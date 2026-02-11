extends CharacterBody2D

@export var arena_time_manager: Node

@export var rotation_speed: float = 4.0

@onready var damage_interval_timer = $DamageIntervalTimer
@onready var health_component = $HealthComponent
@onready var health_bar = $HealthBar
@onready var abilities = $Abilities
@onready var animation_player = $AnimationPlayer
@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent

var enemys_in_contact = []

var number_colliding_bodies = 0
var base_speed = 0

# 通用强化效果
var global_health_bonus: int = 0
var global_crit_rate_bonus: float = 0.0

# 阶段三：移速倍率（1 + 克里斯蒂 + 燃气轮机等）
var move_speed_multiplier: float = 1.0
# 液气悬挂：受到的移速惩罚减半（后续减速效果会乘此系数）
var hydro_pneumatic_half_penalty: bool = false
# 车载空调：回复耐久后冷却速度 +X% 持续 3 秒
var cabin_ac_active_until_msec: int = 0
# cabin_ac 状态边沿检测：用于 buff 结束时刷新维护工具箱间隔
var _cabin_ac_last_active: bool = false
# 维护工具箱：定时器（代码创建）
var _repair_kit_timer: Timer = null

# 阶段三：升级等级缓存（用于效果计算）
var repair_kit_level: int = 0
var cabin_ac_level: int = 0
var heat_sink_level: int = 0
var addon_armor_level: int = 0
var relief_valve_level: int = 0

# 阶段四：被动配件（一次性）
var has_spall_liner: bool = false
var spall_liner_used: bool = false
var has_era_block: bool = false
var era_block_used: bool = false
var has_ir_counter: bool = false

func before_take_damage(amount: float, _hc: HealthComponent, context: Dictionary) -> float:
	"""HealthComponent.damage 前一层：一次性免死等在此拦截。返回最终伤害值。"""
	if amount <= 0:
		return amount
	# 仅玩家自身的 HealthComponent 会走到这里
	var will_die = (health_component.current_health - amount) <= 0
	if not will_die:
		return amount
	
	# 爆反：抵御一次任意致命伤害（优先）
	if has_era_block and not era_block_used:
		era_block_used = true
		# 让本次伤害后至少剩 1 点耐久
		return max(health_component.current_health - 1, 0)
	
	# 纤维内衬：抵御一次致命击穿伤害
	var is_pierced := bool(context.get("is_pierced", false))
	if is_pierced and has_spall_liner and not spall_liner_used:
		spall_liner_used = true
		return max(health_component.current_health - 1, 0)
	
	return amount

func _ready():
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)
	base_speed = velocity_component.max_speed
	
	$CollisionArea2D.body_entered.connect(on_body_entered)
	$CollisionArea2D.body_exited.connect(on_body_exited)
	damage_interval_timer.timeout.connect(on_damage_interval_timer_timeout)
	health_component.health_decreased.connect(on_health_decreased)
	health_component.health_changed.connect(on_health_changed)
	health_component.healed.connect(_on_player_healed)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	
	# 维护工具箱定时器
	_repair_kit_timer = Timer.new()
	_repair_kit_timer.name = "RepairKitTimer"
	_repair_kit_timer.one_shot = false
	_repair_kit_timer.autostart = false
	add_child(_repair_kit_timer)
	_repair_kit_timer.timeout.connect(_on_repair_kit_timeout)
	
	# 创建 WeaponUpgradeHandler
	var upgrade_handler = WeaponUpgradeHandler.new()
	add_child(upgrade_handler)
	
	await get_tree().process_frame
	init_player_data()
	update_health_display()
	
func init_player_data():
	# 初始化时，根据已有升级重新计算属性
	_recalculate_all_attributes(GameManager.current_upgrades)
	_apply_health_bonus()

	# 根据配装添加Ability
	setup_equipped_abilities()
	# 同步被动配件状态
	_sync_passive_accessories(GameManager.current_upgrades)

func _apply_health_bonus():
	"""应用耐久加成：基础 + health + addon_armor - heat_sink，同时更新移速与维护工具箱"""
	var base_health = GameManager.get_player_max_health()
	var old_max = health_component.max_health
	var new_max = base_health + global_health_bonus
	var increase = new_max - old_max
	
	health_component.max_health = new_max
	if increase > 0:
		health_component.current_health += increase
	else:
		health_component.current_health = min(health_component.current_health, new_max)
	update_health_display()
	
	# 移速：base_speed * move_speed_multiplier
	# 液气悬挂：若存在移速惩罚（倍率<1），惩罚减半
	var final_speed_multiplier := move_speed_multiplier
	if hydro_pneumatic_half_penalty and final_speed_multiplier < 1.0:
		var penalty := 1.0 - final_speed_multiplier
		final_speed_multiplier = 1.0 - penalty * 0.5
	velocity_component.max_speed = int(base_speed * final_speed_multiplier)
	
	# 维护工具箱：刷新间隔并启停
	_update_repair_kit_timer()

