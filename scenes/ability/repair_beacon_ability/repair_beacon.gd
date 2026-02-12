extends Node2D
## 维修信标：在范围内每秒治疗玩家
## 持续一段时间后自动销毁

const HEAL_RADIUS: float = 60.0

var heal_per_second: float = 1.0
var duration: float = 8.0

var _heal_timer: Timer

func setup(p_heal_per_second: float, p_duration: float) -> void:
	heal_per_second = p_heal_per_second
	duration = p_duration

func _ready():
	_heal_timer = Timer.new()
	_heal_timer.one_shot = false
	_heal_timer.wait_time = 1.0
	_heal_timer.timeout.connect(_on_heal_tick)
	add_child(_heal_timer)
	_heal_timer.start()
	
	var duration_timer = Timer.new()
	duration_timer.one_shot = true
	duration_timer.wait_time = duration
	duration_timer.timeout.connect(queue_free)
	add_child(duration_timer)
	duration_timer.start()
	
	queue_redraw()

func _on_heal_tick():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if player.global_position.distance_squared_to(global_position) > HEAL_RADIUS * HEAL_RADIUS:
		return
	var hc = player.get_node_or_null("HealthComponent")
	if hc == null:
		return
	hc.heal(int(heal_per_second))

func _draw():
	draw_circle(Vector2.ZERO, 5.0, Color(0.2, 0.9, 0.2))  # 绿色半径5
