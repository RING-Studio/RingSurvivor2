extends PanelContainer

signal selected(upgrade_id: String)

@onready var name_label: Label = $%NameLabel
@onready var description_label: RichTextLabel = $%DescriptionLabel
@onready var level_label: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LevelLabel
@onready var neworup_label: Label = $%NEWorUP
@onready var icon_texture_rect: TextureRect = $%Icon

var disabled = false
var upgrade_data: Dictionary


func _ready():
	gui_input.connect(on_gui_input)
	mouse_entered.connect(on_mouse_entered)


func play_in(delay: float = 0):
	modulate = Color.TRANSPARENT
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("in")
	

func play_discard():
	$AnimationPlayer.play("discard")


func set_upgrade_data(data: Dictionary):
	if data == null:
		return
	upgrade_data = data

	name_label.text = data.get("name", "未知强化")
	
	# 获取当前等级和最大等级
	var current_level = GameManager.current_upgrades.get(data["id"], {"level": 0})["level"]
	var max_level = data.get("max_level", -1)
	var next_level = current_level + 1
	
	# 处理描述文本，替换动态数值占位符
	var description = data.get("description", "")
	description = _process_description_placeholders(description, data["id"], next_level)
	description_label.text = description
	
	# 设置 NEWorUP Label
	if current_level == 0:
		# 未拥有：显示亮黄色"NEW！"
		neworup_label.text = "NEW！"
		neworup_label.modulate = Color(1.0, 0.93, 0.2, 1.0)  # 亮黄色
	else:
		# 已拥有：显示亮橙色"UPGRADE"
		neworup_label.text = "UPGRADE"
		neworup_label.modulate = Color(1.0, 0.5, 0.2, 1.0)  # 亮橙色
	
	# 设置 LevelLabel
	if current_level == 0:
		# 未拥有
		if max_level == 1:
			level_label.text = "唯一"
		else:
			level_label.text = "LV.0 → LV.1"
	else:
		# 已拥有
		if max_level != -1 and next_level >= max_level:
			level_label.text = "LV.%d → LV.MAX" % current_level
		else:
			level_label.text = "LV.%d → LV.%d" % [current_level, next_level]
	
	# 设置图标：从 AbilityUpgradeData 中获取
	var icon = AbilityUpgradeData.get_icon(data["id"])
	if icon != null:
		icon_texture_rect.texture = icon
	else:
		icon_texture_rect.texture = null


func select_card():
	disabled = true
	$AnimationPlayer.play("selected")
	
	for other_card in get_tree().get_nodes_in_group("upgrade_card"):
		if other_card == self:
			continue
		other_card.play_discard()
	
	await $AnimationPlayer.animation_finished
	selected.emit(upgrade_data["id"])


func on_gui_input(event: InputEvent):
	if disabled:
		return

	if event.is_action_pressed("LeftClick"):
		select_card()


func on_mouse_entered():
	if disabled:
		return

	$HoverAnimationPlayer.play("hover")

