extends VBoxContainer
class_name ListDisplay

@export var title: Label
@export var icon: TextureRect
@export var label : RichTextLabel
@export var parts_unlock_button: Button
@export var load_button: Button
@export var unload_button: Button

func set_title(text:String) -> void:
	title.text = text

func set_icon(texture:Texture2D) -> void:
	icon.texture = texture

func set_label_bbcode(bbcode_text: String) -> void:
	label.bbcode_enabled = true
	label.text = bbcode_text

func update_info(id: Variant, table_name: String, vehicle_id: int) -> Dictionary:
	var field: Dictionary = {}
	var upgrade_id: String = ""
	# 配件槽：统一从 AbilityUpgradeData 读，id 为 upgrade_id（String）
	if table_name == "配件":
		if id is String and not id.is_empty():
			upgrade_id = id
			var entry = AbilityUpgradeData.get_entry(id)
			if entry != null:
				field = {"Name": entry.get("name", ""), "Remarks": entry.get("description", "")}
	else:
		var table = JsonManager.get_category(table_name)
		if table != null and table.size() > 0:
			if id is int and id >= 0 and id < table.size():
				var row = table[id]
				if row is Dictionary:
					field = row
			else:
				for row in table:
					if row is Dictionary and (row.get("Id") == id or row.get("ID") == id):
						field = row
						break
	if field.is_empty():
		return {}

	set_title(field.get("Name", ""))

	# 图标：配件优先从 AbilityUpgradeData.upgrade_icons 读取
	var icon_texture: Texture2D = null
	if not upgrade_id.is_empty():
		icon_texture = AbilityUpgradeData.get_icon(upgrade_id)
	if icon_texture == null:
		var image_path = "res://Assets/UIAssets/Accessories/{0}.jpg".format([field.get("Name", "")])
		if ResourceLoader.exists(image_path):
			icon_texture = load(image_path)
	if icon_texture == null:
		icon_texture = load("res://Assets/UIAssets/Unavailable.png")
	set_icon(icon_texture)

	# 描述：应用参数替换 + BBCode 富文本
	var raw_description: String = field.get("Remarks", "")
	if not upgrade_id.is_empty():
		raw_description = _process_description(raw_description, upgrade_id, 1)
	set_label_bbcode(raw_description)

	var unlocked = GameManager.is_parts_unlocked(table_name, id)
	parts_unlock_button.visible = !unlocked

	var equipped = GameManager.is_equipped(vehicle_id, table_name, id)
	load_button.visible = unlocked and !equipped
	unload_button.visible = unlocked and equipped

	icon.use_parent_material = !unlocked
	label.use_parent_material = !unlocked

	return field

# ========== 描述占位符处理（车辆编辑器用，默认展示 Lv1 数值） ==========

