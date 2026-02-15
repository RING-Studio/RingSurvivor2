extends Node2D
class_name Collectible
## 通用收集物实体 — 掉落在场景中，玩家接近后自动拾取
## 拾取后发出 collected 信号，携带 collectible_type 供关卡脚本判定目标进度

signal collected(collectible_type: String)

## 收集物类型标识（如 "energy_core"、"bio_sample"）
@export var collectible_type: String = "energy_core"

## 视觉占位颜色
@export var visual_color: Color = Color(0.2, 0.8, 1.0, 0.9)

## 拾取半径（px）
@export var pickup_radius: float = 30.0

## 磁吸半径（px） — 玩家进入此范围后开始向玩家滑动
@export var magnet_radius: float = 80.0

## 磁吸速度（px/s）
@export var magnet_speed: float = 200.0

## 视觉大小
@export var visual_radius: float = 6.0

## 浮动动画
var _float_offset: float = 0.0

var _collected: bool = false


func _ready() -> void:
	# 随机初始相位
	_float_offset = randf() * TAU
	add_to_group("collectible")


func _process(delta: float) -> void:
	if _collected:
		return

	_float_offset += delta * 3.0

	# 检查玩家距离
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var dist: float = global_position.distance_to(player.global_position)

	# 拾取判定
	if dist <= pickup_radius:
		_do_collect()
		return

	# 磁吸
	if dist <= magnet_radius:
		var dir: Vector2 = (player.global_position - global_position).normalized()
		global_position += dir * magnet_speed * delta


func _draw() -> void:
	# 浮动偏移
	var float_y: float = sin(_float_offset) * 3.0
	# 外圈光晕
	draw_circle(Vector2(0, float_y), visual_radius + 3.0, Color(visual_color.r, visual_color.g, visual_color.b, 0.25))
	# 核心
	draw_circle(Vector2(0, float_y), visual_radius, visual_color)
	# 高光
	draw_circle(Vector2(-1.5, float_y - 1.5), visual_radius * 0.35, Color(1, 1, 1, 0.6))


func _do_collect() -> void:
	if _collected:
		return
	_collected = true
	collected.emit(collectible_type)
	# 全局信号：通知关卡脚本
	GameEvents.emit_collectible_collected(collectible_type)

	# 缩放消失动画
	var tween: Tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.15).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)


## 工厂方法：在指定位置生成收集物
static func spawn_at(pos: Vector2, type: String, color: Color, tree: SceneTree) -> Collectible:
	var c: Collectible = Collectible.new()
	c.collectible_type = type
	c.visual_color = color
	var entities_layer: Node = tree.get_first_node_in_group("entities_layer")
	if entities_layer:
		entities_layer.add_child(c)
	else:
		tree.current_scene.add_child(c)
	c.global_position = pos
	return c
