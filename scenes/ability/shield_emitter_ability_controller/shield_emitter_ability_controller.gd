extends Node
class_name ShieldEmitterAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var base_cooldown_seconds: float = 45.0
@export var shield_duration_seconds: float = 8.0

var _cooldown_timer: Timer
var shield_remaining: float = 0.0
var _shield_expires_at_msec: int = 0
var _shield_visual: Node2D = null
var _shield_capacity_max: float = 0.0
var _regen_accumulator: float = 0.0

class ShieldCircleVisual extends Node2D:
	var radius: float = 24.0
	var draw_color: Color = Color(0.2, 0.4, 1.0, 32.0 / 255.0)
	func _draw():
		draw_circle(Vector2.ZERO, radius, draw_color)

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()

func _process(delta: float) -> void:
	if Time.get_ticks_msec() >= _shield_expires_at_msec:
		shield_remaining = 0
	if shield_remaining <= 0:
		if _shield_visual:
			_shield_visual.visible = false
		return
	
	var regen_rate = _get_regen_per_second()
	if regen_rate > 0.0 and _shield_capacity_max > 0.0:
		_regen_accumulator += delta
		if _regen_accumulator >= 0.2:
			var ticks = int(_regen_accumulator / 0.2)
			_regen_accumulator -= float(ticks) * 0.2
			shield_remaining = min(_shield_capacity_max, shield_remaining + regen_rate * 0.2 * float(ticks))
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player and _shield_visual:
		_shield_visual.global_position = player.global_position
		_shield_visual.visible = true
		_shield_visual.queue_redraw()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["shield_emitter", "cooling_device", "shield_capacity", "shield_regen"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("shield_emitter", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var cooling_device_bonus: float = 0.0
	if cd_lvl > 0:
		cooling_device_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + cooling_device_bonus), 0.5)

func _get_shield_capacity() -> float:
	var lvl = GameManager.current_upgrades.get("shield_emitter", {}).get("level", 0)
	var capacity = UpgradeEffectManager.get_effect("shield_emitter", max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("shield_capacity", {}).get("level", 0)
	if bonus_lvl > 0:
		capacity += UpgradeEffectManager.get_effect("shield_capacity", bonus_lvl)
	return capacity

func _get_regen_per_second() -> float:
	var regen_lvl = GameManager.current_upgrades.get("shield_regen", {}).get("level", 0)
	if regen_lvl <= 0:
		return 0.0
	return UpgradeEffectManager.get_effect("shield_regen", regen_lvl)

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
	
	var capacity: float = _get_shield_capacity()
	shield_remaining = capacity
	_shield_capacity_max = capacity
	_regen_accumulator = 0.0
	_shield_expires_at_msec = Time.get_ticks_msec() + int(shield_duration_seconds * 1000.0)
	
	# Create or show shield visual
	if _shield_visual == null:
		_shield_visual = ShieldCircleVisual.new()
		_shield_visual.radius = 1.5 * GlobalFomulaManager.METERS_TO_PIXELS
		var layer = get_tree().get_first_node_in_group("foreground_layer")
		if layer:
			layer.add_child(_shield_visual)
		else:
			get_tree().current_scene.add_child(_shield_visual)
	_shield_visual.visible = true

func absorb_damage(amount: float) -> float:
	"""Absorb damage with shield. Returns remaining damage that passes through."""
	if shield_remaining <= 0:
		return amount
	var absorbed: float = minf(shield_remaining, amount)
	shield_remaining -= absorbed
	return amount - absorbed
