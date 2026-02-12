extends Node
class_name ThunderCoilAbilityController

@export var base_cooldown_seconds: float = 8.0
@export var base_radius_m: float = 2.5

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
	if upgrade_id in ["thunder_coil", "cooling_device", "damage_bonus", "crit_damage", "crit_rate"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("thunder_coil", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base := base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var cooling_device_bonus := 0.0
	if cd_lvl > 0:
		cooling_device_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + cooling_device_bonus), 0.5)

func _get_target_count() -> int:
	var lvl = GameManager.current_upgrades.get("thunder_coil", {}).get("level", 0)
	return 3 + max(lvl, 1)

func _get_base_damage() -> float:
	var lvl = GameManager.current_upgrades.get("thunder_coil", {}).get("level", 0)
	return UpgradeEffectManager.get_effect("thunder_coil", max(lvl, 1))

func _get_radius_pixels() -> float:
	return base_radius_m * GlobalFomulaManager.METERS_TO_PIXELS

func _update_timer() -> void:
	var interval := _get_cooldown_seconds()
	if _cooldown_timer == null:
		return
	if is_inf(interval):
		if not _cooldown_timer.is_stopped():
			_cooldown_timer.stop()
		return
	_cooldown_timer.wait_time = interval
	if _cooldown_timer.is_stopped():
		_cooldown_timer.start()

func _on_cooldown() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var center: Vector2 = player.global_position
	var radius_px := _get_radius_pixels()
	var target_count := _get_target_count()
	
	var coil_area := Area2D.new()
	coil_area.collision_layer = 0
	coil_area.collision_mask = 4
	coil_area.global_position = center
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius_px
	shape_node.shape = circle
	coil_area.add_child(shape_node)
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(coil_area)
	else:
		get_tree().current_scene.add_child(coil_area)
	
	await get_tree().physics_frame
	
	var candidates: Array[Node2D] = []
	for area in coil_area.get_overlapping_areas():
		if not area is HurtboxComponent:
			continue
		var enemy = area.get_parent()
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.is_in_group("enemy"):
			continue
		if not candidates.has(enemy):
			candidates.append(enemy)
	
	# Sort by distance, pick up to target_count nearest
	candidates.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(center) < b.global_position.distance_squared_to(center)
	)
	
	var targets: Array[Node2D] = []
	for i in range(mini(target_count, candidates.size())):
		targets.append(candidates[i])
	
	coil_area.queue_free()
	
	var base_dmg := _get_base_damage()
	var dmg: float = base_dmg
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	for target in targets:
		var is_critical = randf() < base_crit_rate
		var applied = dmg
		if is_critical:
			applied *= crit_damage_multiplier
		
		var armor_coverage: float = 0.0
		if target.get("armorCoverage") != null:
			armor_coverage = float(target.get("armorCoverage"))
		elif target.get("armor_coverage") != null:
			armor_coverage = float(target.get("armor_coverage"))
		
		var final_damage = GlobalFomulaManager.calculate_damage(
			applied,
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
			print("ThunderCoil hit ", target.name, " for ", final_damage)