func _process_description(description: String, upgrade_id: String, display_level: int) -> String:
	var result: String = description
	
	# 特殊占位符：根据 upgrade_id 和等级直接计算
	var special: Dictionary = {}
	match upgrade_id:
		"mine":
			special["基础伤害=5lv"] = str(5 * display_level)
			special["mine_max_deployed_value"] = str(10 + 5 * display_level)
			special["冷却时间"] = "3.0"
			special["爆炸范围"] = "%.1f" % (48.0 / GlobalFomulaManager.METERS_TO_PIXELS)
		"smoke_grenade":
			special["smoke_radius_value"] = "1.0"
			special["smoke_slow_value"] = str(20 * max(display_level, 1))
			special["smoke_duration_value"] = "3"
		"radio_support":
			special["radio_damage_value"] = str(50 + 20 * display_level)
			special["radio_radius_value"] = "20.0"
			special["radio_cooldown_value"] = str(60 - 5 * display_level)
		"laser_suppress":
			special["laser_duration_value"] = "5"
			special["laser_range_value"] = "5"
			special["laser_hits_per_second_value"] = "5"
			special["laser_damage_value"] = str(4 + 2 * display_level)
			special["laser_cooldown_value"] = "30"
		"external_missile":
			special["missile_lock_range_value"] = "10"
			special["missile_radius_value"] = "3"
			special["missile_damage_value"] = str(20 + 10 * display_level)
			special["missile_cooldown_value"] = "6"
		"heat_sink":
			special["heat_sink_penalty_value"] = str(5 * display_level)
			var cooling_pct = 0.5 * float(display_level) * float(display_level)
			special["heat_sink_cooling_desc"] = "%.1f%%" % cooling_pct
		"addon_armor":
			special["addon_armor_health_value"] = str(4 * display_level)
			special["addon_armor_reduction_value"] = str(5 * display_level)
		"scatter_shot":
			var intervals = [10, 8, 7, 6, 5]
			var counts = [1, 1, 2, 2, 3]
			var idx = min(display_level - 1, intervals.size() - 1)
			special["scatter_shot_interval_value"] = str(intervals[idx])
			special["scatter_shot_count_value"] = str(counts[idx])
		"windmill":
			var penalties = [20, 30, 40]
			var spreads = [2, 3, 4]
			var idx = min(display_level - 1, penalties.size() - 1)
			special["windmill_damage_penalty_value"] = str(penalties[idx])
			special["windmill_spread_value"] = str(spreads[idx])
		"spread_shot":
			var spreads = [1, 2, 3]
			var ratios = [50, 40, 30]
			var idx = min(display_level - 1, spreads.size() - 1)
			special["spread_shot_spread_value"] = str(spreads[idx])
			special["spread_shot_damage_ratio_value"] = str(ratios[idx])
		"split_shot":
			var counts = [2, 3]
			var idx = min(display_level - 1, counts.size() - 1)
			special["split_shot_count_value"] = str(counts[idx])
		"lethal_strike":
			var intervals = [9, 7, 5, 3]
			var idx = min(display_level - 1, intervals.size() - 1)
			special["lethal_strike_interval_value"] = str(intervals[idx])
		"decoy_drone":
			special["decoy_drone_duration_value"] = str(5 + display_level)
			special["decoy_drone_cooldown_value"] = "30"
		"auto_turret":
			special["auto_turret_damage_value"] = str(3 + 2 * display_level)
			special["auto_turret_cooldown_value"] = "20"
		"repair_beacon":
			special["repair_beacon_heal_value"] = str(1 + display_level)
			special["repair_beacon_duration_value"] = str(5 + display_level)
			special["repair_beacon_cooldown_value"] = "25"
		"shield_emitter":
			special["shield_emitter_capacity_value"] = str(int(UpgradeEffectManager.get_effect("shield_emitter", display_level)))
			special["shield_emitter_duration_value"] = "8"
			special["shield_emitter_cooldown_value"] = "45"
		"emp_pulse":
			special["emp_pulse_duration_value"] = str(int(UpgradeEffectManager.get_effect("emp_pulse", display_level)))
			special["emp_pulse_radius_value"] = "3"
			special["emp_pulse_cooldown_value"] = "25"
		"grav_trap":
			special["grav_trap_radius_value"] = "2"
			special["grav_trap_duration_value"] = str(3 + display_level)
			special["grav_trap_cooldown_value"] = "22"
		"thunder_coil":
			special["thunder_coil_targets_value"] = str(3 + display_level)
			special["thunder_coil_damage_value"] = str(int(UpgradeEffectManager.get_effect("thunder_coil", display_level)))
			special["thunder_coil_cooldown_value"] = "8"
		"cryo_canister":
			special["cryo_canister_radius_value"] = "2"
			special["cryo_canister_duration_value"] = str(3 + display_level)
			special["cryo_canister_cooldown_value"] = "18"
		"incendiary_canister":
			special["incendiary_canister_damage_value"] = str(4 + 2 * display_level)
			special["incendiary_canister_radius_value"] = "2"
			special["incendiary_canister_cooldown_value"] = "15"
		"acid_sprayer":
			special["acid_sprayer_damage_value"] = str(4 + 2 * display_level)
			special["acid_sprayer_cooldown_value"] = "12"
		"cluster_mine":
			special["cluster_mine_damage_value"] = str(6 + 3 * display_level)
			special["cluster_mine_cooldown_value"] = "18"
		"chaff_launcher":
			special["chaff_radius_value"] = "3"
			special["chaff_duration_value"] = "%.1f" % (2.0 + 0.5 * float(display_level))
			special["chaff_cooldown_value"] = "22"
		"flare_dispenser":
			special["flare_duration_value"] = "%.1f" % (2.0 + 0.5 * float(display_level))
			special["flare_cooldown_value"] = "24"
		"nano_armor":
			special["nano_armor_heal_value"] = str(2 + display_level)
			special["nano_armor_cooldown_value"] = "12"
		"fuel_injector_module":
			special["fuel_injector_speed_value"] = str(30 + 5 * display_level)
			special["fuel_injector_duration_value"] = "%.1f" % (2.5 + 0.5 * float(display_level))
			special["fuel_injector_cooldown_value"] = "18"
		"adrenaline_stim":
			special["adrenaline_stim_trigger_value"] = str(30 + 2 * display_level)
			special["adrenaline_stim_duration_value"] = "%.1f" % (3.0 + 0.5 * float(display_level))
		"sonar_scanner":
			special["sonar_range_value"] = "3"
			special["sonar_duration_value"] = "%.1f" % (4.0 + 0.5 * float(display_level))
			special["sonar_cooldown_value"] = "18"
		"ballistic_computer_pod":
			special["ballistic_damage_value"] = str(6 + 4 * display_level)
			special["ballistic_radius_value"] = "1.5"
			special["ballistic_cooldown_value"] = "20"
		"jammer_field":
			special["jammer_radius_value"] = "3"
			special["jammer_duration_value"] = "%.1f" % (3.0 + 0.5 * float(display_level))
			special["jammer_cooldown_value"] = "22"
		"overwatch_uav":
			special["uav_damage_value"] = str(5 + 3 * display_level)
			special["uav_duration_value"] = str(6 + display_level)
			special["uav_cooldown_value"] = "25"
		"grapeshot_pod":
			special["grapeshot_damage_value"] = str(3 + 2 * display_level)
			special["grapeshot_cooldown_value"] = "14"
		"scrap_collector":
			special["scrap_chance_value"] = str(10 + 3 * display_level)
			special["scrap_heal_value"] = str(1 + display_level)
		"kinetic_barrier":
			special["barrier_reduction_value"] = str(25 + 5 * display_level)
			special["barrier_duration_value"] = "%.1f" % (3.0 + 0.5 * float(display_level))
			special["barrier_cooldown_value"] = "30"
		"orbital_ping":
			special["orbital_ping_damage_value"] = str(int(UpgradeEffectManager.get_effect("orbital_ping", display_level)))
			special["orbital_ping_delay_value"] = "3"
			special["orbital_ping_cooldown_value"] = "25"
		"med_spray":
			special["med_spray_heal_value"] = str(1 + display_level)
			special["med_spray_radius_value"] = "1.5"
			special["med_spray_cooldown_value"] = "20"
		"mine_multi_deploy":
			special["mine_multi_damage_penalty"] = str(1 * display_level)
			special["mine_multi_deploy_count"] = str(1 * display_level)
		"mg_overload":
			var penalties = [5, 4, 3]
			var stacks = [12, 15, 20]
			var decays = [1, 2, 3]
			var idx = min(display_level - 1, penalties.size() - 1)
			special["mg_overload_penalty_value"] = str(penalties[idx])
			special["mg_overload_max_stacks_value"] = str(stacks[idx])
			special["mg_overload_decay_value"] = str(decays[idx])
		"ricochet":
			special["ricochet_chance_value"] = str(10 + 10 * display_level)
		"chain_fire":
			special["chain_fire_penalty_value"] = str(5 * display_level)
			special["chain_fire_max_stacks_value"] = str(4 * display_level)
		"burst_fire":
			special["burst_fire_max_stacks_value"] = str(4 * display_level)
		"sweep_fire":
			special["sweep_fire_bonus_value"] = str(50 * display_level)
		"breakthrough":
			special["breakthrough_max_bonus_value"] = str(25 * display_level)
		"fire_suppression":
			special["fire_suppression_per_part_value"] = str(5 * display_level)
		"penetration":
			special["penetration_damage_penalty_value"] = str(10 * display_level)
			special["penetration_penetration_value"] = str(1 * display_level)
		"mg_heavy_round":
			special["mg_heavy_round_penalty_value"] = str(10 * display_level)
			special["mg_heavy_round_damage_value"] = str(1 * display_level)
		"weakpoint_strike":
			var intervals = [4, 3, 3, 2, 2]
			var idx = min(display_level - 1, intervals.size() - 1)
			special["weakpoint_strike_interval_value"] = str(intervals[idx])
		"overdrive_trigger":
			special["overdrive_trigger_value"] = str(7 * display_level)
		"mobility_servos":
			special["mobility_servos_turn_value"] = str(12 * display_level)
			special["mobility_servos_reverse_value"] = str(8 * display_level)
		"windmill_spread":
			special["windmill_spread_damage_penalty_value"] = str(10 * display_level)
			var sp = [1, 2, 3]
			var idx = min(display_level - 1, sp.size() - 1)
			special["windmill_spread_value"] = str(sp[idx])
		"windmill_speed":
			special["windmill_speed_fire_rate_value"] = str(10 * display_level)
			special["windmill_speed_rotation_value"] = str(30 * display_level)
	
	# 百分比类占位符（effect_value 需 *100）
	var pct_ids: Array = [
		"crit_rate", "crit_damage", "damage_bonus", "rapid_fire",
		"cabin_ac", "christie_suspension", "gas_turbine", "relief_valve",
		"cooling_device", "mine_cooldown", "mine_anti_tank",
		"howitzer_reload", "missile_reload", "missile_damage",
		"smoke_range", "smoke_duration",
		"kinetic_buffer", "overpressure_limiter", "armor_breaker",
		"recoil_compensator", "tracer_rounds", "execution_protocol",
		"overdrive_trigger", "kill_chain", "hot_load", "fin_stabilized",
		"battle_awareness", "target_computer", "mobility_servos",
		"flare_cooldown", "fuel_boost", "fuel_efficiency", "stim_trigger_hp",
		"sonar_expose_bonus", "uav_laser_tag", "scrap_drop_rate", "barrier_reflect",
		"cooling_share", "cooling_safeguard", "laser_overheat_cut",
		"turret_pierce", "cryo_slow", "acid_armor_break",
	]
	
	# 通用正则替换
	var regex: RegEx = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	var matches: Array = regex.search_all(result)
	
	for m in matches:
		var ph_name: String = m.get_string(1)
		var placeholder: String = "{%s}" % ph_name
		var display_value: String = ""
		
		if special.has(ph_name):
			display_value = str(special[ph_name])
		elif ph_name.ends_with("_value"):
			# 尝试从 UpgradeEffectManager 获取
			var effect_val: float = UpgradeEffectManager.get_effect(upgrade_id, display_level)
			if effect_val != 0.0:
				if upgrade_id in pct_ids:
					display_value = str(int(effect_val * 100))
				else:
					display_value = str(int(effect_val)) if effect_val == float(int(effect_val)) else "%.1f" % effect_val
			else:
				display_value = "?"
		else:
			continue
		
		var colored: String = "[color=#00ff00]%s[/color]" % display_value
		result = result.replace(placeholder, colored)
	
	return result
