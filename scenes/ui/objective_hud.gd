extends PanelContainer
class_name ObjectiveHUD
## 目标 HUD — 右上角显示目标列表，从 ObjectiveManager 读取状态
## 作为子节点放入关卡场景树（在 CanvasLayer 下）

@export var objective_manager: ObjectiveManager

@onready var container: VBoxContainer = $MarginContainer/VBoxContainer

var _labels: Dictionary = {}  # obj_id → Label


func _ready() -> void:
	if objective_manager:
		objective_manager.objective_state_changed.connect(_on_state_changed)
	# 延迟一帧等 ObjectiveManager 填充完目标
	call_deferred("_build_hud")


func _build_hud() -> void:
	for child in container.get_children():
		child.queue_free()
	_labels.clear()

	if not objective_manager:
		return

	var objectives: Array[Dictionary] = objective_manager.get_all_objectives()

	# 主目标
	var title: Label = Label.new()
	title.text = "— 主要目标 —"
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
	title.add_theme_font_size_override("font_size", 14)
	container.add_child(title)

	for obj in objectives:
		if obj["primary"]:
			var label: Label = _make_label()
			container.add_child(label)
			_labels[obj["id"]] = label

	# 次要目标
	var has_secondary: bool = false
	for obj in objectives:
		if not obj["primary"]:
			has_secondary = true
			break

	if has_secondary:
		var sub_title: Label = Label.new()
		sub_title.text = "— 次要目标 —"
		sub_title.add_theme_color_override("font_color", Color(0.7, 0.85, 1.0))
		sub_title.add_theme_font_size_override("font_size", 13)
		container.add_child(sub_title)

		for obj in objectives:
			if not obj["primary"]:
				var label: Label = _make_label()
				container.add_child(label)
				_labels[obj["id"]] = label

	# 计时器
	var timer_label: Label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	container.add_child(timer_label)


func _make_label() -> Label:
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", 13)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(250, 0)
	return label


func _process(_delta: float) -> void:
	if not objective_manager:
		return
	_update_all()


func _update_all() -> void:
	var objectives: Array[Dictionary] = objective_manager.get_all_objectives()
	for obj in objectives:
		var label: Label = _labels.get(obj["id"]) as Label
		if label == null:
			continue
		_update_label(label, obj)

	# 计时器
	var timer_label: Label = container.get_node_or_null("TimerLabel") as Label
	if timer_label:
		timer_label.text = _format_timer()


func _update_label(label: Label, obj: Dictionary) -> void:
	var display_name: String = obj["display_name"]
	var state: String = obj["state"]

	match state:
		"hidden":
			label.text = "???"
			label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 0.5))
		"active":
			var progress_text: String = _progress_text(obj)
			label.text = "○ " + display_name + progress_text
			if obj["primary"]:
				label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.9))
			else:
				label.add_theme_color_override("font_color", Color(0.8, 0.9, 1.0))
		"completed":
			label.text = "● " + display_name + "  ✓"
			label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
		"failed":
			label.text = "✗ " + display_name
			label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))


func _progress_text(obj: Dictionary) -> String:
	var target: int = obj["target"]
	if target > 0:
		return "  %d/%d" % [obj["progress"], target]
	var limit: float = obj["time_limit"]
	if limit > 0:
		var remaining: float = max(limit - obj["timer"], 0.0)
		return "  %d:%02d" % [int(remaining) / 60, int(remaining) % 60]
	return ""


func _format_timer() -> String:
	var elapsed: float = objective_manager.get_time_elapsed()
	# 找最紧迫的主目标倒计时
	var min_remaining: float = 999999.0
	var has_countdown: bool = false
	for obj in objective_manager.get_all_objectives():
		if not obj["primary"] or obj["state"] != "active":
			continue
		var limit: float = obj["time_limit"]
		if limit > 0:
			var remaining: float = limit - obj["timer"]
			has_countdown = true
			if remaining < min_remaining:
				min_remaining = remaining

	if has_countdown:
		min_remaining = max(min_remaining, 0.0)
		return "%d:%02d" % [int(min_remaining) / 60, int(min_remaining) % 60]
	return "已用时 %d:%02d" % [int(elapsed) / 60, int(elapsed) % 60]


func _on_state_changed(_obj_id: String, _new_state: String) -> void:
	# 状态变化时可能需要重建 HUD（如隐藏变激活）
	# 简单处理：_process 中每帧刷新，这里不需要额外操作
	pass
