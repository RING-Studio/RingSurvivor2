extends Node
class_name GravTrapAbilityController

var _cooldown_timer: Timer

const BASE_COOLDOWN: float = 22.0
const TRAP_RADIUS_M: float = 2.0
const PULL_FORCE: float = 80.0

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()


func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["grav_trap", "cooling_device"]:
		_update_timer()


func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("grav_trap", {}).get("level", 0)
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


func _get_trap_duration() -> float:
	var lvl = GameManager.current_upgrades.get("grav_trap", {}).get("level", 0)
	return 3.0 + float(max(lvl, 1))


func _get_trap_radius_px() -> float:
	return TRAP_RADIUS_M * GlobalFomulaManager.METERS_TO_PIXELS


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
	
	var offset = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 80.0)
	var spawn_pos = player.global_position + offset
	
	var trap = Node2D.new()
	trap.set_script(preload("res://scenes/ability/grav_trap_ability/grav_trap.gd"))
	trap.global_position = spawn_pos
	trap.set_meta("_radius", _get_trap_radius_px())
	trap.set_meta("_duration", _get_trap_duration())
	trap.set_meta("_pull_force", PULL_FORCE)
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(trap)
	else:
		get_tree().current_scene.add_child(trap)
