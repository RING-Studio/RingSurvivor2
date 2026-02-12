extends Node2D
class_name ExternalMissile

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var speed_pixels_per_second: float = 360.0

@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/CollisionShape2D

var target: Node2D
var explosion_radius_px: float = 48.0
var base_damage: float = 30.0

func _ready():
	_sync_explosion_shape()

func setup(target_node: Node2D, damage: float, radius_px: float):
	target = target_node
	base_damage = damage
	explosion_radius_px = radius_px
	_sync_explosion_shape()

func _sync_explosion_shape():
	if explosion_collision and explosion_collision.shape is CircleShape2D:
		(explosion_collision.shape as CircleShape2D).radius = explosion_radius_px

func _process(delta: float):
	if target == null or not is_instance_valid(target):
		queue_free()
		return
	var to_target = target.global_position - global_position
	var dist = to_target.length()
	if dist <= 10.0:
		_explode()
		return
	var dir = to_target / max(dist, 0.001)
	rotation = to_target.angle()  # 让 Sprite2D 朝向目标
	global_position += dir * speed_pixels_per_second * delta

func _draw():
	# 占位：小导弹圆点
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.8, 0.2, 1.0))

func _explode():
	# 视觉占位：alpha=64 红色圆形范围提示
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(explosion_radius_px, Color(1.0, 0.2, 0.2, 64.0 / 255.0), 0.22)
		layer.add_child(fx)

	# AOE：通过 ExplosionArea 获取范围内敌人
	var enemies: Array[Node2D] = []
	if explosion_area:
		for area in explosion_area.get_overlapping_areas():
			if area is HurtboxComponent:
				var enemy = area.get_parent()
				if enemy and enemy.is_in_group("enemy") and is_instance_valid(enemy):
					if not enemies.has(enemy):
						enemies.append(enemy)
	
	# 伤害加成
	var dmg := base_damage
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	# 导弹·伤害：+25%/级
	var bonus_lvl = GameManager.current_upgrades.get("missile_damage", {}).get("level", 0)
	if bonus_lvl > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("missile_damage", bonus_lvl))
	
	# 可暴击（来源 accessory）
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	for enemy in enemies:
		var applied = dmg
		var is_critical = randf() < base_crit_rate
		if is_critical:
			applied *= crit_damage_multiplier
		
		var armor_coverage: float = 0.0
		if enemy.get("armorCoverage") != null:
			armor_coverage = float(enemy.get("armorCoverage"))
		elif enemy.get("armor_coverage") != null:
			armor_coverage = float(enemy.get("armor_coverage"))
		
		var final_damage = GlobalFomulaManager.calculate_damage(
			applied,
			GameManager.get_player_hard_attack_multiplier_percent(),
			GameManager.get_player_soft_attack_multiplier_percent(),
			GameManager.get_player_hard_attack_depth_mm(),
			enemy.get("armor_thickness") if enemy.get("armor_thickness") else 0,
			armor_coverage,
			enemy.get("hardAttackDamageReductionPercent") if enemy.get("hardAttackDamageReductionPercent") else 0.0
		)
		var hurtbox = enemy.get_node_or_null("HurtboxComponent")
		if hurtbox:
			hurtbox.apply_damage(final_damage, "accessory", is_critical)
	
	queue_free()
