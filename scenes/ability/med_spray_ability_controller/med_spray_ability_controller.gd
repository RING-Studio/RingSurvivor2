extends Node
class_name MedSprayAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var base_cooldown_seconds: float = 20.0
@export var duration_seconds: float = 5.0
@export var tick_interval_seconds: float = 0.5
@export var base_radius_m: float = 2.0

var _cooldown_timer: Timer
var _tick_timer: Timer
var _heal_active_until_msec: int = 0

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	_tick_timer = Timer.new()
	_tick_timer.one_shot = false
	_tick_timer.autostart = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["med_spray", "cooling_device", "med_tick_rate", "med_radius"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("med_spray", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var cooling_device_bonus: float = 0.0
	if cd_lvl > 0:
		cooling_device_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + cooling_device_bonus), 0.5)

func _get_heal_per_tick() -> int:
	var lvl = GameManager.current_upgrades.get("med_spray", {}).get("level", 0)
	return int(1 + UpgradeEffectManager.get_effect("med_spray", max(lvl, 1)))

func _get_radius_pixels() -> float:
	var bonus_lvl = GameManager.current_upgrades.get("med_radius", {}).get("level", 0)
	var radius_m = base_radius_m + UpgradeEffectManager.get_effect("med_radius", bonus_lvl)
	return radius_m * GlobalFomulaManager.METERS_TO_PIXELS

func _get_tick_interval() -> float:
	var bonus_lvl = GameManager.current_upgrades.get("med_tick_rate", {}).get("level", 0)
	var interval = tick_interval_seconds - UpgradeEffectManager.get_effect("med_tick_rate", bonus_lvl)
	return max(interval, 0.2)

func _update_timer() -> void:
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

func _on_cooldown() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	_heal_active_until_msec = Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	
	# Visual: AoECircleEffect green alpha=32 at player pos, duration=5s
	var radius_px: float = _get_radius_pixels()
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = player.global_position
		fx.setup(radius_px, Color(0.2, 1.0, 0.3, 32.0 / 255.0), duration_seconds)
		layer.add_child(fx)
	
	_tick_timer.wait_time = _get_tick_interval()
	_tick_timer.start()

func _on_tick() -> void:
	if Time.get_ticks_msec() >= _heal_active_until_msec:
		_tick_timer.stop()
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	var hc = player.get_node_or_null("HealthComponent")
	if hc:
		var heal_amount: int = _get_heal_per_tick()
		hc.heal(heal_amount)
