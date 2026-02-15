extends Node2D
## 自主火力塔：检测范围内敌人，按射速对最近敌人造成伤害
## 持续一段时间后自动销毁

const DETECT_RADIUS: float = 150.0

var turret_damage: float = 5.0
var turret_fire_rate: float = 3.0  # 每秒射击次数
var duration: float = 10.0

var _detect_area: Area2D
var _fire_timer: Timer

func setup(p_damage: float, p_fire_rate: float, p_duration: float) -> void:
	turret_damage = p_damage
	turret_fire_rate = p_fire_rate
	duration = p_duration

func _ready():
	# 检测区域
	_detect_area = Area2D.new()
	_detect_area.collision_layer = 0
	_detect_area.collision_mask = 4
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = DETECT_RADIUS
	shape_node.shape = circle
	shape_node.position = Vector2.ZERO
	_detect_area.add_child(shape_node)
	add_child(_detect_area)
	
	_fire_timer = Timer.new()
	_fire_timer.one_shot = false
	_fire_timer.wait_time = 1.0 / turret_fire_rate
	_fire_timer.timeout.connect(_on_fire)
	add_child(_fire_timer)
	_fire_timer.start()
	
	var duration_timer = Timer.new()
	duration_timer.one_shot = true
	duration_timer.wait_time = duration
	duration_timer.timeout.connect(queue_free)
	add_child(duration_timer)
	duration_timer.start()
	
	queue_redraw()

func _on_fire():
	var nearest: Node2D = null
	var nearest_dist_sq: float = INF
	
	for area in _detect_area.get_overlapping_areas():
		if not area is HurtboxComponent:
			continue
		var enemy = area.get_parent()
		if enemy == null or not enemy.is_in_group("enemy") or not is_instance_valid(enemy):
			continue
		var d_sq = global_position.distance_squared_to(enemy.global_position)
		if d_sq < nearest_dist_sq:
			nearest_dist_sq = d_sq
			nearest = enemy
	
	if nearest == null:
		return
	
	var hurtbox = nearest.get_node_or_null("HurtboxComponent")
	if hurtbox == null:
		return
	
	# 伤害加成与暴击
	var dmg: float = turret_damage
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	var base_crit_rate = GameManager.get_global_crit_rate()
	var is_critical = randf() < base_crit_rate
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	if is_critical:
		dmg *= crit_damage_multiplier
	
	hurtbox.apply_damage(dmg, "accessory", is_critical)

func _draw():
	draw_circle(Vector2.ZERO, 6.0, Color(1.0, 0.5, 0.0))  # 橙色半径6
