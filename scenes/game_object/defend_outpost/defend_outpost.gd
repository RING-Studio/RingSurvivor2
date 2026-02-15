extends Node2D
class_name DefendOutpost
## 防守据点实体 — 拥有 HP，可被敌人攻击，毁坏时发出 destroyed 信号
## 放置在关卡场景中作为 defend 目标的实际对象

signal destroyed  ## 据点被摧毁
signal health_ratio_changed(ratio: float)  ## 血量比例变化

## 据点最大生命值
@export var max_health: float = 100.0

## 据点当前生命值
var current_health: float = 100.0

## 受伤无敌帧（秒）
var _damage_cooldown: float = 0.0
const DAMAGE_COOLDOWN_TIME: float = 0.5

## 视觉参数
@export var outpost_size: float = 40.0
@export var outpost_color: Color = Color(0.3, 0.7, 0.3, 0.9)

## 敌人检测半径（敌人进入此范围会攻击据点）
@export var aggro_radius: float = 60.0

## 据点 HitArea 碰撞层（用于让敌人武器/碰撞检测到据点）
var _destroyed: bool = false


func _ready() -> void:
	current_health = max_health
	add_to_group("defend_outpost")
	# 据点本体不需要自己做碰撞，由主动检测敌人范围来受伤
	queue_redraw()


func _process(delta: float) -> void:
	if _destroyed:
		return

	if _damage_cooldown > 0:
		_damage_cooldown -= delta

	# 检测范围内的敌人，受到接触伤害
	_check_enemy_contact()

	# 刷新视觉
	queue_redraw()


func _draw() -> void:
	if _destroyed:
		return

	var hp_ratio: float = current_health / max_health if max_health > 0 else 0.0

	# 底座（方形占位）
	var half: float = outpost_size * 0.5
	var rect: Rect2 = Rect2(-half, -half, outpost_size, outpost_size)
	draw_rect(rect, outpost_color)
	# 边框
	draw_rect(rect, Color(0.8, 0.8, 0.8, 0.6), false, 2.0)
	# 十字标记
	draw_line(Vector2(-half * 0.5, 0), Vector2(half * 0.5, 0), Color.WHITE, 2.0)
	draw_line(Vector2(0, -half * 0.5), Vector2(0, half * 0.5), Color.WHITE, 2.0)

	# 血条（据点下方）
	var bar_width: float = outpost_size + 10.0
	var bar_height: float = 5.0
	var bar_y: float = half + 8.0
	# 背景
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, bar_height), Color(0.2, 0.2, 0.2, 0.8))
	# 前景
	var fill_color: Color = Color.GREEN if hp_ratio > 0.5 else (Color.YELLOW if hp_ratio > 0.25 else Color.RED)
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width * hp_ratio, bar_height), fill_color)

	# 攻击范围指示（半透明圈）
	draw_arc(Vector2.ZERO, aggro_radius, 0, TAU, 32, Color(1, 1, 1, 0.08), 1.0)


func take_damage(amount: float) -> void:
	"""据点受伤"""
	if _destroyed or amount <= 0:
		return
	if _damage_cooldown > 0:
		return

	_damage_cooldown = DAMAGE_COOLDOWN_TIME
	current_health = max(current_health - amount, 0)
	var ratio: float = current_health / max_health if max_health > 0 else 0.0
	health_ratio_changed.emit(ratio)

	# 受伤闪烁
	modulate = Color.RED
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

	if current_health <= 0:
		_on_destroyed()


func get_health_ratio() -> float:
	if max_health <= 0:
		return 0.0
	return current_health / max_health


func _on_destroyed() -> void:
	if _destroyed:
		return
	_destroyed = true
	destroyed.emit()

	# 毁坏动画
	var tween: Tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)


func _check_enemy_contact() -> void:
	"""检测范围内的敌人，根据距离受伤"""
	if _damage_cooldown > 0:
		return

	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	for enemy_node in enemies:
		if not is_instance_valid(enemy_node) or not (enemy_node is Node2D):
			continue
		var enemy: Node2D = enemy_node as Node2D
		var dist: float = global_position.distance_to(enemy.global_position)
		if dist <= aggro_radius:
			# 敌人接触据点造成伤害
			var base_dmg: float = 1.0
			if enemy.get("base_damage") != null:
				base_dmg = float(enemy.base_damage)
			take_damage(base_dmg)
			return  # 每次只受一个敌人的伤
