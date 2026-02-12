extends Node2D
## 诱饵无人机实体：可被敌人攻击的诱饵，持续一段时间或生命耗尽后消失
## 无 tscn，通过 .new() 实例化

var hp: float = 20.0
var duration: float = 5.0

func setup(p_hp: float, p_duration: float) -> void:
	hp = p_hp
	duration = p_duration

func _ready():
	add_to_group("decoy")
	add_to_group("enemy_target")
	var t = Timer.new()
	t.one_shot = true
	t.wait_time = duration
	t.timeout.connect(_on_duration_end)
	add_child(t)
	t.start()
	queue_redraw()

func _on_duration_end():
	queue_free()

func take_damage(amount: float) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		queue_free()

func _draw():
	draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.9, 0.2))  # 绿色半径8
