extends Area2D
class_name SmokeCloud

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var radius_pixels: float = 16.0
var slow_ratio: float = 0.2  # 0~1，表示“最大移速降低比例”
var duration_seconds: float = 3.0

var _original_speeds: Dictionary = {}  # enemy -> int
var _expire_timer: Timer

func _ready():
	# 设置碰撞半径
	if collision_shape and collision_shape.shape is CircleShape2D:
		collision_shape.shape.radius = radius_pixels
	queue_redraw()
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
	# 处理初始重叠（防止生成时已经在烟雾中但未触发 entered）
	for b in get_overlapping_bodies():
		_on_body_entered(b)
	
	_expire_timer = Timer.new()
	_expire_timer.one_shot = true
	_expire_timer.wait_time = max(duration_seconds, 0.1)
	_expire_timer.timeout.connect(_on_expire)
	add_child(_expire_timer)
	_expire_timer.start()

func setup(radius_px: float, slow: float, duration_s: float):
	radius_pixels = max(radius_px, 1.0)
	slow_ratio = clamp(slow, 0.0, 0.95)
	duration_seconds = max(duration_s, 0.1)
	if is_node_ready():
		if collision_shape and collision_shape.shape is CircleShape2D:
			collision_shape.shape.radius = radius_pixels
		queue_redraw()
		if _expire_timer:
			_expire_timer.wait_time = duration_seconds
			_expire_timer.start()

func _draw():
	# 视觉占位：alpha=64 的圆
	var c = Color(0.5, 0.5, 0.5, 64.0 / 255.0)  # 灰色
	draw_circle(Vector2.ZERO, radius_pixels, c)

func _on_body_entered(body: Node):
	if body == null or not (body is Node2D):
		return
	if not body.is_in_group("enemy"):
		return
	if _original_speeds.has(body):
		return
	
	var vc = body.get_node_or_null("VelocityComponent")
	if vc == null:
		return
	
	var original = int(vc.max_speed)
	_original_speeds[body] = original
	vc.max_speed = int(round(float(original) * (1.0 - slow_ratio)))

func _on_body_exited(body: Node):
	if not _original_speeds.has(body):
		return
	var original = int(_original_speeds[body])
	_original_speeds.erase(body)
	if body != null and is_instance_valid(body):
		var vc = body.get_node_or_null("VelocityComponent")
		if vc != null:
			vc.max_speed = original

func _on_expire():
	# 还原所有受影响敌人的速度
	for enemy in _original_speeds.keys():
		var original = int(_original_speeds[enemy])
		if enemy != null and is_instance_valid(enemy):
			var vc = enemy.get_node_or_null("VelocityComponent")
			if vc != null:
				vc.max_speed = original
	_original_speeds.clear()
	queue_free()
