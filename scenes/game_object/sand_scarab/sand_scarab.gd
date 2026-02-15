extends CharacterBody2D
class_name SandScarab
## 沙漠圣甲虫 — 常见的沙漠污染生物，外壳坚硬，以群体围攻为主要手段

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness: float = 1.0  # 薄甲
@export var armorCoverage: float = 0.1  # 低覆甲率
@export var base_damage: int = 1
@export var base_damage_modifier_ratio: float = 1.0
@export var soft_attack_multiplier_percent: float = 1.0
@export var hardAttackMultiplierPercent: int = 1
@export var hard_attack_depth_mm: int = 0

enum EnemyRank { NORMAL = 0, ELITE = 1, BOSS = 2 }
@export var enemy_rank: int = EnemyRank.NORMAL


func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	velocity_component.max_speed = 75
	velocity_component.acceleration = 20.0


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
	velocity_component.accelerate_to_player()
	velocity_component.move(self)

	var move_sign: float = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)


func on_hit():
	var audio = get_node_or_null("HitRandomAudioPlayerComponent")
	if audio:
		audio.play_random()
