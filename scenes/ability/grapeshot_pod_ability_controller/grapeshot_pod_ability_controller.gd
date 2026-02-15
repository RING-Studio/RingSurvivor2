extends Node
class_name GrapeshotPodAbilityController

@export var base_cooldown_seconds: float = 14.0
@export var base_range_px: float = 120.0
@export var base_cone_half_angle_deg: float = 30.0

var _cooldown_timer: Timer

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["grapeshot_pod", "cooling_device", "grapeshot_pellets", "grapeshot_cone", "damage_bonus", "crit_damage", "crit_rate"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("grapeshot_pod", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

func _get_base_damage() -> float:
	var lvl = GameManager.current_upgrades.get("grapeshot_pod", {}).get("level", 0)
	return 3.0 + 2.0 * float(max(lvl, 1))

func _get_pellet_count() -> int:
	var bonus_lvl = GameManager.current_upgrades.get("grapeshot_pellets", {}).get("level", 0)
	return 6 + int(UpgradeEffectManager.get_effect("grapeshot_pellets", bonus_lvl))

func _get_cone_half_angle_rad() -> float:
	var bonus_lvl = GameManager.current_upgrades.get("grapeshot_cone", {}).get("level", 0)
	var angle_deg = base_cone_half_angle_deg + UpgradeEffectManager.get_effect("grapeshot_cone", bonus_lvl)
	return deg_to_rad(angle_deg)

func _update_timer():
	var interval: float = _get_cooldown_seconds()
	if _cooldown_timer == null:
		return
	if is_inf(interval):
		if not _cooldown_timer.is_stopped():
			_cooldown_timer.stop()
		return
	_cooldown_timer.wait_time = interval
	if _cooldown_timer.is_stopped():
		_cooldown_timer.start()

func _on_cooldown():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return
	
	var cone_half_angle = _get_cone_half_angle_rad()
	var player_pos = player.global_position
	var forward = player.transform.x.normalized()
	var in_cone: Array[Node2D] = []
	
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var enemy_pos = (e as Node2D).global_position
		var dist_sq = player_pos.distance_squared_to(enemy_pos)
		if dist_sq > base_range_px * base_range_px:
			continue
		var to_enemy = (enemy_pos - player_pos).normalized()
		var angle = abs(forward.angle_to(to_enemy))
		if angle > cone_half_angle:
			continue
		in_cone.append(e)
	
	if in_cone.size() == 0:
		return
	
	var pellet_count = _get_pellet_count()
	var base_damage = _get_base_damage()
	var dmg_per_target = base_damage * float(pellet_count) / float(in_cone.size())
	
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	for target in in_cone:
		var dmg: float = dmg_per_target
		if damage_bonus_level > 0:
			dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
		
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
