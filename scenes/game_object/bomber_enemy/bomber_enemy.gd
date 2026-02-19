extends CharacterBody2D
class_name BloatTick
## 膨爆蜱 — 被污染胀大的沙漠蜱虫，体内充满腐蚀性液体，接近目标后自爆

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 0.0
@export var armorCoverage: float = 0.0
@export var base_damage: int = 5
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.NORMAL

# 自爆参数
const EXPLODE_TRIGGER_DIST: float = 30.0  # 接近玩家此距离时触发自爆
const EXPLODE_RADIUS: float = 60.0
const EXPLODE_DELAY: float = 0.3
const DEATH_EXPLOSION_DAMAGE_MULT: float = 0.5  # 被击杀时爆炸伤害倍率

var _exploding: bool = false
var _explode_timer: float = 0.0
var _has_exploded: bool = false


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = 80
	velocity_component.acceleration = 30.0

	# 连接死亡信号 — 被击杀也会爆炸
	health_component.died.connect(_on_died)


func initialize_enemy(properties: Dictionary = {}):
	if not is_node_ready():
		await ready
	if properties.has("max_health"):
		health_component.max_health = properties["max_health"]
		if properties.has("current_health"):
			health_component.current_health = properties["current_health"]
		else:
			health_component.current_health = health_component.max_health
	if properties.has("armor_thickness"):
		armor_thickness = properties["armor_thickness"]
	if properties.has("armor_coverage"):
		armorCoverage = properties["armor_coverage"]
	if properties.has("base_damage"):
		base_damage = properties["base_damage"]
	if properties.has("base_damage_modifier_ratio"):
		base_damage_modifier_ratio = properties["base_damage_modifier_ratio"]
	if properties.has("soft_attack_multiplier_percent"):
		soft_attack_multiplier_percent = properties["soft_attack_multiplier_percent"]
	if properties.has("hard_attack_multiplier_percent"):
		hardAttackMultiplierPercent = properties["hard_attack_multiplier_percent"]
	if properties.has("hard_attack_depth_mm"):
		hard_attack_depth_mm = properties["hard_attack_depth_mm"]


func _process(delta: float):
	if _has_exploded:
		return

	if _exploding:
		_explode_timer -= delta
		# 闪烁警告
		visuals.modulate = Color(1, 0.2, 0.2) if fmod(_explode_timer * 20, 2.0) > 1.0 else Color(1, 1, 0)
		if _explode_timer <= 0:
			_do_explode(1.0)
		return

	# 正常移动
	velocity_component.accelerate_to_player()
	velocity_component.move(self)

	var move_sign: float = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)

	# 检查是否到达自爆距离
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= EXPLODE_TRIGGER_DIST:
			_start_explode()


func _start_explode():
	if _exploding:
		return
	_exploding = true
	_explode_timer = EXPLODE_DELAY
	velocity_component.decelerate()


func _do_explode(damage_mult: float):
	if _has_exploded:
		return
	_has_exploded = true

	var explosion_damage: float = float(base_damage) * damage_mult

	# 对范围内玩家造成伤害
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= EXPLODE_RADIUS:
			# 通过 HealthComponent 对玩家造成伤害
			if player.has_node("HealthComponent"):
				var player_health: Node = player.get_node("HealthComponent")
				player_health.damage(explosion_damage)

	# 视觉占位：画一个红色扩散圆
	_play_explosion_effect()

	# 自杀（如果还活着）
	if health_component.current_health > 0:
		health_component.damage(health_component.current_health + 1)
	else:
		# 已经死亡触发的，直接清理
		queue_free()


func _on_died():
	# 被击杀时触发较弱的爆炸
	if not _has_exploded:
		_do_explode(DEATH_EXPLOSION_DAMAGE_MULT)


func _play_explosion_effect():
	"""爆炸视觉占位：红色扩散圆"""
	var ExplosionScene: PackedScene = load("res://scenes/game_object/bomber_enemy/bomber_explosion_effect.tscn")
	var effect: Node2D = ExplosionScene.instantiate()
	effect.setup(EXPLODE_RADIUS)
	effect.global_position = global_position
	var layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if layer:
		layer.add_child(effect)


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
