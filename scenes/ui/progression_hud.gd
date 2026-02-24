extends CanvasLayer
class_name ProgressionHUD

var _panel: PanelContainer
var _content_vbox: VBoxContainer
var _header_label: Label
var _chapter_label: RichTextLabel
var _missions_label: RichTextLabel
var _resources_label: RichTextLabel
var _status_label: Label
var _toggle_btn: Button
var _is_expanded: bool = true

func _ready() -> void:
	layer = 10

	# 右上角切换按钮（始终可见）
	_toggle_btn = Button.new()
	_toggle_btn.text = "◀ 进度"
	_toggle_btn.add_theme_font_size_override("font_size", 13)
	_toggle_btn.pressed.connect(_toggle_panel)
	_toggle_btn.anchor_left = 1.0
	_toggle_btn.anchor_right = 1.0
	_toggle_btn.anchor_top = 0.0
	_toggle_btn.anchor_bottom = 0.0
	_toggle_btn.offset_left = -80
	_toggle_btn.offset_right = -4
	_toggle_btn.offset_top = 4
	_toggle_btn.offset_bottom = 30
	add_child(_toggle_btn)

	# 面板
	_panel = PanelContainer.new()
	_panel.anchor_left = 1.0
	_panel.anchor_right = 1.0
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = -320
	_panel.offset_right = -4
	_panel.offset_top = 34
	_panel.offset_bottom = 34

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.14, 0.92)
	style.border_color = Color(0.35, 0.45, 0.30, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	_panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	_panel.add_child(margin)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 6)
	margin.add_child(_content_vbox)

	# 标题
	_header_label = Label.new()
	_header_label.text = "作战进度"
	_header_label.add_theme_font_size_override("font_size", 18)
	_header_label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	_header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_vbox.add_child(_header_label)

	# 状态行（天数/时段/污染）
	_status_label = Label.new()
	_status_label.add_theme_font_size_override("font_size", 13)
	_status_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_content_vbox.add_child(_status_label)

	# 分隔线
	var sep1: HSeparator = HSeparator.new()
	_content_vbox.add_child(sep1)

	# 当前章节
	_chapter_label = RichTextLabel.new()
	_chapter_label.bbcode_enabled = true
	_chapter_label.fit_content = true
	_chapter_label.scroll_active = false
	_chapter_label.add_theme_font_size_override("normal_font_size", 14)
	_content_vbox.add_child(_chapter_label)

	# 分隔线
	var sep2: HSeparator = HSeparator.new()
	_content_vbox.add_child(sep2)

	# 关卡完成详情
	_missions_label = RichTextLabel.new()
	_missions_label.bbcode_enabled = true
	_missions_label.fit_content = true
	_missions_label.scroll_active = false
	_missions_label.add_theme_font_size_override("normal_font_size", 13)
	_content_vbox.add_child(_missions_label)

	# 分隔线
	var sep3: HSeparator = HSeparator.new()
	_content_vbox.add_child(sep3)

	# 资源一览
	_resources_label = RichTextLabel.new()
	_resources_label.bbcode_enabled = true
	_resources_label.fit_content = true
	_resources_label.scroll_active = false
	_resources_label.add_theme_font_size_override("normal_font_size", 13)
	_content_vbox.add_child(_resources_label)

	add_child(_panel)

	refresh()

func refresh() -> void:
	var summary: Dictionary = GameManager.get_progression_summary()

	# 状态行
	var phase_text: String = MissionData.get_phase_label(summary.get("day", 1))
	_status_label.text = "第 %d 天  |  污染度 %d" % [
		int(summary.get("day", 1)),
		int(summary.get("pollution", 0))
	]

	# 章节信息
	var chapter_text: String = ""
	var current_ch: String = str(summary.get("current_chapter", ""))
	chapter_text += "[b]当前章节[/b]\n"
	chapter_text += "[color=#d4c47a]%s[/color]\n" % current_ch
	chapter_text += "任务通关：%d / %d" % [
		int(summary.get("cleared_missions", 0)),
		int(summary.get("total_missions", 0))
	]
	_chapter_label.text = chapter_text

	# 逐章节详情
	var ch_progress: Dictionary = summary.get("chapter_progress", {})
	var missions_text: String = ""
	for ch_id in GameManager.CHAPTER_DEFINITIONS:
		var ch_def: Dictionary = GameManager.CHAPTER_DEFINITIONS[ch_id]
		var ch_name: String = str(ch_def.get("name", ""))
		var ch_entry: Dictionary = ch_progress.get(ch_id, {})
		var unlocked: bool = ch_entry.get("unlocked", false)
		var completed: bool = ch_entry.get("completed", false)

		if completed:
			missions_text += "[color=green]✓[/color] %s\n" % ch_name
		elif unlocked:
			missions_text += "[color=yellow]▶[/color] %s\n" % ch_name
			var required: Array = ch_def.get("required_missions", [])
			for mid in required:
				var m: Dictionary = MissionData.get_mission(str(mid))
				var m_name: String = str(m.get("name", mid))
				var cleared: bool = GameManager.get_mission_clear_count(str(mid)) > 0
				if cleared:
					missions_text += "    [color=green]✓[/color] %s\n" % m_name
				else:
					missions_text += "    [color=gray]○[/color] %s\n" % m_name
		else:
			missions_text += "[color=gray]🔒[/color] %s\n" % ch_name

	_missions_label.text = missions_text

	# 资源一览
	var res_text: String = "[b]资源[/b]\n"
	res_text += "[color=#ffd700]金币：%d[/color]\n" % GameManager.money
	var mats: Dictionary = GameManager.materials
	if mats.is_empty():
		res_text += "[color=#999999]暂无素材[/color]"
	else:
		for mat_id in mats:
			var amount: int = int(mats[mat_id])
			if amount <= 0:
				continue
			var mat_name: String = EquipmentCostData.get_material_name(str(mat_id))
			res_text += "%s: %d\n" % [mat_name, amount]
	_resources_label.text = res_text

	# 自动调整面板高度
	_panel.size = Vector2.ZERO

func _toggle_panel() -> void:
	_is_expanded = not _is_expanded
	_panel.visible = _is_expanded
	_toggle_btn.text = "◀ 进度" if _is_expanded else "▶ 进度"
