extends CanvasLayer
class_name MissionObjectiveTracker
## 关卡内多目标追踪器
## 支持：主目标/次要目标、触发链（after 条件）、分组 HUD 显示
## 胜利条件：所有主目标完成
## 失败条件：玩家死亡 / 任意主目标超时失败

signal objective_completed  # 所有主目标完成 → 胜利
signal objective_failed  # 任意主目标失败 → 失败
signal single_objective_done(obj_id: String, is_primary: bool)  # 单个目标完成

@onready var objective_container: VBoxContainer = $Panel/MarginContainer/ObjectiveContainer

var _mission_id: String = ""
var _objectives: Array[Dictionary] = []  # 所有目标的运行时状态
var _time_elapsed: float = 0.0
var _finished: bool = false  # 整局已结束（胜或败）

# ========== 目标运行时状态字典键 ==========
# 在原始 objective dict 基础上追加：
#   "_state": "hidden" / "active" / "completed" / "failed"
#   "_progress": int  (当前进度，如击杀数/收集数)
#   "_timer": float   (该目标激活后经过的时间)
#   "_label": Label   (对应的 HUD Label 节点)


func _ready() -> void:
	_mission_id = GameManager.current_mission_id
	var mission: Dictionary = MissionData.get_mission(_mission_id)

	if mission.is_empty():
		# 无关卡配置（直接进 LevelTest），默认无限生存
		_objectives.append({
			"id": "free_play",
			"type": "survive",
			"primary": true,
			"display_name": "自由模式",
			"params": {"duration_seconds": 999999},
			"trigger": null,
			"order": 1,
			"_state": "active",
			"_progress": 0,
			"_timer": 0.0
		})
	else:
		# 加载所有目标
		var raw_objectives: Array = MissionData.get_objectives(mission)
		for obj in raw_objectives:
			var runtime_obj: Dictionary = obj.duplicate(true)
			# 判断初始状态
			var trigger = obj.get("trigger", null)
			if trigger == null or (trigger is Dictionary and trigger.is_empty()):
				runtime_obj["_state"] = "active"
			else:
				runtime_obj["_state"] = "hidden"
			runtime_obj["_progress"] = 0
			runtime_obj["_timer"] = 0.0
			_objectives.append(runtime_obj)

	_build_hud()
	_update_display()


func _build_hud() -> void:
	"""构建目标列表 HUD"""
	# 清空旧内容
	for child in objective_container.get_children():
		child.queue_free()

	# 主目标标题
	var primary_title: Label = Label.new()
	primary_title.text = "— 主要目标 —"
	primary_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	primary_title.add_theme_font_size_override("font_size", 14)
	primary_title.name = "PrimaryTitle"
	objective_container.add_child(primary_title)

	# 主目标项
	for obj in _objectives:
		if obj.get("primary", false):
			var label: Label = _create_objective_label(obj)
			objective_container.add_child(label)
			obj["_label"] = label

	# 次要目标标题
	var has_secondary: bool = false
	for obj in _objectives:
		if not obj.get("primary", false):
			has_secondary = true
			break

	if has_secondary:
		var sep: Label = Label.new()
		sep.text = "— 次要目标 —"
		sep.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		sep.add_theme_font_size_override("font_size", 13)
		sep.name = "SecondaryTitle"
		objective_container.add_child(sep)

		for obj in _objectives:
			if not obj.get("primary", false):
				var label: Label = _create_objective_label(obj)
				objective_container.add_child(label)
				obj["_label"] = label

	# 计时器
	var timer_label: Label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	objective_container.add_child(timer_label)


func _create_objective_label(obj: Dictionary) -> Label:
	var label: Label = Label.new()
	label.name = "Obj_" + str(obj.get("id", ""))
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(250, 0)
	return label


func _process(delta: float) -> void:
	if _finished:
		return

	_time_elapsed += delta

	# 更新每个活跃目标的计时器和状态
	for obj in _objectives:
		var state: String = obj.get("_state", "hidden")
		if state != "active":
			continue

		obj["_timer"] = float(obj.get("_timer", 0.0)) + delta
		var obj_type: String = obj.get("type", "")
		var params: Dictionary = obj.get("params", {})

		match obj_type:
			"survive", "defend":
				var target_dur: float = float(params.get("duration_seconds", params.get("defend_time", 90)))
				if float(obj["_timer"]) >= target_dur:
					_complete_objective(obj)
			"eliminate":
				var time_limit: float = float(params.get("time_limit", -1))
				if time_limit > 0 and float(obj["_timer"]) >= time_limit:
					if obj.get("primary", false):
						_fail_objective(obj)
			"boss_kill":
				var time_limit: float = float(params.get("time_limit", -1))
				if time_limit > 0 and float(obj["_timer"]) >= time_limit:
					if obj.get("primary", false):
						_fail_objective(obj)
			"collect":
				var time_limit: float = float(params.get("time_limit", -1))
				if time_limit > 0 and float(obj["_timer"]) >= time_limit:
					if obj.get("primary", false):
						_fail_objective(obj)
			# reach_area：由关卡脚本调用 report_area_reached()

	_update_display()