func get_global_crit_rate_bonus() -> float:
	"""获取全局暴击率加成（供外部调用）"""
	return global_crit_rate_bonus

func _process(delta):
	var rotation_input = Input.get_action_strength("right") - Input.get_action_strength("left")
	rotation += rotation_input * rotation_speed * delta
	
	var move_input = Input.get_action_strength("up") - Input.get_action_strength("down")
	var direction = Vector2.ZERO
	if move_input != 0:
		direction = transform.x * sign(move_input)

	velocity_component.accelerate_in_direction(direction.normalized())
	velocity_component.move(self)
	
	# cabin_ac buff 结束时，刷新维护工具箱间隔（避免一直保持加速）
	var cabin_ac_active_now := (Time.get_ticks_msec() < cabin_ac_active_until_msec)
	if _cabin_ac_last_active and not cabin_ac_active_now:
		_update_repair_kit_timer()
	_cabin_ac_last_active = cabin_ac_active_now
	
	# if move_input != 0:
	# 	# animation_player.play("walk")
	# 	pass
	# else:
	# 	# animation_player.play("RESET")
	# 	pass


func check_deal_damage():
	if number_colliding_bodies == 0 || !damage_interval_timer.is_stopped():
		return

	var damage: float = 0
	var pierced_any: bool = false
	# 红外对抗：选取 5m 内“正在瞄准玩家”的最近远程敌人
	var ir_target: Node2D = null
	if has_ir_counter:
		ir_target = _get_nearest_aiming_ranged_enemy(5.0)
	
	for body in enemys_in_contact:
		if body.is_in_group("enemy"):
			var player_armor_thickness = GameManager.get_player_armor_thickness()
			var depth_mm := int(body.hard_attack_depth_mm)
			# 红外对抗：对目标敌人的“穿甲率固定为0%”——这里实现为强制不击穿（hard_attack_depth_mm=0）
			if ir_target != null and body == ir_target:
				depth_mm = 0
			var raw_damage := float(GlobalFomulaManager.calculate_damage(
				body.base_damage,
				body.hardAttackMultiplierPercent,
				body.soft_attack_multiplier_percent,
				depth_mm,
				player_armor_thickness,
				GameManager.get_player_armor_coverage(),
				GameManager.get_player_armor_damage_reduction_percent()
			))
			
			# 阶段三：击穿减伤（addon_armor / relief_valve）
			var is_pierced := (int(body.hard_attack_depth_mm) > int(player_armor_thickness))
			if is_pierced:
				pierced_any = true
				raw_damage *= (1.0 - _get_pierce_damage_reduction_ratio())
			
			damage += raw_damage

			# print( body.name )
			# print("armor thickness:", body.armor_thickness)
			# print("armor coverage:", body.armorCoverage)
			# print("base damage:", body.base_damage)
			# print("soft attack multiplier percent:", body.soft_attack_multiplier_percent)
			# print("hard attack multiplier percent:", body.hardAttackMultiplierPercent)
			# print("hard attack depth mm:", body.hard_attack_depth_mm)

	print("enemy damage to player:", damage)
	health_component.damage(damage, {"is_pierced": pierced_any, "damage_source": "enemy_collision"})
	damage_interval_timer.start()

func update_health_display():
	health_bar.value = health_component.get_health_percent()
	GameEvents.health_changed.emit(health_component.current_health, health_component.max_health)

func on_body_entered(other_body: Node2D):
	number_colliding_bodies += 1

	if enemys_in_contact.has(other_body):
		return
	enemys_in_contact.append(other_body)
	check_deal_damage()


func on_body_exited(other_body: Node2D):
	number_colliding_bodies -= 1

	if enemys_in_contact.has(other_body):
		enemys_in_contact.erase(other_body)


func on_damage_interval_timer_timeout():
	check_deal_damage()


func on_health_decreased():
	GameEvents.emit_player_damaged()
	$HitRandomStreamPlayer.play_random()
	

