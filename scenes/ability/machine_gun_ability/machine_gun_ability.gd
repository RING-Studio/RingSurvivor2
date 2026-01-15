extends Node2D
class_name MachineGunAbility

const HurtboxComponent = preload("res://scenes/component/hurtbox_component.gd")
const BleedEffectScene: PackedScene = preload("res://scenes/effects/bleed_effect.tscn")
const SPLASH_RADIUS = 80

@onready var hitbox_component: HitboxComponent = $HitboxComponent

var direction: Vector2 = Vector2.RIGHT
@export var bullet_lifetime: float = 3.0
@export var bullet_speed: float = 900.0
@export var penetration_capacity: int = 0
@export var critical_chance: float = 0.0
@export var critical_damage_multiplier: float = 2.0
@export var splash_count: int = 0
@export var splash_damage_ratio: float = 0.5
@export var bleed_layers: int = 0
@export var bleed_damage_per_layer: float = 1.0

var _hits_remaining: int = 1
var _base_damage: float = 0.0
var _hit_hurtboxes: Array[HurtboxComponent] = []

func _ready():
	var timer = get_tree().create_timer(bullet_lifetime)
	timer.timeout.connect(queue_free)
	hitbox_component.area_entered.connect(_on_hitbox_area_entered)
	set_hits_remaining()

func _process(delta):
	global_position += direction.normalized() * bullet_speed * delta

func set_base_damage(amount: float):
	_base_damage = amount
	hitbox_component.damage = amount
	hitbox_component.damage_type = "weapon"

func set_hits_remaining(amount: int = penetration_capacity + 1):
	_hits_remaining = max(amount, 1)

func _on_hitbox_area_entered(area: Area2D):
	if not area is HurtboxComponent:
		return
	
	var hurtbox = area as HurtboxComponent
	
	# 检查是否已经处理过这个hurtbox
	if hurtbox in _hit_hurtboxes:
		return
	
	# 检查是否还有穿透次数
	if _hits_remaining <= 0:
		return

	var owner = area.get_parent()
	if owner == null or not owner.is_in_group("enemy"):
		return
	
	# 记录已处理的hurtbox
	_hit_hurtboxes.append(hurtbox)

	var damage := _compute_damage_against(owner)
	var damage_type := "weapon"
	var is_critical := false

	if randf() < critical_chance:
		is_critical = true
		damage *= critical_damage_multiplier
		damage_type = "critical"

	# 主目标扣血 + 伤害数字
	apply_damage_to_hurtbox(hurtbox, damage, damage_type)

	# 溅射
	_trigger_splash(owner, damage)

	# 溅血（只有暴击且有升级层数时）
	if is_critical and bleed_layers > 0:
		_trigger_bleed(owner)

	_hits_remaining -= 1
	if _hits_remaining <= 0:
		queue_free()

func _trigger_splash(owner: Node2D, source_damage: float):
	if splash_count <= 0:
		return

	var splash_targets = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy != owner and enemy.global_position.distance_to(owner.global_position) <= SPLASH_RADIUS
	)
	var splash_damage = source_damage * splash_damage_ratio
	for count in range(splash_count):
		for enemy in splash_targets:
			if enemy:
				var hb = enemy.get_node_or_null("HurtboxComponent")
				if hb:
					apply_damage_to_hurtbox(hb, splash_damage, "weapon")

func _trigger_bleed(owner: Node2D):
	var effect = BleedEffectScene.instantiate()
	effect.target = owner
	effect.layers = bleed_layers
	# 流血伤害基于基础伤害计算
	var calculated_bleed_damage = max(_base_damage * bleed_damage_per_layer, 1.0)
	effect.damage_per_layer = calculated_bleed_damage
	owner.add_child(effect)

func apply_damage_to_hurtbox(hurtbox: HurtboxComponent, amount: float, damage_type: String):
	hurtbox.apply_damage(amount, damage_type)

func _compute_damage_against(enemy: Node2D) -> float:
	var armor_thickness: int = 0
	var armor_coverage: float = 0.0
	var penetration_reduction: float = 0.0

	if enemy.get("armor_thickness") != null:
		armor_thickness = int(enemy.get("armor_thickness"))
	elif enemy.get("armor") != null:
		armor_thickness = int(enemy.get("armor"))

	if enemy.get("armorCoverage") != null:
		armor_coverage = float(enemy.get("armorCoverage"))
	elif enemy.get("armor_coverage") != null:
		armor_coverage = float(enemy.get("armor_coverage"))

	if enemy.get("penetrationDamageReductionPercent") != null:
		penetration_reduction = float(enemy.get("penetrationDamageReductionPercent"))

	return GlobalFomulaManager.calculate_damage(
		_base_damage,
		GameManager.get_player_base_damage_modifier_ratio(),
		GameManager.get_player_penetration_attack_multiplier_percent(),
		GameManager.get_player_soft_attack_multiplier_percent(),
		GameManager.get_player_penetration_depth_mm(),
		armor_thickness,
		armor_coverage,
		penetration_reduction
	)