func _update_display() -> void:
	for obj in _objectives:
		var label: Label = obj.get("_label") as Label
		if label == null:
			continue

		var state: String = obj.get("_state", "hidden")
		var display_name: String = obj.get("display_name", "")
		var is_primary: bool = obj.get("primary", false)
		var obj_type: String = obj.get("type", "")
		var params: Dictionary = obj.get("params", {})

		match state:
			"hidden":
				label.text = "???"
				label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
			"active":
				var progress_text: String = _get_progress_text(obj)
				label.text = "○ " + display_name
				if not progress_text.is_empty():
					label.text += "  " + progress_text
				if is_primary:
					label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
				else:
					label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
			"completed":
				label.text = "● " + display_name + "  ✓"
				label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
			"failed":
				label.text = "✗ " + display_name + "  失败"
				label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

	# 更新全局计时器
	var timer_label: Label = objective_container.get_node_or_null("TimerLabel") as Label
	if timer_label:
		# 找最紧迫的时间限制（活跃主目标中最短的剩余时间）
		var display_time: String = _get_most_urgent_timer()
		timer_label.text = display_time


func _get_progress_text(obj: Dictionary) -> String:
	var obj_type: String = obj.get("type", "")
	var params: Dictionary = obj.get("params", {})
	var progress: int = int(obj.get("_progress", 0))
	var timer: float = float(obj.get("_timer", 0.0))

	match obj_type:
		"survive", "defend":
			var target: float = float(params.get("duration_seconds", params.get("defend_time", 90)))
			var remaining: float = max(target - timer, 0.0)
			return "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
		"eliminate":
			var target: int = int(params.get("kill_count", 50))
			var time_limit: float = float(params.get("time_limit", -1))
			var text: String = "%d/%d" % [progress, target]
			if time_limit > 0:
				var remaining: float = max(time_limit - timer, 0.0)
				text += "  %d:%02d" % [int(remaining) / 60, int(remaining) % 60]
			return text
		"boss_kill":
			var time_limit: float = float(params.get("time_limit", -1))
			if time_limit > 0:
				var remaining: float = max(time_limit - timer, 0.0)
				return "%d:%02d" % [int(remaining) / 60, int(remaining) % 60]
			return ""
		"collect":
			var target: int = int(params.get("collect_count", 20))
			return "%d/%d" % [progress, target]
		"reach_area":
			return "前往目标区域"
	return ""


func _get_most_urgent_timer() -> String:
	"""找到最紧迫的倒计时显示"""
	var min_remaining: float = 999999.0
	var has_timer: bool = false

	for obj in _objectives:
		if obj.get("_state", "") != "active":
			continue
		if not obj.get("primary", false):
			continue

		var obj_type: String = obj.get("type", "")
		var params: Dictionary = obj.get("params", {})
		var timer: float = float(obj.get("_timer", 0.0))
		var remaining: float = -1.0

		match obj_type:
			"survive", "defend":
				var target: float = float(params.get("duration_seconds", params.get("defend_time", 90)))
				remaining = target - timer
			"eliminate", "boss_kill", "collect":
				var time_limit: float = float(params.get("time_limit", -1))
				if time_limit > 0:
					remaining = time_limit - timer

		if remaining >= 0:
			has_timer = true
			if remaining < min_remaining:
				min_remaining = remaining

	if has_timer:
		min_remaining = max(min_remaining, 0.0)
		return "%d:%02d" % [int(min_remaining) / 60, int(min_remaining) % 60]
	else:
		# 显示已用时间
		return "已用时 %d:%02d" % [int(_time_elapsed) / 60, int(_time_elapsed) % 60]


# ========== 触发链处理 ==========

func _complete_objective(obj: Dictionary) -> void:
	if obj.get("_state", "") != "active":
		return
	obj["_state"] = "completed"
	var obj_id: String = obj.get("id", "")
	var is_primary: bool = obj.get("primary", false)
	single_objective_done.emit(obj_id, is_primary)

	# 检查是否触发后续目标
	_check_trigger_chain(obj_id)

	# 检查是否所有主目标已完成
	if _all_primary_completed():
		_trigger_mission_victory()


func _fail_objective(obj: Dictionary) -> void:
	if obj.get("_state", "") != "active":
		return
	obj["_state"] = "failed"

	if obj.get("primary", false):
		_trigger_mission_defeat()


func _check_trigger_chain(completed_obj_id: String) -> void:
	"""检查是否有目标因为 completed_obj_id 完成而解锁"""
	for obj in _objectives:
		if obj.get("_state", "") != "hidden":
			continue
		var trigger = obj.get("trigger", null)
		if trigger == null or not (trigger is Dictionary):
			continue
		var after_id: String = str(trigger.get("after", ""))
		if after_id == completed_obj_id:
			obj["_state"] = "active"
			obj["_timer"] = 0.0
			obj["_progress"] = 0


