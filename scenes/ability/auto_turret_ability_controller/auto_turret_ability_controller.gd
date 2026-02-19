extends Node
class_name AutoTurretAbilityController

const AutoTurretScene: PackedScene = preload("res://scenes/ability/auto_turret_ability/auto_turret.tscn")

@export var base_cooldown_seconds: float = 40.0

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
	if upgrade_id in ["auto_turret", "cooling_device", "turret_rate", "turret_pierce"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("auto_turret", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

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
	
	var lvl = GameManager.current_upgrades.get("auto_turret", {}).get("level", 1)
	var turret_duration: float = 10.0 + 2.0 * float(lvl)
	var turret_damage: float = 5.0 + 3.0 * float(lvl)
	var pierce_lvl = GameManager.current_upgrades.get("turret_pierce", {}).get("level", 0)
	if pierce_lvl > 0:
		turret_damage *= (1.0 + UpgradeEffectManager.get_effect("turret_pierce", pierce_lvl))
	var turret_fire_rate: float = 3.0
	var rate_lvl = GameManager.current_upgrades.get("turret_rate", {}).get("level", 0)
	if rate_lvl > 0:
		turret_fire_rate += UpgradeEffectManager.get_effect("turret_rate", rate_lvl)
	
	var turret: Node2D = AutoTurretScene.instantiate()
	turret.setup(turret_damage, turret_fire_rate, turret_duration)
	turret.global_position = player.global_position
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(turret)
	else:
		get_tree().current_scene.add_child(turret)
