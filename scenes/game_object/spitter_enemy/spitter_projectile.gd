extends Node2D

# 喷射者弹丸

var _direction: Vector2 = Vector2.RIGHT
var _speed: float = 150.0
var _damage: float = 2.0
var _lifetime: float = 3.0
var _elapsed: float = 0.0
const HIT_RADIUS: float = 8.0


func setup(p_direction: Vector2, p_speed: float, p_damage: float, p_lifetime: float) -> void:
	_direction = p_direction
	_speed = p_speed
	_damage = p_damage
	_lifetime = p_lifetime

func _ready():
	z_index = 3


func _process(delta: float):
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return

	global_position += _direction * _speed * delta

	# 碰撞检测：检查与玩家的距离
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= HIT_RADIUS:
			# 命中玩家
			if player.has_node("HealthComponent"):
				var player_health = player.get_node("HealthComponent")
				player_health.damage(_damage)
			queue_free()
			return

	queue_redraw()


func _draw():
	# 弹丸视觉占位：绿色小圆
	draw_circle(Vector2.ZERO, 4.0, Color(0.2, 0.8, 0.2, 0.8))