func _all_primary_completed() -> bool:
	for obj in _objectives:
		if not obj.get("primary", false):
			continue
		var state: String = obj.get("_state", "hidden")
		if state == "hidden":
			# 隐藏的主目标可能还未触发
			# 检查其前置是否已完成
			var trigger = obj.get("trigger", null)
			if trigger != null and trigger is Dictionary:
				var after_id: String = str(trigger.get("after", ""))
				if not after_id.is_empty():
					# 前置未完成 → 这个目标还不能被跳过
					return false
			# trigger 为 null 但状态是 hidden 不应该出现（_ready 中已设为 active）
			continue
		if state != "completed":
			return false
	return true


func _trigger_mission_victory() -> void:
	if _finished:
		return
	_finished = true
	objective_completed.emit()


func _trigger_mission_defeat() -> void:
	if _finished:
		return
	_finished = true
	objective_failed.emit()


# ========== 外部调用接口 ==========

func report_kill(enemy: Node2D = null) -> void:
	"""由敌人死亡时调用，报告击杀"""
	if _finished:
		return

	var enemy_class_name: String = ""
	if enemy:
		enemy_class_name = enemy.get_class()
		# 尝试从 class_name 获取（GDScript class_name 通过 script 获得）
		var script: GDScript = enemy.get_script() as GDScript
		if script:
			var global_name: String = script.get_global_name()
			if not global_name.is_empty():
				enemy_class_name = global_name

	var is_elite: bool = false
	var is_boss: bool = false
	if enemy and enemy.get("enemy_rank") != null:
		var rank: int = int(enemy.enemy_rank)
		is_elite = rank >= 1
		is_boss = rank >= 2

	for obj in _objectives:
		if obj.get("_state", "") != "active":
			continue

		var obj_type: String = obj.get("type", "")
		var params: Dictionary = obj.get("params", {})

		if obj_type == "eliminate":
			var filter: String = str(params.get("enemy_filter", ""))
			var should_count: bool = false

			if filter.is_empty():
				should_count = true  # 无过滤，所有敌人计数
			elif filter == "elite":
				should_count = is_elite  # 只计精英+Boss
			elif filter == enemy_class_name:
				should_count = true  # 按 class_name 过滤

			if should_count:
				obj["_progress"] = int(obj.get("_progress", 0)) + 1
				var target: int = int(params.get("kill_count", 50))
				if int(obj["_progress"]) >= target:
					_complete_objective(obj)

		elif obj_type == "boss_kill":
			if is_boss:
				var required_boss: String = str(params.get("boss_id", ""))
				# boss_id 匹配或未指定
				if required_boss.is_empty():
					_complete_objective(obj)
				else:
					# 检查 class_name 匹配（BossTitan → boss_titan）
					var boss_matches: bool = false
					if enemy_class_name == "BossTitan" and required_boss == "boss_titan":
						boss_matches = true
					elif enemy_class_name == "BossHive" and required_boss == "boss_hive":
						boss_matches = true
					elif required_boss in enemy_class_name.to_lower():
						boss_matches = true
					if boss_matches:
						_complete_objective(obj)


func report_collect(item_type: String = "", amount: int = 1) -> void:
	"""收集物品时调用"""
	if _finished:
		return

	for obj in _objectives:
		if obj.get("_state", "") != "active":
			continue
		if obj.get("type", "") != "collect":
			continue
		var params: Dictionary = obj.get("params", {})
		var required_type: String = str(params.get("item_type", ""))
		if not required_type.is_empty() and not item_type.is_empty() and required_type != item_type:
			continue

		obj["_progress"] = int(obj.get("_progress", 0)) + amount
		var target: int = int(params.get("collect_count", 20))
		if int(obj["_progress"]) >= target:
			_complete_objective(obj)


func report_area_reached(area_id: String) -> void:
	"""到达指定区域时由关卡脚本调用"""
	if _finished:
		return

	for obj in _objectives:
		if obj.get("_state", "") != "active":
			continue
		if obj.get("type", "") != "reach_area":
			continue
		var params: Dictionary = obj.get("params", {})
		var required_area: String = str(params.get("area_id", ""))
		if required_area.is_empty() or required_area == area_id:
			_complete_objective(obj)


func report_outpost_destroyed() -> void:
	"""据点被摧毁时调用"""
	for obj in _objectives:
		if obj.get("_state", "") != "active":
			continue
		if obj.get("type", "") == "defend" and obj.get("primary", false):
			_fail_objective(obj)


# ========== 查询接口 ==========

func is_objective_active(obj_id: String) -> bool:
	for obj in _objectives:
		if obj.get("id", "") == obj_id:
			return obj.get("_state", "") == "active"
	return false

func is_objective_completed(obj_id: String) -> bool:
	for obj in _objectives:
		if obj.get("id", "") == obj_id:
			return obj.get("_state", "") == "completed"
	return false

func get_completed_secondary_ids() -> Array[String]:
	"""获取已完成的次要目标 ID 列表（用于结算奖励）"""
	var result: Array[String] = []
	for obj in _objectives:
		if not obj.get("primary", false) and obj.get("_state", "") == "completed":
			result.append(str(obj.get("id", "")))
	return result

func is_finished() -> bool:
	return _finished
