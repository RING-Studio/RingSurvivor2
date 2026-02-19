extends CharacterBody2D

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var arena_time_manager: Node

@export var rotation_speed: float = 1.0

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
var spall_liner_charges: int = 0
var spall_liner_max_charges: int = 0
var _spall_rearm_at_msec: int = 0
var era_block_charges: int = 0
var era_block_max_charges: int = 0
var _era_rearm_at_msec: int = 0

# 阶段八：新增配件/强化等级缓存
var emergency_repair_level: int = 0
var _emergency_repair_timer: Timer = null
var reinforced_bulkhead_level: int = 0
var reinforced_bulkhead_charges: int = 0
var kinetic_buffer_level: int = 0
var overpressure_limiter_level: int = 0
var _overpressure_active_until_msec: int = 0
var mobility_servos_level: int = 0
var target_computer_level: int = 0

# 临时移动速度加成
var _temp_speed_multiplier: float = 1.0
var _temp_speed_bonus_until_msec: int = 0

# 纳米装甲临时护盾
var _nano_overcap_shield: float = 0.0
var _nano_overcap_until_msec: int = 0

# 动能屏障
var _kinetic_barrier_reduction: float = 0.0
var _kinetic_barrier_until_msec: int = 0

func before_take_damage(amount: float, _hc: HealthComponent, context: Dictionary) -> float:
	"""HealthComponent.damage 前一层：护盾吸收 → 减伤 → 一次性免死。返回最终伤害值。"""
	if amount <= 0:
		return amount
	
	# 护盾吸收（shield_emitter）：优先消耗护盾
	var shield_ctrl: Node = _get_shield_emitter_controller()
	if shield_ctrl and shield_ctrl.shield_remaining > 0:
		amount = shield_ctrl.absorb_damage(amount)
		if amount <= 0:
			return 0.0
	
	# 纳米装甲临时护盾
	if _nano_overcap_shield > 0.0:
		if Time.get_ticks_msec() >= _nano_overcap_until_msec:
			_nano_overcap_shield = 0.0
		else:
			var absorbed: float = min(amount, _nano_overcap_shield)
			_nano_overcap_shield -= absorbed
			amount -= absorbed
			if amount <= 0.0:
				return 0.0
	
	# 动能屏障减伤（仅在持续时间内）
	if _kinetic_barrier_reduction > 0.0 and Time.get_ticks_msec() < _kinetic_barrier_until_msec:
		amount *= (1.0 - _kinetic_barrier_reduction)
	
	var is_pierced: bool = bool(context.get("is_pierced", false))
	
	# 动能缓冲：非击穿伤害减免 6%*lv
	if kinetic_buffer_level > 0 and not is_pierced:
		var reduction: float = 0.06 * float(kinetic_buffer_level)
		amount *= (1.0 - reduction)
	
	# 超压限制器：被连续命中后 2 秒内受伤 -8%*lv
	if overpressure_limiter_level > 0 and Time.get_ticks_msec() < _overpressure_active_until_msec:
		var reduction: float = 0.08 * float(overpressure_limiter_level)
		amount *= (1.0 - reduction)
	# 记录本次受伤，激活超压限制器 2 秒
	if overpressure_limiter_level > 0:
		_overpressure_active_until_msec = Time.get_ticks_msec() + 2000
	
	# 仅玩家自身的 HealthComponent 会走到这里
	var will_die = (health_component.current_health - amount) <= 0
	if not will_die:
		return amount
	
	# 加固隔舱：致命伤时保留 1 点耐久（每局 1+lv 次）
	if reinforced_bulkhead_level > 0 and reinforced_bulkhead_charges > 0:
		reinforced_bulkhead_charges -= 1
		return max(health_component.current_health - 1, 0)
	
	# 爆反：抵御一次任意致命伤害（优先）
	if has_era_block and era_block_charges > 0:
		era_block_charges -= 1
		var rearm_level = GameManager.current_upgrades.get("era_rearm", {}).get("level", 0)
		if rearm_level > 0 and era_block_charges < era_block_max_charges:
			_era_rearm_at_msec = Time.get_ticks_msec() + int(_get_era_rearm_seconds(rearm_level) * 1000.0)
		var shock_level = GameManager.current_upgrades.get("era_shockwave", {}).get("level", 0)
		if shock_level > 0:
			_trigger_era_shockwave(shock_level)
		return max(health_component.current_health - 1, 0)
	
	# 纤维内衬：抵御一次致命击穿伤害
	if is_pierced and has_spall_liner and spall_liner_charges > 0:
		spall_liner_charges -= 1
		var rearm_level = GameManager.current_upgrades.get("spall_reload", {}).get("level", 0)
		if rearm_level > 0 and spall_liner_charges < spall_liner_max_charges:
			_spall_rearm_at_msec = Time.get_ticks_msec() + int(_get_spall_rearm_seconds(rearm_level) * 1000.0)
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
	
	# 应急抢修定时器
	_emergency_repair_timer = Timer.new()
	_emergency_repair_timer.name = "EmergencyRepairTimer"
	_emergency_repair_timer.one_shot = false
	_emergency_repair_timer.autostart = false
	_emergency_repair_timer.wait_time = 5.0
	add_child(_emergency_repair_timer)
	_emergency_repair_timer.timeout.connect(_on_emergency_repair_timeout)
	
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
	var final_speed_multiplier: float = move_speed_multiplier
	if _temp_speed_multiplier > 1.0:
		final_speed_multiplier *= _temp_speed_multiplier
	if hydro_pneumatic_half_penalty and final_speed_multiplier < 1.0:
		var penalty: float = 1.0 - final_speed_multiplier
		final_speed_multiplier = 1.0 - penalty * 0.5
	velocity_component.max_speed = int(base_speed * final_speed_multiplier)
	
	# 机动伺服：转向响应 +12%*lv
	if mobility_servos_level > 0:
		rotation_speed = 1.0 * (1.0 + 0.12 * float(mobility_servos_level))
	else:
		rotation_speed = 1.0
	
	# 维护工具箱：刷新间隔并启停
	_update_repair_kit_timer()

