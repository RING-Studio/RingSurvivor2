extends CharacterBody2D
class_name BossTitan
## 污染巨兽 — 沙漠深处的巨型污染体，体型庞大，会定期释放地面冲击波

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 8.0
@export var armorCoverage: float = 0.6
@export var base_damage: int = 4
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0
@export var knockback_resist: bool = true  # Boss 免疫击退

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.BOSS

# 冲击波参数
const SHOCKWAVE_INTERVAL: float = 5.0  # 每 5 秒释放一次冲击波
const SHOCKWAVE_RADIUS: float = 120.0  # px
const SHOCKWAVE_DAMAGE: float = 15.0
const MOVE_SPEED: int = 30

var _shockwave_timer: float = SHOCKWAVE_INTERVAL

const AoECircleEffect: GDScript = preload("res://scenes/effects/aoe_circle_effect.gd")


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = MOVE_SPEED
	velocity_component.acceleration = 8.0


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
	# 缓慢追踪玩家
	velocity_component.accelerate_to_player()
	velocity_component.move(self)

	var move_sign: float = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)

	# 冲击波计时
	_shockwave_timer -= delta
	if _shockwave_timer <= 0:
		_shockwave_timer = SHOCKWAVE_INTERVAL
		_cast_shockwave()


func _cast_shockwave():
	"""释放冲击波 — 以自身为中心，对范围内玩家造成伤害"""
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player:
		var dist: float = global_position.distance_to(player.global_position)
		if dist <= SHOCKWAVE_RADIUS:
			if player.has_node("HealthComponent"):
				var hc: Node = player.get_node("HealthComponent")
				hc.damage(SHOCKWAVE_DAMAGE)

	# 视觉效果：红色冲击波圆环
	_play_shockwave_effect()

	# 冲击波发动时闪白
	visuals.modulate = Color(1.5, 1.5, 1.5)
	var tween: Tween = create_tween()
	tween.tween_property(visuals, "modulate", Color(1, 1, 1), 0.3)


func _play_shockwave_effect():
	"""冲击波视觉占位：红色扩散圆环"""
	var layer: Node = get_tree().get_first_node_in_group("foreground_layer")
	if not layer:
		layer = get_tree().current_scene
	var fx: Node2D = AoECircleEffect.new()
	fx.global_position = global_position
	fx.setup(SHOCKWAVE_RADIUS, Color(1.0, 0.15, 0.1, 80.0 / 255.0), 0.35)
	layer.add_child(fx)


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
