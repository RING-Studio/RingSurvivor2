extends Node2D
## 孢子弹 — SporeCaster 发射的孢子投射物，命中玩家造成伤害

var _direction: Vector2 = Vector2.ZERO
var _speed: float = 120.0
var _damage: float = 1.0
var _lifetime: float = 3.5
var _elapsed: float = 0.0
var _radius: float = 6.0  # 比酸液弹稍大


func setup(p_direction: Vector2, p_speed: float, p_damage: float, p_lifetime: float) -> void:
	_direction = p_direction
	_speed = p_speed
	_damage = p_damage
	_lifetime = p_lifetime

func _ready():
	pass


func _process(delta: float):
	_elapsed += delta
	if _elapsed >= _lifetime:
		queue_free()
		return

	position += _direction * _speed * delta

	# 碰撞检测：与玩家的简单距离检测
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= 15.0:
			if player.has_node("HealthComponent"):
				var hc: Node = player.get_node("HealthComponent")
				hc.damage(_damage)
			queue_free()
			return

	queue_redraw()


func _draw():
	# 占位视觉：紫色圆点（孢子）
	draw_circle(Vector2.ZERO, _radius, Color(0.6, 0.2, 0.8, 0.8))