func get_global_crit_rate_bonus() -> float:
	"""获取全局暴击率加成（供外部调用）"""
	return global_crit_rate_bonus

func _process(delta):
	# 临时速度加成到期
	if _temp_speed_multiplier > 1.0 and Time.get_ticks_msec() >= _temp_speed_bonus_until_msec:
		_temp_speed_multiplier = 1.0
		_apply_health_bonus()
	
	# 纤维内衬 / 爆反 复位
	_handle_passive_rearm()
	
	# 有 GUI 正在接收输入时（如控制台），跳过移动
	var console: Node = get_node_or_null("/root/DebugConsole")
	if console != null and console.get("is_consuming_input"):
		velocity_component.accelerate_in_direction(Vector2.ZERO)
		velocity_component.move(self)
	else:
		var rotation_input = Input.get_action_strength("right") - Input.get_action_strength("left")
		rotation += rotation_input * rotation_speed * delta
		
		var move_input = Input.get_action_strength("up") - Input.get_action_strength("down")
		var direction = Vector2.ZERO
		if move_input != 0:
			direction = transform.x * sign(move_input)

		velocity_component.accelerate_in_direction(direction.normalized())
		velocity_component.move(self)
	
	# cabin_ac buff 结束时，刷新维护工具箱间隔（避免一直保持加速）
	var cabin_ac_active_now: bool = (Time.get_ticks_msec() < cabin_ac_active_until_msec)
	if _cabin_ac_last_active and not cabin_ac_active_now:
		_update_repair_kit_timer()
	_cabin_ac_last_active = cabin_ac_active_now
	
	pass

