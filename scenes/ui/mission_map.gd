extends CanvasLayer
class_name MissionMap
## 任务地图 — 覆盖层场景，显示目的地图标，点击弹出该目的地的任务面板

signal mission_confirmed(mission_id: String)
signal canceled

@onready var map_container: Control = $MapContainer
@onready var detail_panel: PanelContainer = $DetailPanel
@onready var detail_title: Label = $DetailPanel/MarginContainer/VBox/Title
@onready var detail_missions: VBoxContainer = $DetailPanel/MarginContainer/VBox/MissionList
@onready var detail_info: RichTextLabel = $DetailPanel/MarginContainer/VBox/Info
@onready var confirm_button: Button = $DetailPanel/MarginContainer/VBox/Buttons/Confirm
@onready var cancel_detail_button: Button = $DetailPanel/MarginContainer/VBox/Buttons/Cancel
@onready var close_button: Button = $TopBar/CloseButton
@onready var day_label: Label = $TopBar/DayLabel
@onready var phase_label: Label = $TopBar/PhaseLabel
@onready var pollution_label: Label = $TopBar/PollutionLabel

var _destinations: Array[Dictionary] = []
var _destination_buttons: Array[Button] = []
var _current_dest_id: String = ""
var _current_missions: Array[Dictionary] = []
var _selected_mission_index: int = -1


func _ready() -> void:
	close_button.pressed.connect(_on_close_pressed)
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_detail_button.pressed.connect(_on_cancel_detail)
	detail_panel.visible = false

	_update_top_bar()
	_build_destination_icons()


func open() -> void:
	visible = true
	_update_top_bar()
	_refresh_destination_states()
	detail_panel.visible = false


func close() -> void:
	visible = false


func _update_top_bar() -> void:
	day_label.text = "第 %d 天" % GameManager.day
	var phase_text: String = MissionData.get_phase_label(GameManager.time_phase)
	var remaining: int = GameManager.get_remaining_time_phases()
	phase_label.text = "时段：%s（剩余 %d）" % [phase_text, remaining]
	pollution_label.text = "污染度：%d" % GameManager.pollution


func _build_destination_icons() -> void:
	"""根据 DESTINATIONS 在地图上创建按钮图标"""
	_destinations = MissionData.get_all_destinations()

	for dest in _destinations:
		var btn: Button = Button.new()
		btn.name = "Dest_" + str(dest.get("id", ""))
		btn.text = str(dest.get("name", "???"))
		btn.custom_minimum_size = Vector2(100, 40)

		# 定位：归一化坐标映射到 map_container 大小
		var map_pos: Vector2 = dest.get("map_position", Vector2(0.5, 0.5))
		btn.position = Vector2(map_pos.x * 900, map_pos.y * 500)
		btn.add_theme_font_size_override("font_size", 13)

		var dest_id: String = str(dest.get("id", ""))
		btn.pressed.connect(_on_destination_clicked.bind(dest_id))

		map_container.add_child(btn)
		_destination_buttons.append(btn)


func _refresh_destination_states() -> void:
	"""更新每个目的地按钮的可用/已完成状态"""
	for i in range(_destinations.size()):
		var dest: Dictionary = _destinations[i]
		var btn: Button = _destination_buttons[i]
		var mission_ids: Array = dest.get("missions", [])

		var has_unlocked: bool = false
		var all_cleared: bool = true
		for mid in mission_ids:
			if GameManager.is_mission_unlocked(str(mid)):
				has_unlocked = true
			if GameManager.get_mission_clear_count(str(mid)) == 0:
				all_cleared = false

		if not has_unlocked:
			btn.disabled = true
			btn.modulate = Color(0.5, 0.5, 0.5)
			btn.tooltip_text = "尚未解锁"
		elif all_cleared and mission_ids.size() > 0:
			btn.disabled = false
			btn.modulate = Color(0.4, 1.0, 0.4)
			btn.tooltip_text = "已全部通关"
		else:
			btn.disabled = false
			btn.modulate = Color(1.0, 1.0, 1.0)
			btn.tooltip_text = ""


