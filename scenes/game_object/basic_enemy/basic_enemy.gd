extends CharacterBody2D
class_name BasicEnemy

@onready var visuals = $Visuals
@onready var velocity_component = $VelocityComponent

@export var armor_thickness:float = 1.0 #装甲厚度
@export var armorCoverage:float = 100.0 #覆甲率
@export var base_damage = 1 #基础伤害
@export var base_damage_modifier_ratio = 1.0 #基础伤害修改比例 = 1.0
@export var soft_attack_multiplier_percent  = 1.0 #软攻倍率 = 1.0
@export var penetrationAttackMultiplierPercent = 1 #穿甲攻击倍率/%
@export var penetration_depth_mm = 0 #穿深 = 0

func _ready():
	$HurtboxComponent.hit.connect(on_hit)
	

func _process(delta):
	velocity_component.accelerate_to_player()
	velocity_component.move(self)
	
	var move_sign = sign(velocity.x)
	if move_sign != 0:
		visuals.scale = Vector2(-move_sign, 1)


func on_hit():
	$HitRandomAudioPlayerComponent.play_random()