func _handle_passive_rearm() -> void:
	var now = Time.get_ticks_msec()
	# 纤维内衬复位
	if has_spall_liner and spall_liner_charges < spall_liner_max_charges and _spall_rearm_at_msec > 0 and now >= _spall_rearm_at_msec:
		spall_liner_charges += 1
		if spall_liner_charges < spall_liner_max_charges:
			var reload_level = GameManager.current_upgrades.get("spall_reload", {}).get("level", 0)
			if reload_level > 0:
				_spall_rearm_at_msec = now + int(_get_spall_rearm_seconds(reload_level) * 1000.0)
			else:
				_spall_rearm_at_msec = 0
		else:
			_spall_rearm_at_msec = 0
	
	# 爆反复位
	if has_era_block and era_block_charges < era_block_max_charges and _era_rearm_at_msec > 0 and now >= _era_rearm_at_msec:
		era_block_charges += 1
		if era_block_charges < era_block_max_charges:
			var rearm_level = GameManager.current_upgrades.get("era_rearm", {}).get("level", 0)
			if rearm_level > 0:
				_era_rearm_at_msec = now + int(_get_era_rearm_seconds(rearm_level) * 1000.0)
			else:
				_era_rearm_at_msec = 0
		else:
			_era_rearm_at_msec = 0

func _get_spall_rearm_seconds(level: int) -> float:
	var base: float = 45.0
	var reduction: float = UpgradeEffectManager.get_effect("spall_reload", level)
	return max(base - reduction, 12.0)

func _get_era_rearm_seconds(level: int) -> float:
	var base: float = 60.0
	var reduction: float = UpgradeEffectManager.get_effect("era_rearm", level)
	return max(base - reduction, 15.0)

func _get_ir_counter_range_m() -> float:
	var bonus_level = GameManager.current_upgrades.get("ir_wideband", {}).get("level", 0)
	return 5.0 + UpgradeEffectManager.get_effect("ir_wideband", bonus_level)

func _get_ir_lockbreak_seconds() -> float:
	var bonus_level = GameManager.current_upgrades.get("ir_lockbreak", {}).get("level", 0)
	return UpgradeEffectManager.get_effect("ir_lockbreak", bonus_level)

func _trigger_era_shockwave(level: int) -> void:
	var radius_px: float = 2.0 * GlobalFomulaManager.METERS_TO_PIXELS
	var base_damage: float = 8.0 + UpgradeEffectManager.get_effect("era_shockwave", level)
	
	# 伤害加成
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		base_damage *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	# 暴击参数
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	# 视觉冲击
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(radius_px, Color(1.0, 0.6, 0.2, 80.0 / 255.0), 0.2)
		layer.add_child(fx)
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var d2 = (enemy as Node2D).global_position.distance_squared_to(global_position)
		if d2 > radius_px * radius_px:
			continue
		var dmg = base_damage
		var is_critical = randf() < base_crit_rate
		if is_critical:
			dmg *= crit_damage_multiplier
		var armor_coverage: float = 0.0
		if enemy.get("armorCoverage") != null:
			armor_coverage = float(enemy.get("armorCoverage"))
		elif enemy.get("armor_coverage") != null:
			armor_coverage = float(enemy.get("armor_coverage"))
		var final_damage = GlobalFomulaManager.calculate_damage(
			dmg,
			GameManager.get_player_hard_attack_multiplier_percent(),
			GameManager.get_player_soft_attack_multiplier_percent(),
			GameManager.get_player_hard_attack_depth_mm(),
			enemy.get("armor_thickness") if enemy.get("armor_thickness") else 0,
			armor_coverage,
			enemy.get("hardAttackDamageReductionPercent") if enemy.get("hardAttackDamageReductionPercent") else 0.0
		)
		var hurtbox = enemy.get_node_or_null("HurtboxComponent")
		if hurtbox:
			hurtbox.apply_damage(final_damage, "accessory", is_critical)