func _on_destination_clicked(dest_id: String) -> void:
	"""点击目的地图标 → 打开该目的地的任务面板"""
	_current_dest_id = dest_id
	_current_missions = MissionData.get_missions_for_destination(dest_id)

	var dest: Dictionary = MissionData.get_destination(dest_id)
	detail_title.text = str(dest.get("name", "未知区域"))

	# 清空任务列表
	for child in detail_missions.get_children():
		child.queue_free()

	_selected_mission_index = -1

	# 构建任务按钮
	for i in range(_current_missions.size()):
		var m: Dictionary = _current_missions[i]
		var mid: String = str(m.get("id", ""))
		var unlocked: bool = GameManager.is_mission_unlocked(mid)
		var difficulty: int = int(m.get("difficulty", 1))
		var stars: String = "★".repeat(difficulty)
		var clear_count: int = GameManager.get_mission_clear_count(mid)

		var btn: Button = Button.new()
		btn.custom_minimum_size = Vector2(0, 50)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var label_text: String = "%s %s" % [stars, str(m.get("name", "未命名"))]
		if clear_count > 0:
			label_text += "  (已通关 %d 次)" % clear_count
		if not unlocked:
			label_text += "  [未解锁]"
			btn.disabled = true
		btn.text = label_text
		btn.pressed.connect(_on_mission_button_pressed.bind(i))
		detail_missions.add_child(btn)

		# 第一个可用的自动选中
		if _selected_mission_index < 0 and unlocked:
			_selected_mission_index = i

	if _selected_mission_index >= 0:
		_update_mission_info(_selected_mission_index)
	else:
		detail_info.text = "该区域暂无可用任务。"
		confirm_button.disabled = true

	detail_panel.visible = true


func _on_mission_button_pressed(index: int) -> void:
	_selected_mission_index = index
	_update_mission_info(index)


func _update_mission_info(index: int) -> void:
	if index < 0 or index >= _current_missions.size():
		return

	var mission: Dictionary = _current_missions[index]
	var mid: String = str(mission.get("id", ""))
	var desc: String = str(mission.get("description", ""))
	var time_cost: int = MissionData.get_time_cost(mission)
	var allow_phases: Array = mission.get("allow_phases", [])
	var phase_labels_text: String = MissionData.get_phase_labels(allow_phases)
	if phase_labels_text.is_empty():
		phase_labels_text = "任意"

	var current_pollution: int = GameManager.pollution
	var victory_pollution: int = MissionData.calc_pollution_after(current_pollution, mission, "victory")
	var defeat_pollution: int = MissionData.calc_pollution_after(current_pollution, mission, "defeat")

	var text: String = ""
	text += "[b]%s[/b]\n" % str(mission.get("name", ""))
	text += "难度：%s\n" % MissionData.get_difficulty_stars(mission)
	text += "%s\n\n" % desc

	# 目标列表
	text += "[u]目标[/u]\n"
	var objectives: Array = MissionData.get_objectives(mission)
	var completed_objs: Array = GameManager.get_mission_completed_objectives(mid)
	for obj in objectives:
		var is_primary: bool = obj.get("primary", false)
		var tag: String = "[主]" if is_primary else "[次]"
		var obj_name: String = str(obj.get("display_name", ""))
		var obj_id: String = str(obj.get("id", ""))
		var done: bool = obj_id in completed_objs

		if done:
			text += "  %s %s  [color=green]✓[/color]\n" % [tag, obj_name]
		else:
			text += "  %s %s\n" % [tag, obj_name]

	text += "\n消耗时段：%s\n" % str(time_cost)
	text += "可出击时段：%s\n" % phase_labels_text
	text += "胜利污染：%s → %s\n" % [str(current_pollution), str(victory_pollution)]
	text += "失败污染：%s → %s\n" % [str(current_pollution), str(defeat_pollution)]

	detail_info.bbcode_enabled = true
	detail_info.text = text

	# 检查能否出击
	var reason: String = _get_unavailable_reason(mission)
	if reason.is_empty():
		confirm_button.disabled = false
		confirm_button.text = "确认出击"
	else:
		confirm_button.disabled = true
		confirm_button.text = reason


func _get_unavailable_reason(mission: Dictionary) -> String:
	var mid: String = str(mission.get("id", ""))
	if not GameManager.is_mission_unlocked(mid):
		return "尚未解锁"
	if not MissionData.is_phase_allowed(mission, GameManager.time_phase):
		return "当前时段不可出击"
	var time_cost: int = MissionData.get_time_cost(mission)
	if time_cost > GameManager.get_remaining_time_phases():
		return "剩余时段不足"
	return ""


func _on_confirm_pressed() -> void:
	if _selected_mission_index < 0 or _selected_mission_index >= _current_missions.size():
		return
	var mission_id: String = str(_current_missions[_selected_mission_index].get("id", ""))
	if mission_id.is_empty():
		return
	close()
	mission_confirmed.emit(mission_id)


func _on_cancel_detail() -> void:
	detail_panel.visible = false


func _on_close_pressed() -> void:
	close()
	canceled.emit()
