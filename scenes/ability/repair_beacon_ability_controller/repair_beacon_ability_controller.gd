extends Node
class_name RepairBeaconAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")
const RepairBeaconScene: PackedScene = preload("res://scenes/ability/repair_beacon_ability/repair_beacon.tscn")

@export var base_cooldown_seconds: float = 35.0

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
	if upgrade_id in ["repair_beacon", "cooling_device", "beacon_heal", "beacon_uptime"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("repair_beacon", {}).get("level", 0)
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
	
	var lvl = GameManager.current_upgrades.get("repair_beacon", {}).get("level", 1)
	var beacon_duration: float = 8.0 + 2.0 * float(lvl)
	var uptime_lvl = GameManager.current_upgrades.get("beacon_uptime", {}).get("level", 0)
	if uptime_lvl > 0:
		beacon_duration += UpgradeEffectManager.get_effect("beacon_uptime", uptime_lvl)
	var heal_per_second: float = 1.0 + float(lvl)
	var heal_lvl = GameManager.current_upgrades.get("beacon_heal", {}).get("level", 0)
	if heal_lvl > 0:
		heal_per_second += UpgradeEffectManager.get_effect("beacon_heal", heal_lvl)
	
	var beacon: Node2D = RepairBeaconScene.instantiate()
	beacon.setup(heal_per_second, beacon_duration)
	beacon.global_position = player.global_position
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		layer.add_child(beacon)
		# AOE 视觉效果：绿色 alpha=24，半径60px，持续 beacon_duration
		var fx = AoECircleEffect.new()
		fx.global_position = player.global_position
		fx.setup(60.0, Color(0.2, 0.9, 0.2, 24.0 / 255.0), beacon_duration)
		layer.add_child(fx)
	else:
		get_tree().current_scene.add_child(beacon)