func check_deal_damage():
	if number_colliding_bodies == 0 || !damage_interval_timer.is_stopped():
		return

	var damage: float = 0
	var pierced_any: bool = false
	# 红外对抗：选取范围内“正在瞄准玩家”的最近远程敌人
	var ir_target: Node2D = null
	if has_ir_counter:
		ir_target = _get_nearest_aiming_ranged_enemy(_get_ir_counter_range_m())
		var lock_seconds = _get_ir_lockbreak_seconds()
		if ir_target != null and lock_seconds > 0.0 and ir_target.has_method("disable_aiming"):
			ir_target.disable_aiming(lock_seconds)
	
	for body in enemys_in_contact:
		if body.is_in_group("enemy"):
			var player_armor_thickness = GameManager.get_player_armor_thickness()
			var depth_mm: int = int(body.hard_attack_depth_mm)
			# 红外对抗：对目标敌人的“穿甲率固定为0%”——这里实现为强制不击穿（hard_attack_depth_mm=0）
			if ir_target != null and body == ir_target:
				depth_mm = 0
			var raw_damage: float = float(GlobalFomulaManager.calculate_damage(
				body.base_damage,
				body.hardAttackMultiplierPercent,
				body.soft_attack_multiplier_percent,
				depth_mm,
				player_armor_thickness,
				GameManager.get_player_armor_coverage(),
				GameManager.get_player_armor_damage_reduction_percent()
			))
			
			# 阶段三：击穿减伤（addon_armor / relief_valve）
			var is_pierced: bool = (int(body.hard_attack_depth_mm) > int(player_armor_thickness))
			if is_pierced:
				pierced_any = true
				raw_damage *= (1.0 - _get_pierce_damage_reduction_ratio())
			
			damage += raw_damage

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
			var controller_exists: bool = _has_accessory_controller(upgrade_id)
			
			# 如果不存在，则实例化
			if not controller_exists and upgrade_id in equipped_accessories:
				_instantiate_accessory_controller(upgrade_id)
	

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
	# 阶段八
	emergency_repair_level = 0
	reinforced_bulkhead_level = 0
	kinetic_buffer_level = 0
	overpressure_limiter_level = 0
	mobility_servos_level = 0
	target_computer_level = 0

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
			# 阶段八
			"emergency_repair", "reinforced_bulkhead", "kinetic_buffer",
			"overpressure_limiter", "mobility_servos", "target_computer",
			# 阶段十五
			"thermal_imager", "laser_rangefinder", "extra_ammo_rack",
		]
		
		if not is_global_upgrade and not is_new_global_upgrade:
			continue
		
		var level = current_upgrades[upgrade_id].get("level", 0)
		if level <= 0:
			continue
		
		var effect_value = UpgradeEffectManager.get_effect(upgrade_id, level)
		
		match upgrade_id:
			"health":
				global_health_bonus += int(effect_value)
			"crit_rate":
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
			# ===== 阶段八 =====
			"emergency_repair":
				emergency_repair_level = level
			"reinforced_bulkhead":
				reinforced_bulkhead_level = level
				reinforced_bulkhead_charges = 1 + level
			"kinetic_buffer":
				kinetic_buffer_level = level
			"overpressure_limiter":
				overpressure_limiter_level = level
			"mobility_servos":
				mobility_servos_level = level
			"target_computer":
				target_computer_level = level
			# ===== 阶段十五 =====
			"thermal_imager":
				global_crit_rate_bonus += effect_value
			"laser_rangefinder":
				global_crit_rate_bonus += effect_value
			"extra_ammo_rack":
				var cfg: Dictionary = UpgradeEffectManager.get_config("extra_ammo_rack")
				var hp_penalty: float = float(cfg.get("hp_penalty_per_level", 5.0)) * float(level)
				global_health_bonus -= int(hp_penalty)
				var speed_penalty: float = float(cfg.get("speed_penalty", 0.10))
				move_speed_multiplier -= speed_penalty
	
	# 应用耐久加成
	_apply_health_bonus()
	# 更新应急抢修定时器
	_update_emergency_repair_timer()


