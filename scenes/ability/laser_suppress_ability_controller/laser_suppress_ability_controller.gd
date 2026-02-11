extends Node
class_name LaserSuppressAbilityController

@export var base_cooldown_seconds: float = 30.0
@export var active_duration_seconds: float = 5.0
@export var range_m: float = 5.0
@export var hits_per_second: float = 5.0

var _cooldown_timer: Timer
var _tick_timer: Timer
var _active_until_msec: int = 0

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.autostart = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_cooldown_timer()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["laser_suppress", "cooling_device", "damage_bonus", "crit_damage", "crit_rate"]:
		_update_cooldown_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("laser_suppress", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base := base_cooldown_seconds
	# cooling_device：仅影响冷却类配件
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus := 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var speed_multiplier := 1.0 + speed_bonus
	if speed_multiplier <= 0.0:
		return INF
	return max(base / speed_multiplier, 0.5)

func _update_cooldown_timer():
	var interval := _get_cooldown_seconds()
	if is_inf(interval):
		if _cooldown_timer and not _cooldown_timer.is_stopped():
			_cooldown_timer.stop()
		return
	_cooldown_timer.wait_time = interval
	if _cooldown_timer.is_stopped():
		_cooldown_timer.start()

func _on_cooldown():
	_active_until_msec = Time.get_ticks_msec() + int(active_duration_seconds * 1000.0)
	_tick_timer.wait_time = max(1.0 / hits_per_second, 0.05)
	_tick_timer.start()

func _on_tick():
	if Time.get_ticks_msec() >= _active_until_msec:
		_tick_timer.stop()
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	# 目标选择口径：锁定“正在瞄准玩家”的远程敌人（WizardEnemy 视为远程敌人并提供 is_aiming_player）
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
	if target == null:
		return
	
	var lvl = GameManager.current_upgrades.get("laser_suppress", {}).get("level", 0)
	var base_damage = 4.0 + 2.0 * float(max(lvl, 1))
	
	# 伤害加成
	var dmg: float = base_damage
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	# 可暴击（来源 accessory）
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	var is_critical = randf() < base_crit_rate
	if is_critical:
		dmg *= crit_damage_multiplier
	
	var armor_coverage: float = 0.0
	if target.get("armorCoverage") != null:
		armor_coverage = float(target.get("armorCoverage"))
	elif target.get("armor_coverage") != null:
		armor_coverage = float(target.get("armor_coverage"))
	
	var final_damage = GlobalFomulaManager.calculate_damage(
		dmg,
		GameManager.get_player_hard_attack_multiplier_percent(),
		GameManager.get_player_soft_attack_multiplier_percent(),
		GameManager.get_player_hard_attack_depth_mm(),
		target.get("armor_thickness") if target.get("armor_thickness") else 0,
		armor_coverage,
		target.get("hardAttackDamageReductionPercent") if target.get("hardAttackDamageReductionPercent") else 0.0
	)
	var hurtbox = target.get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.apply_damage(final_damage, "accessory", is_critical)
