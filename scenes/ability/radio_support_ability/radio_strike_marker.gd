extends Node2D
class_name RadioStrikeMarker

var radius_pixels: float = 64.0
var duration_seconds: float = 10.0

func _ready():
	queue_redraw()
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = max(duration_seconds, 0.1)
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

func setup(radius_px: float, duration_s: float):
	radius_pixels = max(radius_px, 1.0)
	duration_seconds = max(duration_s, 0.1)
	queue_redraw()

func _draw():
	# 占位：半透明红圈提示打击范围
	var c_fill = Color(1.0, 0.2, 0.2, 64.0 / 255.0)
	var c_ring = Color(1.0, 0.2, 0.2, 140.0 / 255.0)
	draw_circle(Vector2.ZERO, radius_pixels, c_fill)
	draw_arc(Vector2.ZERO, radius_pixels, 0.0, TAU, 64, c_ring, 2.0)
