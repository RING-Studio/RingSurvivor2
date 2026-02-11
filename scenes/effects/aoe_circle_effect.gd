extends Node2D
class_name AoECircleEffect

# MARK（待替换动画）：AOE 占位表现。当前用 alpha=64 的圆形绘制范围提示，
# 后续有动画/粒子资源后可整体替换为更精细的爆炸/烟雾/冲击波表现。
var radius_pixels: float = 16.0
var color: Color = Color(1.0, 0.2, 0.2, 64.0 / 255.0)
var duration_seconds: float = 0.25

func _ready():
	queue_redraw()
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = max(duration_seconds, 0.05)
	t.timeout.connect(queue_free)
	add_child(t)
	t.start()

func setup(radius_px: float, c: Color, duration_s: float = 0.25):
	radius_pixels = max(radius_px, 1.0)
	color = c
	duration_seconds = max(duration_s, 0.05)
	queue_redraw()

func _draw():
	draw_circle(Vector2.ZERO, radius_pixels, color)
