extends Node
class_name KineticBarrierAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

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
	if upgrade_id in ["kinetic_barrier", "cooling_device", "barrier_angle", "barrier_reflect"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("kinetic_barrier", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

func _get_duration_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("kinetic_barrier", {}).get("level", 0)
	var duration = 3.0 + 0.5 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("barrier_angle", {}).get("level", 0)
	duration += UpgradeEffectManager.get_effect("barrier_angle", bonus_lvl)
	return duration

func _get_reduction() -> float:
	var lvl = GameManager.current_upgrades.get("kinetic_barrier", {}).get("level", 0)
	var reduction = 0.25 + 0.05 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("barrier_reflect", {}).get("level", 0)
	if bonus_lvl > 0:
		reduction += UpgradeEffectManager.get_effect("barrier_reflect", bonus_lvl)
	return clamp(reduction, 0.0, 0.85)

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
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if not player.has_method("apply_kinetic_barrier"):
		return
	
	var duration = _get_duration_seconds()
	var reduction = _get_reduction()
	player.apply_kinetic_barrier(reduction, duration)
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer and player is Node2D:
		var fx = AoECircleEffect.new()
		fx.global_position = (player as Node2D).global_position
		fx.setup(36.0, Color(0.8, 0.9, 1.0, 40.0 / 255.0), 0.4)
		layer.add_child(fx)