func _get_cooling_speed_bonus() -> float:
	"""全局冷却速度加成（倍率加成部分）。用于维护工具箱等“冷却类”强化。"""
	var bonus: float = 0.0
	
	# 散热器：全局冷却速度 +{初始耐久上限-耐久上限}*0.1lv%
	# 当前实现：差值 = 5*heat_sink_level
	if heat_sink_level > 0:
		var diff: float = 5.0 * float(heat_sink_level)
		bonus += diff * 0.001 * float(heat_sink_level)  # diff * 0.1*lv% => diff * 0.001 * lv
	
	# 车载空调：回复耐久时，冷却速度 +5lv%，持续3秒，不叠加
	if cabin_ac_level > 0 and Time.get_ticks_msec() < cabin_ac_active_until_msec:
		bonus += UpgradeEffectManager.get_effect("cabin_ac", cabin_ac_level)
	
	return max(bonus, 0.0)


func _get_repair_kit_interval_seconds() -> float:
	"""维护工具箱间隔（秒）= 基础间隔 / (1 + 冷却速度加成)。"""
	if repair_kit_level <= 0:
		return INF
	var base_interval: float = UpgradeEffectManager.get_effect("repair_kit", repair_kit_level)
	var speed_multiplier: float = 1.0 + _get_cooling_speed_bonus()
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
	var interval: float = _get_repair_kit_interval_seconds()
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
	var reduction: float = 0.0
	
	# 车身附加装甲：5%*等级（从 config 读取）
	if addon_armor_level > 0:
		var cfg: Dictionary = UpgradeEffectManager.get_config("addon_armor")
		var per_level: float = float(cfg.get("pierce_reduction_per_level", 0.0))
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
			"howitzer":
				var howitzer_controller = preload("res://scenes/ability/howitzer_ability_controller/howitzer_ability_controller.tscn").instantiate()
				abilities.add_child(howitzer_controller)
			"tank_gun":
				var tank_gun_controller = preload("res://scenes/ability/tank_gun_ability_controller/tank_gun_ability_controller.tscn").instantiate()
				abilities.add_child(tank_gun_controller)
			"missile":
				var missile_controller = preload("res://scenes/ability/missile_weapon_ability_controller/missile_weapon_ability_controller.tscn").instantiate()
				abilities.add_child(missile_controller)
	
	# 配件：带入的（从 GameManager 读）+ 局内选的（从 UpgradeManager session 读）
	var equipped_accessories: Array = []
	equipped_accessories.append_array(GameManager.get_brought_in_accessories())
	var upgrade_manager = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_manager and upgrade_manager.has_method("get_session_equipped_accessories"):
		equipped_accessories.append_array(upgrade_manager.get_session_equipped_accessories())
	for accessory_id in equipped_accessories:
		if accessory_id is not String:
			continue
		_instantiate_accessory_controller(accessory_id)

func _sync_passive_accessories(current_upgrades: Dictionary):
	"""根据 current_upgrades 同步被动配件拥有状态（不重置已消耗状态）"""
	has_spall_liner = current_upgrades.get("spall_liner", {}).get("level", 0) > 0
	has_era_block = current_upgrades.get("era_block", {}).get("level", 0) > 0
	has_ir_counter = current_upgrades.get("ir_counter", {}).get("level", 0) > 0
	
	# 纤维内衬：补充最大次数
	var spall_reserve_level = current_upgrades.get("spall_reserve", {}).get("level", 0)
	var new_spall_max = (1 + spall_reserve_level) if has_spall_liner else 0
	if new_spall_max > spall_liner_max_charges:
		var diff = new_spall_max - spall_liner_max_charges
		spall_liner_charges += diff
	spall_liner_max_charges = new_spall_max
	if not has_spall_liner:
		spall_liner_charges = 0
		spall_liner_max_charges = 0
		_spall_rearm_at_msec = 0
	else:
		var spall_reload_level = current_upgrades.get("spall_reload", {}).get("level", 0)
		if spall_reload_level > 0 and spall_liner_charges < spall_liner_max_charges and _spall_rearm_at_msec == 0:
			_spall_rearm_at_msec = Time.get_ticks_msec() + int(_get_spall_rearm_seconds(spall_reload_level) * 1000.0)
	
	# 爆反：最大次数固定为 1（后续如有储备升级可在此扩展）
	var new_era_max = 1 if has_era_block else 0
	if new_era_max > era_block_max_charges:
		var diff = new_era_max - era_block_max_charges
		era_block_charges += diff
	era_block_max_charges = new_era_max
	if not has_era_block:
		era_block_charges = 0
		era_block_max_charges = 0
		_era_rearm_at_msec = 0
	else:
		var rearm_level = current_upgrades.get("era_rearm", {}).get("level", 0)
		if rearm_level > 0 and era_block_charges < era_block_max_charges and _era_rearm_at_msec == 0:
			_era_rearm_at_msec = Time.get_ticks_msec() + int(_get_era_rearm_seconds(rearm_level) * 1000.0)

