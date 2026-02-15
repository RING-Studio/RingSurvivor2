extends Node
class_name ExternalMissileAbilityController

@export var missile_scene: PackedScene

@export var base_cooldown_seconds: float = 6.0   # 你已确认：6秒
@export var lock_range_m: float = 10.0
@export var explosion_radius_m: float = 3.0

var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["external_missile", "missile_damage", "missile_warhead", "cooling_device", "damage_bonus", "crit_rate", "crit_damage"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("external_missile", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	# cooling_device：仅影响冷却类配件
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var speed_multiplier: float = 1.0 + speed_bonus
	if speed_multiplier <= 0.0:
		return INF
	return max(base / speed_multiplier, 0.3)

func _get_base_damage() -> float:
	var lvl = GameManager.current_upgrades.get("external_missile", {}).get("level", 0)
	return 20.0 + 10.0 * float(max(lvl, 1))

func _update_timer():
	var interval: float = _get_cooldown_seconds()
	if is_inf(interval):
		if _timer and not _timer.is_stopped():
			_timer.stop()
		return
	_timer.wait_time = interval
	if _timer.is_stopped():
		_timer.start()

func _on_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or missile_scene == null:
		return
	
	var lock_px: float = lock_range_m * GlobalFomulaManager.METERS_TO_PIXELS
	var enemies = get_tree().get_nodes_in_group("enemy")
	var target: Node2D = null
	var best: float = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var d2 = e.global_position.distance_squared_to(player.global_position)
		if d2 <= lock_px * lock_px and d2 < best:
			best = d2
			target = e
	if target == null:
		return
	
	var missile = missile_scene.instantiate()
	get_tree().get_first_node_in_group("foreground_layer").add_child(missile)
	missile.global_position = player.global_position
	if missile.has_method("setup"):
		var warhead_lvl = GameManager.current_upgrades.get("missile_warhead", {}).get("level", 0)
		var radius_m = explosion_radius_m + UpgradeEffectManager.get_effect("missile_warhead", warhead_lvl)
		missile.setup(target, _get_base_damage(), radius_m * GlobalFomulaManager.METERS_TO_PIXELS)

