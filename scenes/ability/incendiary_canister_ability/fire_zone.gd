extends Node2D
class_name FireZone

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

var zone_radius_px: float = 24.0
var zone_duration: float = 5.0
var damage_per_half_second: float = 2.5  # damage_per_second * 0.5

var _area: Area2D
var _tick_timer: Timer
var _expire_timer: Timer

func setup(p_radius: float, p_duration: float, p_dmg_per_tick: float) -> void:
	zone_radius_px = p_radius
	zone_duration = p_duration
	damage_per_half_second = p_dmg_per_tick

func _ready():
	
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 4
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = zone_radius_px
	shape_node.shape = circle
	_area.add_child(shape_node)
	add_child(_area)
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(zone_radius_px, Color(1.0, 0.5, 0.1, 32.0 / 255.0), zone_duration)
		layer.add_child(fx)
	
	_tick_timer = Timer.new()
	_tick_timer.wait_time = 0.5
	_tick_timer.one_shot = false
	_tick_timer.timeout.connect(_on_tick)
	add_child(_tick_timer)
	_tick_timer.start()
	
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
		var hurtbox = area as HurtboxComponent
		hurtbox.apply_damage(damage_per_half_second, "accessory", false)


func _on_expire():
	queue_free()