func _get_nearest_aiming_ranged_enemy(range_m: float) -> Node2D:
	var player = self as Node2D
	var range_px: float = range_m * GlobalFomulaManager.METERS_TO_PIXELS
	var ranged = get_tree().get_nodes_in_group("ranged_enemy")
	var target: Node2D = null
	var best: float = INF
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

# ========== 应急抢修 ==========

func _update_emergency_repair_timer():
	if _emergency_repair_timer == null:
		return
	if emergency_repair_level <= 0:
		if not _emergency_repair_timer.is_stopped():
			_emergency_repair_timer.stop()
		return
	if _emergency_repair_timer.is_stopped():
		_emergency_repair_timer.start()

func _on_emergency_repair_timeout():
	"""应急抢修：耐久低于 30% 时每 5 秒回复 (1 + lv) 点"""
	if emergency_repair_level <= 0:
		return
	var hp_ratio: float = float(health_component.current_health) / float(health_component.max_health)
	if hp_ratio < 0.30:
		health_component.heal(1 + emergency_repair_level)

# ========== 配件控制器映射表 ==========

# { accessory_id: [class_name_type, preload_path] }
const ACCESSORY_CONTROLLER_MAP: Dictionary = {
	"mine": ["MineAbilityController", "res://scenes/ability/mine_ability_controller/mine_ability_controller.tscn"],
	"smoke_grenade": ["SmokeGrenadeAbilityController", "res://scenes/ability/smoke_grenade_ability_controller/smoke_grenade_ability_controller.tscn"],
	"radio_support": ["RadioSupportAbilityController", "res://scenes/ability/radio_support_ability_controller/radio_support_ability_controller.tscn"],
	"laser_suppress": ["LaserSuppressAbilityController", "res://scenes/ability/laser_suppress_ability_controller/laser_suppress_ability_controller.tscn"],
	"external_missile": ["ExternalMissileAbilityController", "res://scenes/ability/external_missile_ability_controller/external_missile_ability_controller.tscn"],
	"decoy_drone": ["DecoyDroneAbilityController", "res://scenes/ability/decoy_drone_ability_controller/decoy_drone_ability_controller.tscn"],
	"auto_turret": ["AutoTurretAbilityController", "res://scenes/ability/auto_turret_ability_controller/auto_turret_ability_controller.tscn"],
	"repair_beacon": ["RepairBeaconAbilityController", "res://scenes/ability/repair_beacon_ability_controller/repair_beacon_ability_controller.tscn"],
	"shield_emitter": ["ShieldEmitterAbilityController", "res://scenes/ability/shield_emitter_ability_controller/shield_emitter_ability_controller.tscn"],
	"emp_pulse": ["EmpPulseAbilityController", "res://scenes/ability/emp_pulse_ability_controller/emp_pulse_ability_controller.tscn"],
	"grav_trap": ["GravTrapAbilityController", "res://scenes/ability/grav_trap_ability_controller/grav_trap_ability_controller.tscn"],
	"thunder_coil": ["ThunderCoilAbilityController", "res://scenes/ability/thunder_coil_ability_controller/thunder_coil_ability_controller.tscn"],
	"cryo_canister": ["CryoCanisterAbilityController", "res://scenes/ability/cryo_canister_ability_controller/cryo_canister_ability_controller.tscn"],
	"incendiary_canister": ["IncendiaryCanisterAbilityController", "res://scenes/ability/incendiary_canister_ability_controller/incendiary_canister_ability_controller.tscn"],
	"acid_sprayer": ["AcidSprayerAbilityController", "res://scenes/ability/acid_sprayer_ability_controller/acid_sprayer_ability_controller.tscn"],
	"orbital_ping": ["OrbitalPingAbilityController", "res://scenes/ability/orbital_ping_ability_controller/orbital_ping_ability_controller.tscn"],
	"med_spray": ["MedSprayAbilityController", "res://scenes/ability/med_spray_ability_controller/med_spray_ability_controller.tscn"],
	"cluster_mine": ["ClusterMineAbilityController", "res://scenes/ability/cluster_mine_ability_controller/cluster_mine_ability_controller.tscn"],
	"chaff_launcher": ["ChaffLauncherAbilityController", "res://scenes/ability/chaff_launcher_ability_controller/chaff_launcher_ability_controller.tscn"],
	"flare_dispenser": ["FlareDispenserAbilityController", "res://scenes/ability/flare_dispenser_ability_controller/flare_dispenser_ability_controller.tscn"],
	"nano_armor": ["NanoArmorAbilityController", "res://scenes/ability/nano_armor_ability_controller/nano_armor_ability_controller.tscn"],
	"fuel_injector_module": ["FuelInjectorModuleAbilityController", "res://scenes/ability/fuel_injector_module_ability_controller/fuel_injector_module_ability_controller.tscn"],
	"adrenaline_stim": ["AdrenalineStimAbilityController", "res://scenes/ability/adrenaline_stim_ability_controller/adrenaline_stim_ability_controller.tscn"],
	"sonar_scanner": ["SonarScannerAbilityController", "res://scenes/ability/sonar_scanner_ability_controller/sonar_scanner_ability_controller.tscn"],
	"ballistic_computer_pod": ["BallisticComputerPodAbilityController", "res://scenes/ability/ballistic_computer_pod_ability_controller/ballistic_computer_pod_ability_controller.tscn"],
	"jammer_field": ["JammerFieldAbilityController", "res://scenes/ability/jammer_field_ability_controller/jammer_field_ability_controller.tscn"],
	"overwatch_uav": ["OverwatchUavAbilityController", "res://scenes/ability/overwatch_uav_ability_controller/overwatch_uav_ability_controller.tscn"],
	"grapeshot_pod": ["GrapeshotPodAbilityController", "res://scenes/ability/grapeshot_pod_ability_controller/grapeshot_pod_ability_controller.tscn"],
	"scrap_collector": ["ScrapCollectorAbilityController", "res://scenes/ability/scrap_collector_ability_controller/scrap_collector_ability_controller.tscn"],
	"kinetic_barrier": ["KineticBarrierAbilityController", "res://scenes/ability/kinetic_barrier_ability_controller/kinetic_barrier_ability_controller.tscn"],
}

