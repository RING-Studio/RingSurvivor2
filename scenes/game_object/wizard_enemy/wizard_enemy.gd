extends CharacterBody2D
class_name WizardEnemy

@onready var velocity_component = $VelocityComponent
@onready var visuals = $Visuals

@export var armor_thickness:float = 1.0 #装甲厚度
@export var armorCoverage:float = 100.0 #覆甲率
@export var base_damage = 1 #基础伤害
@export var base_damage_modifier_ratio = 1.0 #基础伤害修改比例 = 1.0
@export var soft_attack_multiplier_percent  = 1.0 #软攻倍率 = 1.0
@export var penetrationAttackMultiplierPercent = 1 #穿甲攻击倍率/%
@export var penetration_depth_mm = 0 #穿深 = 0

var is_moving = false


func _ready():
	$HurtboxComponent.hit.connect(on_hit)


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
