extends Node2D
class_name GravTrap

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

var trap_radius_px: float = 32.0
var trap_duration: float = 3.0
var pull_force: float = 80.0  # px/sec

var _area: Area2D
var _expire_timer: Timer

func setup(p_radius: float, p_duration: float, p_pull_force: float) -> void:
	trap_radius_px = p_radius
	trap_duration = p_duration
	pull_force = p_pull_force

func _ready():
	
	_area = Area2D.new()
	_area.collision_layer = 0
	_area.collision_mask = 4
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = trap_radius_px
	shape_node.shape = circle
	_area.add_child(shape_node)
	add_child(_area)
	
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(trap_radius_px, Color(0.6, 0.2, 1.0, 32.0 / 255.0), trap_duration)
		layer.add_child(fx)
	
	_expire_timer = Timer.new()
	_expire_timer.wait_time = trap_duration
	_expire_timer.one_shot = true
	_expire_timer.timeout.connect(_on_expire)
	add_child(_expire_timer)
	_expire_timer.start()


func _process(delta: float):
	var center = global_position
	for area in _area.get_overlapping_areas():
		if not area is HurtboxComponent:
			continue
		var enemy = area.get_parent()
		if enemy == null or not enemy.is_in_group("enemy") or not is_instance_valid(enemy):
			continue
		if not enemy is Node2D:
			continue
		var enemy_pos = (enemy as Node2D).global_position
		var to_center = center - enemy_pos
		var dist = to_center.length()
		if dist > 0.1:
			var move_dist = min(pull_force * delta, dist)
			(enemy as Node2D).global_position += to_center.normalized() * move_dist


func _on_expire():
	queue_free()