func on_health_changed():
	update_health_display()
	
func on_ability_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	# 不再累加，而是重新计算所有属性
	_recalculate_all_attributes(current_upgrades)
	_sync_passive_accessories(current_upgrades)
	
	# 检查是否是配件，如果是则动态添加Controller
	var upgrade_manager = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_manager and upgrade_manager.has_method("get_session_equipped_accessories"):
		var equipped_accessories = upgrade_manager.get_session_equipped_accessories()
		
		# 检查是否刚获得了新配件
		var entry = AbilityUpgradeData.get_entry(upgrade_id)
		if entry and entry.get("upgrade_type", "") == "accessory":
			# 检查是否已经实例化了该配件的Controller
			var controller_exists = false
			for child in abilities.get_children():
				match upgrade_id:
					"mine":
						if child is MineAbilityController:
							controller_exists = true
							break
					"smoke_grenade":
						if child is SmokeGrenadeAbilityController:
							controller_exists = true
							break
					"radio_support":
						if child is RadioSupportAbilityController:
							controller_exists = true
							break
					"laser_suppress":
						if child is LaserSuppressAbilityController:
							controller_exists = true
							break
					"external_missile":
						if child is ExternalMissileAbilityController:
							controller_exists = true
							break
					# 其他配件...
			
			# 如果不存在，则实例化
			if not controller_exists and upgrade_id in equipped_accessories:
				match upgrade_id:
					"mine":
						var mine_controller = preload("res://scenes/ability/mine_ability_controller/mine_ability_controller.tscn").instantiate()
						abilities.add_child(mine_controller)
						print("已装备地雷")
					"smoke_grenade":
						var smoke_controller = preload("res://scenes/ability/smoke_grenade_ability_controller/smoke_grenade_ability_controller.tscn").instantiate()
						abilities.add_child(smoke_controller)
						print("已装备烟雾弹")
					"radio_support":
						var radio_controller = preload("res://scenes/ability/radio_support_ability_controller/radio_support_ability_controller.tscn").instantiate()
						abilities.add_child(radio_controller)
						print("已装备无线电通讯")
					"laser_suppress":
						var laser_controller = preload("res://scenes/ability/laser_suppress_ability_controller/laser_suppress_ability_controller.tscn").instantiate()
						abilities.add_child(laser_controller)
						print("已装备激光压制")
					"external_missile":
						var missile_controller = preload("res://scenes/ability/external_missile_ability_controller/external_missile_ability_controller.tscn").instantiate()
						abilities.add_child(missile_controller)
						print("已装备外挂导弹")
					# 其他配件...
	
	print("-------------------")	
	print("基础伤害: " + str(GameManager.get_player_base_damage()))
	print("硬攻倍率: " + str(GameManager.get_player_hard_attack_multiplier_percent()))
	print("软攻倍率: " + str(GameManager.get_player_soft_attack_multiplier_percent()))
	print("硬攻深度: " + str(GameManager.get_player_hard_attack_depth_mm()))
	print("装甲厚度: " + str(GameManager.get_player_armor_thickness()))
	print("覆甲率: " + str(GameManager.get_player_armor_coverage()))
	print("击穿伤害减免: " + str(GameManager.get_player_armor_damage_reduction_percent()))
	print("全局暴击率: " + str(global_crit_rate_bonus * 100) + "%")
	print("耐久加成: " + str(global_health_bonus))
	print("-------------------")

func _reset_to_base_values():
	"""重置所有属性到基础值"""
	global_health_bonus = 0
	global_crit_rate_bonus = 0.0
	move_speed_multiplier = 1.0
	hydro_pneumatic_half_penalty = false
	repair_kit_level = 0
	cabin_ac_level = 0
	heat_sink_level = 0
	addon_armor_level = 0
	relief_valve_level = 0