# 名称到 class 的映射（GDScript 无法 const 字典存 class，改用 match）
func _has_accessory_controller(accessory_id: String) -> bool:
	"""检查 abilities 子节点中是否已存在该配件的控制器"""
	for child in abilities.get_children():
		match accessory_id:
			"mine":
				if child is MineAbilityController: return true
			"smoke_grenade":
				if child is SmokeGrenadeAbilityController: return true
			"radio_support":
				if child is RadioSupportAbilityController: return true
			"laser_suppress":
				if child is LaserSuppressAbilityController: return true
			"external_missile":
				if child is ExternalMissileAbilityController: return true
			"decoy_drone":
				if child is DecoyDroneAbilityController: return true
			"auto_turret":
				if child is AutoTurretAbilityController: return true
			"repair_beacon":
				if child is RepairBeaconAbilityController: return true
			"shield_emitter":
				if child is ShieldEmitterAbilityController: return true
			"emp_pulse":
				if child is EmpPulseAbilityController: return true
			"grav_trap":
				if child is GravTrapAbilityController: return true
			"thunder_coil":
				if child is ThunderCoilAbilityController: return true
			"cryo_canister":
				if child is CryoCanisterAbilityController: return true
			"incendiary_canister":
				if child is IncendiaryCanisterAbilityController: return true
			"acid_sprayer":
				if child is AcidSprayerAbilityController: return true
			"orbital_ping":
				if child is OrbitalPingAbilityController: return true
			"med_spray":
				if child is MedSprayAbilityController: return true
			"cluster_mine":
				if child is ClusterMineAbilityController: return true
			"chaff_launcher":
				if child is ChaffLauncherAbilityController: return true
			"flare_dispenser":
				if child is FlareDispenserAbilityController: return true
			"nano_armor":
				if child is NanoArmorAbilityController: return true
			"fuel_injector_module":
				if child is FuelInjectorModuleAbilityController: return true
			"adrenaline_stim":
				if child is AdrenalineStimAbilityController: return true
			"sonar_scanner":
				if child is SonarScannerAbilityController: return true
			"ballistic_computer_pod":
				if child is BallisticComputerPodAbilityController: return true
			"jammer_field":
				if child is JammerFieldAbilityController: return true
			"overwatch_uav":
				if child is OverwatchUavAbilityController: return true
			"grapeshot_pod":
				if child is GrapeshotPodAbilityController: return true
			"scrap_collector":
				if child is ScrapCollectorAbilityController: return true
			"kinetic_barrier":
				if child is KineticBarrierAbilityController: return true
	return false

