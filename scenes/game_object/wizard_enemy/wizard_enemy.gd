extends CharacterBody2D
class_name WizardEnemy

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent
@onready var health_component = $HealthComponent

@export var armor_thickness:float = 1.0 #装甲厚度
@export var armorCoverage:float = 100.0 #覆甲率
@export var base_damage = 1 #基础伤害
@export var base_damage_modifier_ratio = 1.0 #基础伤害修改比例 = 1.0
@export var soft_attack_multiplier_percent  = 1.0 #软攻倍率 = 1.0
@export var hardAttackMultiplierPercent = 1 #硬攻倍率/%
@export var hard_attack_depth_mm = 0 #硬攻深度 = 0
@export var is_elite: bool = false  # 是否为精英敌人
@export var is_boss: bool = false  # 是否为BOSS

var is_moving = false


func _ready():
	$HurtboxComponent.hit.connect(on_hit)

func initialize_enemy(properties: Dictionary = {}):
	"""
	初始化敌人属性
	properties 可包含的键：
	- max_health: float - 最大生命值
	- current_health: float - 当前生命值（如果未指定，则等于 max_health）
	- armor_thickness: float - 装甲厚度
	- armor_coverage: float - 覆甲率
	- base_damage: float - 基础伤害
	- base_damage_modifier_ratio: float - 基础伤害修改比例
	- soft_attack_multiplier_percent: float - 软攻倍率
	- hard_attack_multiplier_percent: float - 硬攻倍率
	- hard_attack_depth_mm: float - 硬攻深度
	"""
	# 等待节点准备就绪
	if not is_node_ready():
		await ready
	
	# 设置生命值
	if properties.has("max_health"):
		health_component.max_health = properties["max_health"]
		if properties.has("current_health"):
			health_component.current_health = properties["current_health"]
		else:
			health_component.current_health = health_component.max_health
	
	# 设置其他属性（如果提供）
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


func _process(delta):
	if is_moving:
		velocity_component.accelerate_to_player()
	else:
		velocity_component.decelerate()

	velocity_component.move(self)

	var move_sign = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(move_sign, 1)


func set_is_moving(moving: bool):
	is_moving = moving


func on_hit():
	$HitRandomAudioPlayerComponent.play_random()