func _recalculate_all_attributes(current_upgrades: Dictionary):
	"""根据当前所有升级重新计算属性"""
	# 先重置到基础值
	_reset_to_base_values()
	
	# 遍历所有通用升级，累加效果
	for upgrade_id in current_upgrades.keys():
		# 处理旧的 global_ 开头的强化和新的通用强化
		var is_global_upgrade = upgrade_id.begins_with("global_")
		var is_new_global_upgrade = upgrade_id in [
			"health", "crit_rate", "crit_damage", "damage_bonus",
			# 阶段三
			"repair_kit", "cabin_ac", "heat_sink",
			"christie_suspension", "gas_turbine", "hydro_pneumatic",
			"addon_armor", "relief_valve",
		]
		
		if not is_global_upgrade and not is_new_global_upgrade:
			continue
		
		var level = current_upgrades[upgrade_id].get("level", 0)
		if level <= 0:
			continue
		
		var effect_value = UpgradeEffectManager.get_effect(upgrade_id, level)
		
		match upgrade_id:
			"global_health_1", "global_health_2", "global_health_3", "global_health_4", "health":
				global_health_bonus += int(effect_value)
			"global_crit_rate_1", "global_crit_rate_2", "crit_rate":
				global_crit_rate_bonus += effect_value
			# ===== 阶段三 =====
			"repair_kit":
				repair_kit_level = level
			"cabin_ac":
				cabin_ac_level = level
			"heat_sink":
				heat_sink_level = level
				# 耐久上限 -5lv（effect_value=5*lv）
				global_health_bonus -= int(effect_value)
			"christie_suspension":
				move_speed_multiplier += effect_value
			"gas_turbine":
				move_speed_multiplier += effect_value
			"hydro_pneumatic":
				hydro_pneumatic_half_penalty = true
			"addon_armor":
				addon_armor_level = level
				# 耐久 +4lv（effect_value=4*lv）
				global_health_bonus += int(effect_value)
			"relief_valve":
				relief_valve_level = level
	
	# 应用耐久加成
	_apply_health_bonus()


func _get_cooling_speed_bonus() -> float:
	"""全局冷却速度加成（倍率加成部分）。用于维护工具箱等“冷却类”强化。"""
	var bonus := 0.0
	
	# 散热器：全局冷却速度 +{初始耐久上限-耐久上限}*0.1lv%
	# 当前实现：差值 = 5*heat_sink_level
	if heat_sink_level > 0:
		var diff := 5.0 * float(heat_sink_level)
		bonus += diff * 0.001 * float(heat_sink_level)  # diff * 0.1*lv% => diff * 0.001 * lv
	
	# 车载空调：回复耐久时，冷却速度 +5lv%，持续3秒，不叠加
	if cabin_ac_level > 0 and Time.get_ticks_msec() < cabin_ac_active_until_msec:
		bonus += UpgradeEffectManager.get_effect("cabin_ac", cabin_ac_level)
	
	return max(bonus, 0.0)


func _get_repair_kit_interval_seconds() -> float:
	"""维护工具箱间隔（秒）= 基础间隔 / (1 + 冷却速度加成)。"""
	if repair_kit_level <= 0:
		return INF
	var base_interval := UpgradeEffectManager.get_effect("repair_kit", repair_kit_level)
	var speed_multiplier := 1.0 + _get_cooling_speed_bonus()
	if speed_multiplier <= 0.0:
		return INF
	return max(float(base_interval) / speed_multiplier, 0.2)


func _update_repair_kit_timer():
	if _repair_kit_timer == null:
		return
	if repair_kit_level <= 0:
		if not _repair_kit_timer.is_stopped():
			_repair_kit_timer.stop()
		return
	var interval := _get_repair_kit_interval_seconds()
	if is_inf(interval):
		if not _repair_kit_timer.is_stopped():
			_repair_kit_timer.stop()
		return
	_repair_kit_timer.wait_time = interval
	if _repair_kit_timer.is_stopped():
		_repair_kit_timer.start()


func _on_repair_kit_timeout():
	# 每次触发回复 1 点耐久（回复事件会通过 HealthComponent.healed 触发 cabin_ac）
	health_component.heal(1)


func _on_player_healed(_amount: int):
	# 车载空调：回复耐久时触发 3 秒冷却加速，不可叠加
	if cabin_ac_level <= 0:
		return
	if Time.get_ticks_msec() < cabin_ac_active_until_msec:
		return
	cabin_ac_active_until_msec = Time.get_ticks_msec() + 3000
	_update_repair_kit_timer()


func _get_pierce_damage_reduction_ratio() -> float:
	"""被击穿时受到伤害减免（0~0.95）。"""
	var reduction := 0.0
	
	# 车身附加装甲：5%*等级（从 config 读取）
	if addon_armor_level > 0:
		var cfg := UpgradeEffectManager.get_config("addon_armor")
		var per_level := float(cfg.get("pierce_reduction_per_level", 0.0))
		reduction += per_level * float(addon_armor_level)
	
	# 泄压阀：10%*等级（get_effect 直接返回比例）
	if relief_valve_level > 0:
		reduction += UpgradeEffectManager.get_effect("relief_valve", relief_valve_level)
	
	return clamp(reduction, 0.0, 0.95)

