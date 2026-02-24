extends CanvasLayer

@onready var panel_container = $%PanelContainer
@export var continue_scene: StringName = &""
@export var quit_scene: StringName = &""

# 结算 UI 节点
@onready var settlement_container = $%SettlementContainer
@onready var loss_label = $%LossLabel
@onready var energy_label = $%EnergyLabel
@onready var materials_label = $%MaterialsLabel

# 素材显示名称映射
const MATERIAL_DISPLAY_NAMES: Dictionary = {
	"energy_core": "能量核心",
	"bio_sample": "生物样本",
	"pollution_energy": "污染能量",
	"scrap_metal": "废金属",
	"rare_mineral": "稀有矿石",
	"scarab_chitin": "甲虫甲壳",
	"spore_sample": "孢子样本",
	"acid_gland": "酸液腺",
}


func _ready():
	panel_container.pivot_offset = panel_container.size / 2
	var tween: Tween = create_tween()
	tween.tween_property(panel_container, "scale", Vector2.ZERO, 0)
	tween.tween_property(panel_container, "scale", Vector2.ONE, .3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	get_tree().paused = true
	$%ContinueButton.pressed.connect(on_continue_button_pressed)
	$%QuitButton.pressed.connect(on_quit_button_pressed)

	# 默认隐藏结算区域（等待 show_settlement 调用）
	if settlement_container:
		settlement_container.visible = false


func set_defeat():
	$%TitleLabel.text = "失败"
	$%DescriptionLabel.text = "任务失败……"
	play_jingle(true)


func set_victory():
	$%TitleLabel.text = "胜利"
	$%DescriptionLabel.text = "任务完成！"
	play_jingle(false)


func show_settlement(settlement: Dictionary) -> void:
	"""显示结算带出物品信息"""
	if settlement.is_empty() or not settlement_container:
		return

	settlement_container.visible = true

	# 损失描述
	var loss_text: String = settlement.get("loss_desc", "")
	if not loss_text.is_empty():
		loss_label.text = loss_text
	else:
		loss_label.visible = false

	# 能量返还
	var energy_raw: int = int(settlement.get("total_upgrade_energy_raw", 0))
	var energy_final: int = int(settlement.get("total_upgrade_energy_final", 0))
	if energy_raw > 0:
		if energy_raw == energy_final:
			energy_label.text = "污染能量：+%d" % energy_final
		else:
			energy_label.text = "污染能量：+%d（原 %d）" % [energy_final, energy_raw]
	else:
		energy_label.text = "污染能量：+0"

	# 素材
	var final_mats: Dictionary = settlement.get("final_materials", {})
	var raw_mats: Dictionary = settlement.get("raw_materials", {})
	if final_mats.is_empty() and raw_mats.is_empty():
		materials_label.text = "素材：无"
	else:
		var parts: Array[String] = []
		for mat_type in raw_mats.keys():
			var raw_count: int = int(raw_mats[mat_type])
			var final_count: int = int(final_mats.get(mat_type, 0))
			var display_name: String = MATERIAL_DISPLAY_NAMES.get(mat_type, mat_type)
			if raw_count == final_count:
				parts.append("%s ×%d" % [display_name, final_count])
			else:
				parts.append("%s ×%d（原 %d）" % [display_name, final_count, raw_count])
		materials_label.text = "素材：" + "，".join(parts)

	# 通关奖励
	var vb_money: int = int(settlement.get("victory_bonus_money", 0))
	var vb_mats: Dictionary = settlement.get("victory_bonus_materials", {})
	if vb_money > 0 or not vb_mats.is_empty():
		var vb_parts: Array[String] = []
		if vb_money > 0:
			vb_parts.append("金币 +%d" % vb_money)
		for mat_type in vb_mats:
			var display_name: String = MATERIAL_DISPLAY_NAMES.get(mat_type, mat_type)
			vb_parts.append("%s ×%d" % [display_name, int(vb_mats[mat_type])])
		var vb_label: Label = Label.new()
		vb_label.text = "通关奖励：" + "，".join(vb_parts)
		vb_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4))
		settlement_container.add_child(vb_label)

	# 次要目标奖励
	var obj_details: Array = settlement.get("obj_reward_details", [])
	if not obj_details.is_empty():
		var obj_header: Label = Label.new()
		obj_header.text = "── 额外目标奖励 ──"
		obj_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		obj_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		settlement_container.add_child(obj_header)
		for detail in obj_details:
			var obj_parts: Array[String] = []
			var obj_money: int = int(detail.get("money", 0))
			if obj_money > 0:
				obj_parts.append("金币 +%d" % obj_money)
			var obj_mats: Dictionary = detail.get("materials", {})
			for mat_type in obj_mats:
				var display_name: String = MATERIAL_DISPLAY_NAMES.get(mat_type, mat_type)
				obj_parts.append("%s ×%d" % [display_name, int(obj_mats[mat_type])])
			var obj_label: Label = Label.new()
			obj_label.text = "✓ %s：%s" % [str(detail.get("display_name", "")), "，".join(obj_parts)]
			obj_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
			settlement_container.add_child(obj_label)

	# 新解锁配件（Mark E.1）
	var newly_unlocked: Array = settlement.get("newly_unlocked", [])
	if not newly_unlocked.is_empty():
		var unlock_parts: Array[String] = []
		for uid in newly_unlocked:
			var entry: Variant = AbilityUpgradeData.get_entry(uid)
			if entry != null and entry is Dictionary:
				unlock_parts.append(entry.get("name", uid))
			else:
				unlock_parts.append(uid)
		var unlock_label: Label = Label.new()
		unlock_label.text = "🔓 新解锁配件：" + "，".join(unlock_parts)
		unlock_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		settlement_container.add_child(unlock_label)


func play_jingle(defeat: bool = false):
	if defeat:
		$DefeatStreamPlayer.play()
	else:
		$VictoryStreamPlayer.play()


func on_continue_button_pressed():
	get_tree().paused = false
	Transitions.set_next_scene(continue_scene)
	Transitions.transition(Transitions.transition_type.Diamond, false)


func on_quit_button_pressed():
	get_tree().paused = false
	Transitions.set_next_scene(quit_scene)
	Transitions.transition(Transitions.transition_type.Diamond, false)
