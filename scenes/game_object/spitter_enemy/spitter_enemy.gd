extends CharacterBody2D
class_name AcidSpitter
## 酸液射手 — 沙漠中的变异蜥蜴，能从口腔喷射腐蚀性酸液，保持距离作战

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 3.0
@export var armorCoverage: float = 0.3
@export var base_damage: int = 2
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0
@export var is_aiming_player: bool = false

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.NORMAL

# 行为参数
const PREFERRED_DIST: float = 200.0  # 理想射击距离
const MIN_DIST: float = 100.0  # 低于此距离后退
const MAX_DIST: float = 250.0  # 高于此距离接近
const FIRE_INTERVAL: float = 2.0  # 射击间隔
const PROJECTILE_SPEED: float = 150.0  # 弹丸速度
const PROJECTILE_LIFETIME: float = 3.0  # 弹丸存活时间

enum State { APPROACH, ATTACK, RETREAT }
var _state: int = State.APPROACH
var _fire_timer: float = FIRE_INTERVAL

var SpitterProjectileScript: GDScript = preload("res://scenes/game_object/spitter_enemy/spitter_projectile.gd")


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = 55
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
	if player == null:
		velocity_component.decelerate()
		velocity_component.move(self)
		return

	var dist: float = global_position.distance_to(player.global_position)

	# 更新瞄准状态
	is_aiming_player = dist <= MAX_DIST and dist >= MIN_DIST

	# 决定行为状态
	if dist > MAX_DIST:
		_state = State.APPROACH
	elif dist < MIN_DIST:
		_state = State.RETREAT
	else:
		_state = State.ATTACK

	match _state:
		State.APPROACH:
			velocity_component.accelerate_to_player()
		State.RETREAT:
			var away_dir: Vector2 = (global_position - player.global_position).normalized()
			velocity_component.accelerate_in_direction(away_dir)
		State.ATTACK:
			velocity_component.decelerate()

	velocity_component.move(self)

	var move_sign: float = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(move_sign, 1)

	# 射击逻辑
	if _state == State.ATTACK or (_state == State.RETREAT and dist <= MAX_DIST):
		_fire_timer -= delta
		if _fire_timer <= 0:
			_fire_timer = FIRE_INTERVAL
			_fire_projectile(player)


func _fire_projectile(target: Node2D):
	var direction: Vector2 = (target.global_position - global_position).normalized()
	var projectile: Node2D = Node2D.new()
	projectile.set_script(SpitterProjectileScript)
	projectile.global_position = global_position
	projectile.set_meta("direction", direction)
	projectile.set_meta("speed", PROJECTILE_SPEED)
	projectile.set_meta("damage", float(base_damage))
	projectile.set_meta("lifetime", PROJECTILE_LIFETIME)

	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if entities_layer:
		entities_layer.add_child(projectile)


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
