extends Node
class_name AcidSprayerAbilityController

var _cooldown_timer: Timer
var _spray_active: bool = false
var _spray_remaining: float = 0.0
var _tick_acc: float = 0.0

const BASE_COOLDOWN: float = 12.0
const CONE_RANGE: float = 80.0
const CONE_HALF_ANGLE_DEG: float = 30.0

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()


func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["acid_sprayer", "cooling_device", "acid_armor_break", "acid_spread"]:
		_update_timer()


func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("acid_sprayer", {}).get("level", 0)
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


func _get_spray_duration() -> float:
	var lvl = GameManager.current_upgrades.get("acid_sprayer", {}).get("level", 0)
	return 3.0 + float(max(lvl, 1))


func _get_damage_per_second() -> float:
	var lvl = GameManager.current_upgrades.get("acid_sprayer", {}).get("level", 0)
	return 4.0 + 2.0 * float(max(lvl, 1))

func _get_cone_range() -> float:
	return CONE_RANGE

func _get_cone_half_angle_rad() -> float:
	var bonus_lvl = GameManager.current_upgrades.get("acid_spread", {}).get("level", 0)
	var angle = CONE_HALF_ANGLE_DEG + UpgradeEffectManager.get_effect("acid_spread", bonus_lvl)
	return deg_to_rad(angle)


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
	_spray_active = true
	_spray_remaining = _get_spray_duration()
	_tick_acc = 0.0
	print("[AcidSprayer] Spray activated for %.1fs" % _spray_remaining)


func _process(delta: float):
	if not _spray_active:
		return
	
	_spray_remaining -= delta
	if _spray_remaining <= 0.0:
		_spray_active = false
		return
	
	_tick_acc += delta
	if _tick_acc >= 0.5:
		_tick_acc -= 0.5
		_apply_cone_damage()


func _apply_cone_damage():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var cone_half_angle_rad = _get_cone_half_angle_rad()
	var player_pos = player.global_position
	var forward = player.transform.x.normalized()
	var dmg_per_tick = _get_damage_per_second() * 0.5
	var break_lvl = GameManager.current_upgrades.get("acid_armor_break", {}).get("level", 0)
	if break_lvl > 0:
		dmg_per_tick *= (1.0 + UpgradeEffectManager.get_effect("acid_armor_break", break_lvl))
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var enemy_pos = (e as Node2D).global_position
		var to_enemy = (enemy_pos - player_pos).normalized()
		var dist_sq = player_pos.distance_squared_to(enemy_pos)
		var cone_range = _get_cone_range()
		if dist_sq > cone_range * cone_range:
			continue
		var angle = abs(forward.angle_to(to_enemy))
		if angle > cone_half_angle_rad:
			continue
		var hurtbox = e.get_node_or_null("HurtboxComponent")
		if hurtbox:
			hurtbox.apply_damage(dmg_per_tick, "accessory", false)
