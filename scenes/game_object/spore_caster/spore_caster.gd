extends CharacterBody2D
class_name SporeCaster
## 孢子投手 — 沙漠中被污染的真菌体，会在中距离停下释放具有腐蚀性的孢子弹

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 1.0
@export var armorCoverage: float = 0.1
@export var base_damage: int = 1
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0
@export var is_aiming_player: bool = false  # 瞄准状态（用于激光压制/红外对抗）

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.NORMAL

# 行为参数
const MOVE_SPEED: int = 50
const PREFERRED_DIST: float = 150.0  # 理想射击距离
const STOP_RANGE: float = 30.0  # ±30px 范围内停下射击
const FIRE_INTERVAL: float = 2.5  # 射击间隔
const PROJECTILE_SPEED: float = 120.0
const PROJECTILE_LIFETIME: float = 3.5

var _fire_timer: float = FIRE_INTERVAL
var _is_moving: bool = true  # 内部移动状态
var _aiming_disabled_until_msec: int = 0

var SporeProjectileScene: PackedScene = preload("res://scenes/game_object/spore_caster/spore_projectile.tscn")


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = MOVE_SPEED
	velocity_component.acceleration = 15.0
	add_to_group("ranged_enemy")


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
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D

	# 更新瞄准状态
	if Time.get_ticks_msec() < _aiming_disabled_until_msec:
		is_aiming_player = false
	elif player:
		var dist: float = global_position.distance_to(player.global_position)
		var in_range: bool = abs(dist - PREFERRED_DIST) <= STOP_RANGE
		is_aiming_player = in_range
	else:
		is_aiming_player = false

	if player == null:
		velocity_component.decelerate()
		velocity_component.move(self)
		return

	var dist: float = global_position.distance_to(player.global_position)

	# 距离判定：太远接近，到达射程停下，太近也停下（不后退，群体生物）
	if abs(dist - PREFERRED_DIST) > STOP_RANGE:
		_is_moving = true
		velocity_component.accelerate_to_player()
	else:
		_is_moving = false
		velocity_component.decelerate()

	velocity_component.move(self)

	if _is_moving:
		var move_sign: float = sign(velocity.x)
		if move_sign != 0:
			visuals.scale = Vector2(move_sign, 1)

	# 射击逻辑：在射程内时开火
	if not _is_moving:
		_fire_timer -= delta
		if _fire_timer <= 0:
			_fire_timer = FIRE_INTERVAL
			_fire_projectile(player)


func _fire_projectile(target: Node2D):
	var direction: Vector2 = (target.global_position - global_position).normalized()
	var projectile: Node2D = SporeProjectileScene.instantiate()
	projectile.setup(direction, PROJECTILE_SPEED, float(base_damage), PROJECTILE_LIFETIME)
	projectile.global_position = global_position

	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if entities_layer:
		entities_layer.add_child(projectile)


func disable_aiming(duration_seconds: float) -> void:
	_aiming_disabled_until_msec = max(
		_aiming_disabled_until_msec,
		Time.get_ticks_msec() + int(duration_seconds * 1000.0)
	)


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
