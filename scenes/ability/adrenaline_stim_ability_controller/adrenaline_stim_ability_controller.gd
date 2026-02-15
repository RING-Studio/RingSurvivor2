extends Node
class_name AdrenalineStimAbilityController

@export var check_interval_seconds: float = 0.5

var _check_timer: Timer
var _cooldown_until_msec: int = 0

func _ready():
	_check_timer = Timer.new()
	_check_timer.one_shot = false
	_check_timer.autostart = true
	_check_timer.wait_time = check_interval_seconds
	_check_timer.timeout.connect(_on_check)
	add_child(_check_timer)

func _get_trigger_threshold() -> float:
	var lvl = GameManager.current_upgrades.get("adrenaline_stim", {}).get("level", 0)
	if lvl <= 0:
		return 0.0
	var threshold = 0.30 + 0.02 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("stim_trigger_hp", {}).get("level", 0)
	if bonus_lvl > 0:
		threshold += UpgradeEffectManager.get_effect("stim_trigger_hp", bonus_lvl)
	return clamp(threshold, 0.1, 0.9)

func _get_duration_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("adrenaline_stim", {}).get("level", 0)
	var duration = 3.0 + 0.5 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("stim_duration", {}).get("level", 0)
	if bonus_lvl > 0:
		duration += UpgradeEffectManager.get_effect("stim_duration", bonus_lvl)
	return duration

func _get_speed_bonus() -> float:
	var lvl = GameManager.current_upgrades.get("adrenaline_stim", {}).get("level", 0)
	return 0.25 + 0.05 * float(max(lvl, 1))

func _get_fire_rate_bonus() -> float:
	var lvl = GameManager.current_upgrades.get("adrenaline_stim", {}).get("level", 0)
	return 0.20 + 0.04 * float(max(lvl, 1))

func _on_check():
	var lvl = GameManager.current_upgrades.get("adrenaline_stim", {}).get("level", 0)
	if lvl <= 0:
		return
	if Time.get_ticks_msec() < _cooldown_until_msec:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var hc = player.get_node_or_null("HealthComponent")
	if hc == null or hc.max_health <= 0:
		return
	
	var hp_ratio = float(hc.current_health) / float(hc.max_health)
	if hp_ratio > _get_trigger_threshold():
		return
	
	var duration = _get_duration_seconds()
	var speed_bonus = _get_speed_bonus()
	var fire_rate_bonus = _get_fire_rate_bonus()
	
	if player.has_method("apply_temporary_speed_bonus"):
		player.apply_temporary_speed_bonus(1.0 + speed_bonus, duration)
	if WeaponUpgradeHandler.instance:
		WeaponUpgradeHandler.instance.apply_temporary_fire_rate_bonus(fire_rate_bonus, duration)
	
	_cooldown_until_msec = Time.get_ticks_msec() + int((duration + 5.0) * 1000.0)
