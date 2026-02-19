extends Node2D

var radius: float = 64.0
var color: Color = Color(1.0, 0.2, 0.2, 32.0 / 255.0)
var _blink_timer: float = 0.0
var _visible_phase: bool = true

func setup(p_radius: float, p_color: Color) -> void:
	radius = p_radius
	color = p_color

func _ready():
	queue_redraw()

func _process(delta: float):
	_blink_timer += delta
	if _blink_timer >= 0.3:
		_blink_timer -= 0.3
		_visible_phase = not _visible_phase
		queue_redraw()

func _draw():
	if _visible_phase:
		draw_circle(Vector2.ZERO, radius, color)
		draw_arc(Vector2.ZERO, radius, 0.0, TAU, 64, Color(color.r, color.g, color.b, color.a * 3.0), 2.0)