func _instantiate_accessory_controller(accessory_id: String) -> void:
	"""实例化配件控制器并添加到 abilities 节点"""
	if not ACCESSORY_CONTROLLER_MAP.has(accessory_id):
		push_warning("未知配件 ID: %s" % accessory_id)
		return
	var entry = ACCESSORY_CONTROLLER_MAP[accessory_id]
	var scene_path: String = entry[1]
	var controller = load(scene_path).instantiate()
	abilities.add_child(controller)

# ========== 护盾吸收（shield_emitter） ==========

func _get_shield_emitter_controller() -> ShieldEmitterAbilityController:
	"""查找 abilities 下的 ShieldEmitterAbilityController"""
	for child in abilities.get_children():
		if child is ShieldEmitterAbilityController:
			return child as ShieldEmitterAbilityController
	return null

# ========== 对外接口（供 WeaponUpgradeHandler 查询） ==========

func get_target_computer_level() -> int:
	return target_computer_level

func get_mobility_servos_level() -> int:
	return mobility_servos_level

func apply_temporary_speed_bonus(multiplier: float, duration_seconds: float) -> void:
	if multiplier <= 1.0 or duration_seconds <= 0.0:
		return
	_temp_speed_multiplier = max(_temp_speed_multiplier, multiplier)
	_temp_speed_bonus_until_msec = max(
		_temp_speed_bonus_until_msec,
		Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	)
	_apply_health_bonus()

func apply_nano_overcap_shield(amount: float, duration_seconds: float) -> void:
	if amount <= 0.0 or duration_seconds <= 0.0:
		return
	_nano_overcap_shield += amount
	_nano_overcap_until_msec = max(
		_nano_overcap_until_msec,
		Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	)

func apply_kinetic_barrier(reduction: float, duration_seconds: float) -> void:
	if reduction <= 0.0 or duration_seconds <= 0.0:
		return
	_kinetic_barrier_reduction = clamp(reduction, 0.0, 0.95)
	_kinetic_barrier_until_msec = Time.get_ticks_msec() + int(duration_seconds * 1000.0)
