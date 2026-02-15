extends Node
class_name OverwatchUavAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var base_cooldown_seconds: float = 25.0
@export var base_radius_m: float = 1.5

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
	_update_timer()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["overwatch_uav", "cooling_device", "uav_bomb_rate", "uav_laser_tag"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("overwatch_uav", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

func _get_duration_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("overwatch_uav", {}).get("level", 0)
	return 6.0 + float(max(lvl, 1))

func _get_damage() -> float:
	var lvl = GameManager.current_upgrades.get("overwatch_uav", {}).get("level", 0)
	var base = 5.0 + 3.0 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("uav_laser_tag", {}).get("level", 0)
	if bonus_lvl > 0:
		base *= (1.0 + UpgradeEffectManager.get_effect("uav_laser_tag", bonus_lvl))
	return base

func _get_tick_interval() -> float:
	var base = 1.0
	var rate_lvl = GameManager.current_upgrades.get("uav_bomb_rate", {}).get("level", 0)
	if rate_lvl > 0:
		base -= UpgradeEffectManager.get_effect("uav_bomb_rate", rate_lvl)
	return clamp(base, 0.3, 2.0)

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
	_active_until_msec = Time.get_ticks_msec() + int(_get_duration_seconds() * 1000.0)
	_tick_timer.wait_time = _get_tick_interval()
	_tick_timer.start()

func _on_tick():
	if Time.get_ticks_msec() >= _active_until_msec:
		_tick_timer.stop()
		return
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var best_d2: float = INF
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var d2 = e.global_position.distance_squared_to(player.global_position)
		if d2 < best_d2:
			best_d2 = d2
			nearest = e
	if nearest == null:
		return
	
	_apply_bomb(nearest.global_position)

func _apply_bomb(center: Vector2) -> void:
	var radius_px = base_radius_m * GlobalFomulaManager.METERS_TO_PIXELS
	var base_damage = _get_damage()
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = center
		fx.setup(radius_px, Color(1.0, 0.5, 0.2, 64.0 / 255.0), 0.2)
		layer.add_child(fx)
	
	var strike_area: Area2D = Area2D.new()
	strike_area.collision_layer = 0
	strike_area.collision_mask = 4
	strike_area.global_position = center
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius_px
	shape_node.shape = circle
	strike_area.add_child(shape_node)
	if layer:
		layer.add_child(strike_area)
	else:
		get_tree().current_scene.add_child(strike_area)
	
	await get_tree().physics_frame
	
	var enemies: Array[Node2D] = []
	for area in strike_area.get_overlapping_areas():
		if area is HurtboxComponent:
			var enemy = area.get_parent()
			if enemy and enemy.is_in_group("enemy") and is_instance_valid(enemy):
				if not enemies.has(enemy):
					enemies.append(enemy)
	
	strike_area.queue_free()
	
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	for enemy in enemies:
		var dmg: float = base_damage
		if damage_bonus_level > 0:
			dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
		
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
