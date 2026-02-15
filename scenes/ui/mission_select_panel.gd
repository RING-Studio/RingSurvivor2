extends CanvasLayer
class_name MissionSelectPanel

signal mission_confirmed(mission_id: String)
signal canceled

@export var mission_list: ItemList
@export var detail_label: RichTextLabel
@export var confirm_button: Button
@export var cancel_button: Button
@export var tip_label: Label

var _missions: Array[Dictionary] = []
var _selected_index: int = -1

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	mission_list.item_selected.connect(_on_item_selected)
	refresh()

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	visible = false

func refresh() -> void:
	_missions = MissionData.get_all_missions()
	mission_list.clear()
	for m in _missions:
		var mid: String = m.get("id", "")
		var unlocked: bool = GameManager.is_mission_unlocked(mid)
		var difficulty: int = int(m.get("difficulty", 1))
		var stars: String = "★".repeat(difficulty)
		var label: String = "%s %s" % [stars, m.get("name", "未命名关卡")]
		if not unlocked:
			label += "（未解锁）"
		mission_list.add_item(label)
	if _missions.size() > 0:
		_selected_index = 0
		mission_list.select(0)
		_update_detail(0)
	else:
		_selected_index = -1
		confirm_button.disabled = true
		detail_label.text = "暂无可选任务。"
		tip_label.text = ""

func _on_item_selected(index: int) -> void:
	_update_detail(index)

func _update_detail(index: int) -> void:
	_selected_index = index
	if index < 0 or index >= _missions.size():
		confirm_button.disabled = true
		return
	var mission = _missions[index]
	var time_cost = MissionData.get_time_cost(mission)
	var allow_phases: Array = mission.get("allow_phases", [])
	var phase_labels = MissionData.get_phase_labels(allow_phases)
	if phase_labels.is_empty():
		phase_labels = "任意"
	
	var current_phase = GameManager.time_phase
	var time_left = GameManager.get_remaining_time_phases()
	var current_pollution = GameManager.pollution
	var victory_pollution = MissionData.calc_pollution_after(current_pollution, mission, "victory")
	var defeat_pollution = MissionData.calc_pollution_after(current_pollution, mission, "defeat")
	
	var desc = mission.get("description", "")
	var reward = mission.get("reward_preview", "无")
	var current_phase_label = MissionData.get_phase_label(current_phase)
	
	var detail_text: String = ""
	detail_text += "[b]%s[/b]\n" % mission.get("name", "")
	detail_text += "难度：%s\n" % MissionData.get_difficulty_stars(mission)
	detail_text += "%s\n\n" % desc
	
	# 目标描述
	var obj_type: String = mission.get("objective_type", "survive")
	var obj_params: Dictionary = mission.get("objective_params", {})
	detail_text += "目标：%s\n" % _get_objective_text(obj_type, obj_params)
	
	var mid: String = mission.get("id", "")
	var clear_count: int = GameManager.get_mission_clear_count(mid)
	detail_text += "消耗时段：%s\n" % str(time_cost)
	detail_text += "可出击时段：%s\n" % phase_labels
	detail_text += "当前时段：%s（剩余 %s）\n" % [current_phase_label, str(time_left)]
	detail_text += "已通关次数：%s\n\n" % str(clear_count)
	detail_text += "奖励预览：%s\n" % reward
	detail_text += "胜利污染：%s → %s\n" % [str(current_pollution), str(victory_pollution)]
	detail_text += "失败污染：%s → %s\n" % [str(current_pollution), str(defeat_pollution)]
	detail_label.bbcode_enabled = true
	detail_label.text = detail_text
	
	var availability = _get_unavailable_reason(mission, current_phase, time_left)
	if availability.is_empty():
		confirm_button.disabled = false
		tip_label.text = ""
	else:
		confirm_button.disabled = true
		tip_label.text = availability

func _get_unavailable_reason(mission: Dictionary, current_phase: int, time_left: int) -> String:
	var mid: String = mission.get("id", "")
	if not GameManager.is_mission_unlocked(mid):
		return "该关卡尚未解锁。"
	if not MissionData.is_phase_allowed(mission, current_phase):
		return "当前时段不可出击该关卡。"
	var time_cost = MissionData.get_time_cost(mission)
	if time_cost > time_left:
		return "剩余时段不足，无法接取该关卡。"
	return ""

func _get_objective_text(obj_type: String, obj_params: Dictionary) -> String:
	match obj_type:
		"survive":
			return "存活 %s 秒" % str(obj_params.get("duration_seconds", 90))
		"eliminate":
			var count: int = int(obj_params.get("kill_count", 50))
			var limit: int = int(obj_params.get("time_limit", 120))
			return "在 %s 秒内击杀 %s 只敌人" % [str(limit), str(count)]
		"boss_kill":
			var limit: int = int(obj_params.get("time_limit", 180))
			return "在 %s 秒内击杀 Boss" % str(limit)
		"defend":
			var time: int = int(obj_params.get("defend_time", 150))
			return "保护据点 %s 秒" % str(time)
		"collect":
			var count: int = int(obj_params.get("collect_count", 20))
			return "收集 %s 个物品" % str(count)
		_:
			return "完成关卡目标"

func _on_confirm_pressed() -> void:
	if _selected_index < 0 or _selected_index >= _missions.size():
		return
	var mission_id = _missions[_selected_index].get("id", "")
	if mission_id.is_empty():
		return
	close()
	mission_confirmed.emit(mission_id)

func _on_cancel_pressed() -> void:
	close()
	canceled.emit()
