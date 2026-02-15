extends Node2D

# 自爆者爆炸视觉占位效果

var _radius: float = 60.0
var _alpha: float = 0.6
var _lifetime: float = 0.5
var _elapsed: float = 0.0


func _ready():
	if has_meta("radius"):
		_radius = get_meta("radius")
	z_index = 5


func _process(delta: float):
	_elapsed += delta
	_alpha = lerpf(0.6, 0.0, _elapsed / _lifetime)
	queue_redraw()
	if _elapsed >= _lifetime:
		queue_free()


func _draw():
	var progress: float = _elapsed / _lifetime
	var current_radius: float = _radius * (0.5 + 0.5 * progress)
	draw_circle(Vector2.ZERO, current_radius, Color(1, 0.3, 0, _alpha))
