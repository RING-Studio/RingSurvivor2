extends CharacterBody2D
class_name DuneBeetle
## 沙丘甲虫 — 污染变异的大型沙漠甲虫，受到刺激后会高速冲锋

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 2.0
@export var armorCoverage: float = 0.2
@export var base_damage: int = 3
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.NORMAL

# 冲锋状态机
enum State { CHASE, WINDUP, CHARGE, STUNNED }
var _state: int = State.CHASE

# 冲锋参数
const CHASE_SPEED: int = 50
const CHARGE_SPEED: int = 200
const WINDUP_DURATION: float = 0.5
const CHARGE_DURATION: float = 0.8
const STUN_DURATION: float = 1.0
const CHARGE_TRIGGER_DIST: float = 200.0  # px

var _state_timer: float = 0.0
var _charge_direction: Vector2 = Vector2.ZERO
var _original_max_speed: int = CHASE_SPEED
var _is_charging: bool = false  # 用于碰撞伤害倍率判断


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = CHASE_SPEED
	velocity_component.acceleration = 15.0


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
	_state_timer -= delta

	match _state:
		State.CHASE:
			_process_chase(delta)
		State.WINDUP:
			_process_windup(delta)
		State.CHARGE:
			_process_charge(delta)
		State.STUNNED:
			_process_stunned(delta)

	velocity_component.move(self)

	var move_sign: float = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)


func _process_chase(_delta: float):
	_is_charging = false
	velocity_component.max_speed = CHASE_SPEED
	velocity_component.accelerate_to_player()

	# 检测是否到达冲锋距离
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= CHARGE_TRIGGER_DIST:
			_enter_state(State.WINDUP)
			# 锁定方向
			_charge_direction = (player.global_position - global_position).normalized()


func _process_windup(_delta: float):
	velocity_component.decelerate()
	# 视觉提示：闪烁（简单通过 modulate 实现占位）
	visuals.modulate = Color(1, 0.3, 0.3) if fmod(_state_timer * 10, 2.0) > 1.0 else Color(1, 1, 1)

	if _state_timer <= 0:
		_enter_state(State.CHARGE)
		visuals.modulate = Color(1, 1, 1)


func _process_charge(_delta: float):
	_is_charging = true
	velocity_component.max_speed = CHARGE_SPEED
	velocity_component.accelerate_in_direction(_charge_direction)

	if _state_timer <= 0:
		_enter_state(State.STUNNED)
		_is_charging = false


func _process_stunned(_delta: float):
	velocity_component.decelerate()
	# 眩晕视觉：变灰
	visuals.modulate = Color(0.6, 0.6, 0.6)

	if _state_timer <= 0:
		visuals.modulate = Color(1, 1, 1)
		_enter_state(State.CHASE)


func _enter_state(new_state: int):
	_state = new_state
	match new_state:
		State.WINDUP:
			_state_timer = WINDUP_DURATION
		State.CHARGE:
			_state_timer = CHARGE_DURATION
		State.STUNNED:
			_state_timer = STUN_DURATION
		State.CHASE:
			_state_timer = 0.0


func get_contact_damage() -> int:
	if _is_charging:
		return base_damage * 2
	return base_damage


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
