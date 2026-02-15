extends CharacterBody2D
class_name BossHive
## 孵化母体 — 深层污染区的巢穴核心，能持续孵化污染生物增援

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 4.0
@export var armorCoverage: float = 0.4
@export var base_damage: int = 2
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.BOSS

# 行为参数
const PREFERRED_DIST: float = 200.0  # 保持与玩家的距离
const RETREAT_DIST: float = 120.0  # 低于此距离后退
const MOVE_SPEED: int = 40

# 召唤参数
const SUMMON_INTERVAL: float = 8.0  # 每 8 秒召唤一波
const SUMMON_COUNT_MIN: int = 3
const SUMMON_COUNT_MAX: int = 5
const MAX_SUMMONS: int = 15  # 同时存在的召唤物上限
const DAMAGE_SUMMON_THRESHOLD: float = 50.0  # 单次受伤超过此值立即召唤

var _summon_timer: float = SUMMON_INTERVAL
var _active_summons: Array[Node2D] = []
var _last_health: float = 0.0

var SandScarabScene: PackedScene = preload("res://scenes/game_object/sand_scarab/sand_scarab.tscn")


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = MOVE_SPEED
	velocity_component.acceleration = 12.0
	_last_health = health_component.max_health

	# 监听自身受伤以触发应急召唤
	health_component.health_changed.connect(_on_health_changed)


func initialize_enemy(properties: Dictionary = {}):
	if not is_node_ready():
		await ready
	if properties.has("max_health"):
		health_component.max_health = properties["max_health"]
		if properties.has("current_health"):
			health_component.current_health = properties["current_health"]
		else:
			health_component.current_health = health_component.max_health
		_last_health = health_component.current_health
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

	if player:
		var dist: float = global_position.distance_to(player.global_position)

		# 保持距离：太近则后退，太远则不动（不主动接近）
		if dist < RETREAT_DIST:
			var away_dir: Vector2 = (global_position - player.global_position).normalized()
			velocity_component.accelerate_in_direction(away_dir)
		elif dist < PREFERRED_DIST:
			velocity_component.decelerate()
		else:
			# 太远了也不追，保持原位
			velocity_component.decelerate()
	else:
		velocity_component.decelerate()

	velocity_component.move(self)

	var move_sign: float = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)

	# 定时召唤
	_summon_timer -= delta
	if _summon_timer <= 0:
		_summon_timer = SUMMON_INTERVAL
		_summon_wave()


func _on_health_changed():
	"""受到高伤害时立即触发额外召唤"""
	var current_hp: float = health_component.current_health
	var damage_taken: float = _last_health - current_hp
	_last_health = current_hp

	if damage_taken >= DAMAGE_SUMMON_THRESHOLD:
		_summon_wave()
		# 视觉反馈：闪红
		visuals.modulate = Color(1.5, 0.5, 0.5)
		var tween: Tween = create_tween()
		tween.tween_property(visuals, "modulate", Color(1, 1, 1), 0.4)


func _summon_wave():
	"""召唤一波小怪"""
	# 清理已死亡的召唤物引用
	_active_summons = _active_summons.filter(func(e: Node2D) -> bool: return is_instance_valid(e))

	if _active_summons.size() >= MAX_SUMMONS:
		return

	var count: int = randi_range(SUMMON_COUNT_MIN, SUMMON_COUNT_MAX)
	count = min(count, MAX_SUMMONS - _active_summons.size())

	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if not entities_layer:
		return

	for i in range(count):
		var minion: Node2D = SandScarabScene.instantiate() as Node2D
		entities_layer.add_child(minion)

		# 在母体周围随机位置生成
		var offset: Vector2 = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(30.0, 60.0)
		minion.global_position = global_position + offset

		# 设置基础属性
		if minion.has_method("initialize_enemy"):
			minion.initialize_enemy({"max_health": 15.0})

		minion.add_to_group("enemy")
		_active_summons.append(minion)

		# 连接死亡清理
		if minion.has_node("HealthComponent"):
			var hc: Node = minion.get_node("HealthComponent")
			hc.died.connect(_on_summon_died.bind(minion))

	# 召唤视觉反馈：闪紫
	visuals.modulate = Color(0.8, 0.5, 1.2)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "modulate", Color(1, 1, 1), 0.3)


func _on_summon_died(minion: Node2D):
	if minion in _active_summons:
		_active_summons.erase(minion)


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