func _process_description_placeholders(description: String, upgrade_id: String, next_level: int) -> String:
	"""处理描述文本中的占位符，将动态数值用绿色富文本显示"""
	var result = description
	
	# 占位符到 upgrade_id 的映射（用于特殊命名的情况）
	var placeholder_to_upgrade_id = {
		"health_1_value": "global_health_1",
		"health_2_value": "global_health_2",
		"health_3_value": "global_health_3",
		"health_4_value": "global_health_4",
		"crit_rate_1_value": "global_crit_rate_1",
		"crit_rate_2_value": "global_crit_rate_2",
		"fire_rate_1_value": "mg_fire_rate_1",
		"fire_rate_2_value": "mg_fire_rate_2",
		"fire_rate_3_value": "mg_fire_rate_3",
		"precision_1_value": "mg_precision_1",
		"precision_2_value": "mg_precision_2",
		"precision_3_value": "mg_precision_3",
		"damage_1_value": "mg_damage_1",
		"damage_2_value": "mg_damage_2",
		"penetration_value": "mg_penetration",
		"spread_value": "mg_spread",
		"bleed_value": "mg_bleed",
		"rapid_fire_1_value": "mg_rapid_fire_1",
		"rapid_fire_2_value": "mg_rapid_fire_2"
	}
	
	# 需要显示为百分比的占位符（效果值需要乘以100）
	var percentage_placeholders = [
		"crit_rate_1_value", "crit_rate_2_value",
		"fire_rate_1_value", "fire_rate_2_value", "fire_rate_3_value",
		"precision_1_value", "precision_2_value", "precision_3_value",
		"rapid_fire_1_value", "rapid_fire_2_value",
		"windmill_damage_penalty_value", "spread_shot_damage_ratio_value", "mg_overload_penalty_value", "ricochet_chance_value",
		"chain_fire_penalty_value", "chain_fire_max_stacks_value", "burst_fire_max_stacks_value", "sweep_fire_bonus_value",
		"breakthrough_max_bonus_value", "fire_suppression_per_part_value", "penetration_damage_penalty_value",
		"breath_hold_rate_value", "focus_crit_rate_value", "mg_heavy_round_penalty_value",
		"mine_cooldown_value", "cooling_device_value", "mine_anti_tank_value"
	]
	
	# 特殊占位符处理（根据等级计算特定值）
	var special_placeholder_values = {}
	
	match upgrade_id:
		"scatter_shot":
			# 10/8/7/6/5次
			var interval_values = [10, 8, 7, 6, 5]
			var index = min(next_level - 1, interval_values.size() - 1)
			special_placeholder_values["scatter_shot_interval_value"] = interval_values[index]
			# 1/1/2/2/3次额外射击
			var count_values = [1, 1, 2, 2, 3]
			special_placeholder_values["scatter_shot_count_value"] = count_values[index]
		
		"windmill":
			# 伤害 -20/30/40%
			var damage_penalties = [20, 30, 40]
			var index = min(next_level - 1, damage_penalties.size() - 1)
			special_placeholder_values["windmill_damage_penalty_value"] = damage_penalties[index]
			# 弹道+2/3/4
			var spread_values = [2, 3, 4]
			special_placeholder_values["windmill_spread_value"] = spread_values[index]
		
		"spread_shot":
			# 弹道+1/2/3
			var spread_values = [1, 2, 3]
			var index = min(next_level - 1, spread_values.size() - 1)
			special_placeholder_values["spread_shot_spread_value"] = spread_values[index]
			# 伤害 50%/40%/30%
			var damage_ratios = [50, 40, 30]
			special_placeholder_values["spread_shot_damage_ratio_value"] = damage_ratios[index]
		
		"split_shot":
			# 2/3发
			var count_values = [2, 3]
			var index = min(next_level - 1, count_values.size() - 1)
			special_placeholder_values["split_shot_count_value"] = count_values[index]
		
		"lethal_strike":
			# 9/7/5/3次
			var interval_values = [9, 7, 5, 3]
			var index = min(next_level - 1, interval_values.size() - 1)
			special_placeholder_values["lethal_strike_interval_value"] = interval_values[index]
		
		"mg_overload":
			# -5/4/3%射速
			var penalty_values = [5, 4, 3]
			var index = min(next_level - 1, penalty_values.size() - 1)
			special_placeholder_values["mg_overload_penalty_value"] = penalty_values[index]
			# 最多叠加12/15/20层
			var max_stacks_values = [12, 15, 20]
			special_placeholder_values["mg_overload_max_stacks_value"] = max_stacks_values[index]
			# 每1秒减少1/2/3层
			var decay_values = [1, 2, 3]
			special_placeholder_values["mg_overload_decay_value"] = decay_values[index]
		
		"ricochet":
			# (10+10lv)%
			var chance = 10 + 10 * next_level
			special_placeholder_values["ricochet_chance_value"] = chance
		
		"chain_fire":
			# 惩罚 -5lv%
			var penalty = 5 * next_level
			special_placeholder_values["chain_fire_penalty_value"] = penalty
			# 最大层数 4lv层
			var max_stacks = 4 * next_level
			special_placeholder_values["chain_fire_max_stacks_value"] = max_stacks
		
		"burst_fire":
			# 最大层数 4lv层
			var max_stacks = 4 * next_level
			special_placeholder_values["burst_fire_max_stacks_value"] = max_stacks
		
		"sweep_fire":
			# +50lv%射速
			var bonus = 50 * next_level
			special_placeholder_values["sweep_fire_bonus_value"] = bonus
		
		"breakthrough":
			# 最多+25lv%
			var max_bonus = 25 * next_level
			special_placeholder_values["breakthrough_max_bonus_value"] = max_bonus
		
		"fire_suppression":
			# +5lv*N%射速
			var per_part = 5 * next_level
			special_placeholder_values["fire_suppression_per_part_value"] = per_part
		
		"penetration":
			# 伤害 -10lv%
			var damage_penalty = 10 * next_level
			special_placeholder_values["penetration_damage_penalty_value"] = damage_penalty
			# 穿透+1lv
			var penetration = 1 * next_level
			special_placeholder_values["penetration_penetration_value"] = penetration
		
		"breath_hold":
			# +10lv%/秒
			var rate = 10 * next_level
			special_placeholder_values["breath_hold_rate_value"] = rate
		
		"focus":
			# +1lv%暴击率
			var crit_rate = 1 * next_level
			special_placeholder_values["focus_crit_rate_value"] = crit_rate
		
		"harvest":
			# 恢复1lv点耐久
			var heal = 1 * next_level
			special_placeholder_values["harvest_heal_value"] = heal
		
		"mg_heavy_round":
			# 射速 -10lv%
			var penalty = 10 * next_level
			special_placeholder_values["mg_heavy_round_penalty_value"] = penalty
			# 基础伤害+1lv
			var damage = 1 * next_level
			special_placeholder_values["mg_heavy_round_damage_value"] = damage
		
		"mine":
			# 基础伤害=5lv
			var base_damage = 5 * next_level
			special_placeholder_values["基础伤害=5lv"] = base_damage
			# 部署上限：10+5lv
			var max_deployed = 10 + 5 * next_level
			special_placeholder_values["mine_max_deployed_value"] = max_deployed
			# 冷却时间（基础3秒，受强化影响）
			# 这里显示基础冷却时间，实际冷却时间受mine_cooldown和cooling_device影响
			var base_cooldown = 3.0
			special_placeholder_values["冷却时间"] = base_cooldown
			# 爆炸范围（基础48像素=3米，受mine_range影响）
			var base_radius = 48.0
			special_placeholder_values["爆炸范围"] = base_radius
		
		"mine_range":
			# 地雷爆炸范围+1.5lv米
			var range_bonus = 1.5 * next_level
			special_placeholder_values["mine_range_value"] = range_bonus
		
		"mine_cooldown":
			# 地雷冷却时间-15lv%
			var cooldown_reduction = 15 * next_level
			special_placeholder_values["mine_cooldown_value"] = cooldown_reduction
		
		"mine_anti_tank":
			# 地雷基础伤害+200lv%
			var damage_bonus = 200 * next_level
			special_placeholder_values["mine_anti_tank_value"] = damage_bonus
		
		"cooling_device":
			# 所有配件冷却时间缩短15lv%
			var cooldown_reduction = 15 * next_level
			special_placeholder_values["cooling_device_value"] = cooldown_reduction
	
	# 查找所有占位符（格式：{xxx_value} 或 {中文占位符}）
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	var matches = regex.search_all(result)
	
	for match in matches:
		var placeholder_name = match.get_string(1)
		var placeholder = "{%s}" % placeholder_name
		
		var display_value: String
		
		# 先检查是否是特殊占位符（包括中文占位符）
		if special_placeholder_values.has(placeholder_name):
			var value = special_placeholder_values[placeholder_name]
			# 对于 mine_range_value，显示一位小数
			if placeholder_name == "mine_range_value":
				display_value = "%.1f" % value
			else:
				display_value = str(value)
		elif placeholder_name == "冷却时间":
			# 地雷基础冷却时间
			display_value = "3.0"
		elif placeholder_name == "爆炸范围":
			# 地雷基础爆炸范围（显示为米，需要转换）
			var base_radius_m = 48.0 / GlobalFomulaManager.METERS_TO_PIXELS  # 像素转米（1米=16像素）
			display_value = "%.1f" % base_radius_m
		elif placeholder_name == "基础伤害=5lv":
			# 地雷基础伤害
			var base_damage = 5 * next_level
			display_value = str(base_damage)
		else:
			# 标准格式：{xxx_value}
			if placeholder_name.ends_with("_value"):
				# 确定使用的 upgrade_id
				var mapped_upgrade_id: String
				if placeholder_to_upgrade_id.has(placeholder_name):
					# 使用映射表中的ID
					mapped_upgrade_id = placeholder_to_upgrade_id[placeholder_name]
				else:
					# 不在映射表中，默认使用当前 upgrade_id
					mapped_upgrade_id = upgrade_id
				
				# 从 UpgradeEffectManager 获取效果值
				var effect_value = UpgradeEffectManager.get_effect(mapped_upgrade_id, next_level)
				
				# 判断是否需要显示为百分比
				var is_percentage = placeholder_name in percentage_placeholders
				if not is_percentage:
					# 检查 upgrade_id 是否通常显示为百分比
					if mapped_upgrade_id in ["crit_rate", "crit_damage", "damage_bonus", "rapid_fire", 
											  "mg_crit_damage", "mg_precision_1", "mg_precision_2", "mg_precision_3",
											  "global_crit_rate_1", "global_crit_rate_2",
											  "mg_fire_rate_1", "mg_fire_rate_2", "mg_fire_rate_3",
											  "mg_rapid_fire_1", "mg_rapid_fire_2"]:
						is_percentage = true
				
				if is_percentage:
					# 百分比：乘以100并显示为整数
					var percentage = int(effect_value * 100)
					display_value = str(percentage)
				else:
					# 整数：直接显示
					display_value = str(int(effect_value))
			else:
				# 未知占位符，跳过
				continue
		
		# 用绿色富文本替换占位符
		var colored_value = "[color=#00ff00]%s[/color]" % display_value
		result = result.replace(placeholder, colored_value)
	
	return result
