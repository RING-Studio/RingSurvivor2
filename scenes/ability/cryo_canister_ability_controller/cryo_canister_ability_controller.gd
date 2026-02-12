extends Node
class_name CryoCanisterAbilityController

var _cooldown_timer: Timer

const BASE_COOLDOWN: float = 18.0
const ZONE_RADIUS_M: float = 2.0
const SLOW_PERCENT: float = 0.5
const SLOW_DURATION: float = 0.6

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()


func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["cryo_canister", "cooling_device"]:
		_update_timer()


func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("cryo_canister", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base := BASE_COOLDOWN
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var cooling_bonus := 0.0
	if cd_lvl > 0:
		cooling_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var speed_multiplier := 1.0 + cooling_bonus
	if speed_multiplier <= 0.0:
		return INF
	return max(base / speed_multiplier, 0.5)


func _get_zone_duration() -> float:
	var lvl = GameManager.current_upgrades.get("cryo_canister", {}).get("level", 0)
	return 4.0 + float(max(lvl, 1))


func _get_zone_radius_px() -> float:
	return ZONE_RADIUS_M * GlobalFomulaManager.METERS_TO_PIXELS


func _update_timer():
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


func _on_cooldown():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var spawn_pos: Vector2
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var best_d2 := INF
	
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
	
	var zone = Node2D.new()
	zone.set_script(preload("res://scenes/ability/cryo_canister_ability/cryo_zone.gd"))
	zone.global_position = spawn_pos
	zone.set_meta("_radius", _get_zone_radius_px())
	zone.set_meta("_duration", _get_zone_duration())
	zone.set_meta("_slow_percent", SLOW_PERCENT)
	zone.set_meta("_slow_duration", SLOW_DURATION)
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(zone)
	else:
		get_tree().current_scene.add_child(zone)
