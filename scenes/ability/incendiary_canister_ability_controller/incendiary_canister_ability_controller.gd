extends Node
class_name IncendiaryCanisterAbilityController

var _cooldown_timer: Timer

const BASE_COOLDOWN: float = 15.0
const ZONE_RADIUS_M: float = 1.5

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()


func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["incendiary_canister", "cooling_device", "fire_duration", "fire_damage"]:
		_update_timer()


func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("incendiary_canister", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = BASE_COOLDOWN
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var cooling_bonus: float = 0.0
	if cd_lvl > 0:
		cooling_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var speed_multiplier: float = 1.0 + cooling_bonus
	if speed_multiplier <= 0.0:
		return INF
	return max(base / speed_multiplier, 0.5)


func _get_zone_duration() -> float:
	var lvl = GameManager.current_upgrades.get("incendiary_canister", {}).get("level", 0)
	var duration = 5.0 + float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("fire_duration", {}).get("level", 0)
	if bonus_lvl > 0:
		duration += UpgradeEffectManager.get_effect("fire_duration", bonus_lvl)
	return duration


func _get_zone_radius_px() -> float:
	return ZONE_RADIUS_M * GlobalFomulaManager.METERS_TO_PIXELS


func _get_damage_per_second() -> float:
	var lvl = GameManager.current_upgrades.get("incendiary_canister", {}).get("level", 0)
	var dmg = 3.0 + 2.0 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("fire_damage", {}).get("level", 0)
	if bonus_lvl > 0:
		dmg += UpgradeEffectManager.get_effect("fire_damage", bonus_lvl)
	return dmg


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
	
	var spawn_pos: Vector2
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
	
	if nearest != null:
		var dir = (nearest.global_position - player.global_position).normalized()
		spawn_pos = player.global_position + dir * 100.0
	else:
		spawn_pos = player.global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 100.0)
	
	var FireZoneScene: PackedScene = load("res://scenes/ability/incendiary_canister_ability/fire_zone.tscn")
	var zone: Node2D = FireZoneScene.instantiate()
	zone.setup(_get_zone_radius_px(), _get_zone_duration(), _get_damage_per_second() * 0.5)
	zone.global_position = spawn_pos
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(zone)
	else:
		get_tree().current_scene.add_child(zone)
