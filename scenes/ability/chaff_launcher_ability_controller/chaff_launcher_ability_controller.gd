extends Node
class_name ChaffLauncherAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var base_cooldown_seconds: float = 22.0
@export var base_radius_m: float = 3.0

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
	if upgrade_id in ["chaff_launcher", "cooling_device", "chaff_density", "chaff_duration"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("chaff_launcher", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

func _get_radius_pixels() -> float:
	var bonus_lvl = GameManager.current_upgrades.get("chaff_density", {}).get("level", 0)
	var radius_m = base_radius_m + UpgradeEffectManager.get_effect("chaff_density", bonus_lvl)
	return radius_m * GlobalFomulaManager.METERS_TO_PIXELS

func _get_duration_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("chaff_launcher", {}).get("level", 0)
	var duration = 2.0 + 0.5 * float(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("chaff_duration", {}).get("level", 0)
	duration += UpgradeEffectManager.get_effect("chaff_duration", bonus_lvl)
	return duration

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
	
	var radius_px: float = _get_radius_pixels()
	var duration: float = _get_duration_seconds()
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = player.global_position
		fx.setup(radius_px, Color(0.6, 0.9, 1.0, 40.0 / 255.0), 0.3)
		layer.add_child(fx)
	
	var area: Area2D = Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 4
	area.global_position = player.global_position
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius_px
	shape_node.shape = circle
	area.add_child(shape_node)
	if layer:
		layer.add_child(area)
	else:
		get_tree().current_scene.add_child(area)
	
	await get_tree().physics_frame
	
	for a in area.get_overlapping_areas():
		if not a is HurtboxComponent:
			continue
		var enemy = a.get_parent()
		if enemy == null or not is_instance_valid(enemy):
			continue
		if not enemy.is_in_group("ranged_enemy"):
			continue
		if enemy.has_method("disable_aiming"):
			enemy.disable_aiming(duration)
		else:
			enemy.set_meta("is_aiming_disabled", true)
			var t = get_tree().create_timer(duration)
			t.timeout.connect(func():
				if is_instance_valid(enemy):
					enemy.set_meta("is_aiming_disabled", false)
			)
	
	area.queue_free()
