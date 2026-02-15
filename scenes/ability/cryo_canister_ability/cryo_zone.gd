extends Node2D
class_name CryoZone

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

var zone_radius_px: float = 32.0
var zone_duration: float = 4.0
var slow_percent: float = 0.5
var slow_duration: float = 0.6

var _area: Area2D
var _tick_timer: Timer
var _expire_timer: Timer

func _ready():
	# Read params from meta (set by controller before add_child)
	zone_radius_px = get_meta("_radius", zone_radius_px)
	zone_duration = get_meta("_duration", zone_duration)
	slow_percent = get_meta("_slow_percent", slow_percent)
	slow_duration = get_meta("_slow_duration", slow_duration)
	
	# Area2D for HurtboxComponent detection
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 4
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = zone_radius_px
	shape_node.shape = circle
	_area.add_child(shape_node)
	add_child(_area)
	
	# Visual: AoECircleEffect
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(zone_radius_px, Color(0.2, 0.6, 1.0, 32.0 / 255.0), zone_duration)
		layer.add_child(fx)
	
	# Tick every 0.5s
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 0.5
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()
	
	# Expire after duration
	_expire_timer = Timer.new()
	_expire_timer.wait_time = zone_duration
	_expire_timer.one_shot = true
	_expire_timer.timeout.connect(_on_expire)
	add_child(_expire_timer)
	_expire_timer.start()


func _on_tick():
	for area in _area.get_overlapping_areas():
		if not area is HurtboxComponent:
			continue
		var enemy = area.get_parent()
		if enemy == null or not enemy.is_in_group("enemy") or not is_instance_valid(enemy):
			continue
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_percent, slow_duration)
		# else: just note it (no action)


func _on_expire():
	queue_free()
