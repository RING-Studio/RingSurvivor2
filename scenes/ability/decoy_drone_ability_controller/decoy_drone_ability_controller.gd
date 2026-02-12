extends Node
class_name DecoyDroneAbilityController

const DecoyDrone = preload("res://scenes/ability/decoy_drone_ability/decoy_drone.gd")

@export var base_cooldown_seconds: float = 30.0

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
	if upgrade_id in ["decoy_drone", "cooling_device"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("decoy_drone", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base := base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus := 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

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
	
	var lvl = GameManager.current_upgrades.get("decoy_drone", {}).get("level", 1)
	var decoy_duration := 5.0 + float(lvl)
	var decoy_health := 20.0 + 10.0 * float(lvl)
	
	var offset = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 50.0)
	var pos = player.global_position + offset
	
	var decoy = DecoyDrone.new()
	decoy.global_position = pos
	decoy.setup(decoy_health, decoy_duration)
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(decoy)
	else:
		get_tree().current_scene.add_child(decoy)