func setup_equipped_abilities():
	"""根据当前车辆配装设置Ability"""
	var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
	if vehicle_config == null:
		return

	# 主武器（英文 id：machine_gun / howitzer / tank_gun / missile）
	var main_weapon_id = vehicle_config.get("主武器类型")
	if main_weapon_id is String:
		match main_weapon_id:
			"machine_gun":
				var machine_gun_controller = preload("res://scenes/ability/machine_gun_ability_controller/machine_gun_ability_controller.tscn").instantiate()
				abilities.add_child(machine_gun_controller)
				print("已装备机炮")
			"howitzer":
				var howitzer_controller = preload("res://scenes/ability/howitzer_ability_controller/howitzer_ability_controller.tscn").instantiate()
				abilities.add_child(howitzer_controller)
				print("已装备榴弹炮")
			"tank_gun":
				var tank_gun_controller = preload("res://scenes/ability/tank_gun_ability_controller/tank_gun_ability_controller.tscn").instantiate()
				abilities.add_child(tank_gun_controller)
				print("已装备坦克炮")
			"missile":
				var missile_controller = preload("res://scenes/ability/missile_weapon_ability_controller/missile_weapon_ability_controller.tscn").instantiate()
				abilities.add_child(missile_controller)
				print("已装备导弹主武器")
	
	# 配件：带入的（从 GameManager 读）+ 局内选的（从 UpgradeManager session 读）
	var equipped_accessories: Array = []
	equipped_accessories.append_array(GameManager.get_brought_in_accessories())
	var upgrade_manager = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_manager and upgrade_manager.has_method("get_session_equipped_accessories"):
		equipped_accessories.append_array(upgrade_manager.get_session_equipped_accessories())
	for accessory_id in equipped_accessories:
		if accessory_id is not String:
			continue
		match accessory_id:
			"mine":
				var mine_controller = preload("res://scenes/ability/mine_ability_controller/mine_ability_controller.tscn").instantiate()
				abilities.add_child(mine_controller)
				print("已装备地雷")
			"smoke_grenade":
				var smoke_controller = preload("res://scenes/ability/smoke_grenade_ability_controller/smoke_grenade_ability_controller.tscn").instantiate()
				abilities.add_child(smoke_controller)
				print("已装备烟雾弹")
			"radio_support":
				var radio_controller = preload("res://scenes/ability/radio_support_ability_controller/radio_support_ability_controller.tscn").instantiate()
				abilities.add_child(radio_controller)
				print("已装备无线电通讯")
			"laser_suppress":
				var laser_controller = preload("res://scenes/ability/laser_suppress_ability_controller/laser_suppress_ability_controller.tscn").instantiate()
				abilities.add_child(laser_controller)
				print("已装备激光压制")
			"external_missile":
				var missile_controller = preload("res://scenes/ability/external_missile_ability_controller/external_missile_ability_controller.tscn").instantiate()
				abilities.add_child(missile_controller)
				print("已装备外挂导弹")
			# 其他配件...

func _sync_passive_accessories(current_upgrades: Dictionary):
	"""根据 current_upgrades 同步被动配件拥有状态（不重置已消耗状态）"""
	has_spall_liner = current_upgrades.get("spall_liner", {}).get("level", 0) > 0
	has_era_block = current_upgrades.get("era_block", {}).get("level", 0) > 0
	has_ir_counter = current_upgrades.get("ir_counter", {}).get("level", 0) > 0

func _get_nearest_aiming_ranged_enemy(range_m: float) -> Node2D:
	var player = self as Node2D
	var range_px := range_m * GlobalFomulaManager.METERS_TO_PIXELS
	var ranged = get_tree().get_nodes_in_group("ranged_enemy")
	var target: Node2D = null
	var best := INF
	for e in ranged:
		if not is_instance_valid(e):
			continue
		if e.get("is_aiming_player") != true:
			continue
		var d2 = e.global_position.distance_squared_to(player.global_position)
		if d2 <= range_px * range_px and d2 < best:
			best = d2
			target = e
	return target

func on_arena_difficulty_increased(difficulty: int):
	var health_regeneration_quantity = MetaProgression.get_upgrade_count("health_regeneration")
	if health_regeneration_quantity > 0:
		var is_thirty_second_interval = (difficulty % 6) == 0
		if is_thirty_second_interval:
			health_component.heal(health_regeneration_quantity)
