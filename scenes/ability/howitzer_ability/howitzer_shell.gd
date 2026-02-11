extends Node2D
class_name HowitzerShell

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@onready var hitbox_component: HitboxComponent = $HitboxComponent

var direction: Vector2 = Vector2.RIGHT
var speed_pixels_per_second: float = 520.0
var lifetime_seconds: float = 3.0

var explosion_radius_px: float = 64.0
var base_damage: float = 0.0
var damage_ratio: float = 1.0  # 用于扩散/多弹道等伤害比例

func _ready():
	queue_redraw()
	var t = get_tree().create_timer(lifetime_seconds)
	t.timeout.connect(queue_free)
	hitbox_component.area_entered.connect(_on_hitbox_area_entered)
	hitbox_component.damage_type = "weapon"

func _process(delta: float):
	global_position += direction.normalized() * speed_pixels_per_second * delta

func setup(dir: Vector2, dmg: float, radius_px: float, ratio: float = 1.0):
	direction = dir
	base_damage = dmg
	explosion_radius_px = radius_px
	damage_ratio = ratio
	rotation = dir.angle()  # 让 Sprite2D 朝向移动方向

func _draw():
	# 占位：炮弹小点
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 1.0, 1.0, 1.0))

func _on_hitbox_area_entered(area: Area2D):
	if not area is HurtboxComponent:
		return
	var target = area.get_parent()
	if target == null or not target.is_in_group("enemy"):
		return
	_explode()

func _explode():
	# 视觉占位：红色 alpha=64 圆形（范围伤害）
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(explosion_radius_px, Color(1.0, 0.2, 0.2, 64.0 / 255.0), 0.22)
		layer.add_child(fx)
	
	var dmg := base_damage * damage_ratio
	# 伤害修正（主武器通用强化）
	if WeaponUpgradeHandler.instance:
		dmg = WeaponUpgradeHandler.instance.get_damage_modifier(dmg)
	
	# 暴击（主武器通用强化）
	var base_crit_rate = GameManager.get_global_crit_rate()
	var final_crit = base_crit_rate
	if WeaponUpgradeHandler.instance:
		final_crit = WeaponUpgradeHandler.instance.get_crit_rate_modifier(base_crit_rate, null)
	var is_critical = randf() < final_crit
	var crit_mult = 2.0
	if WeaponUpgradeHandler.instance:
		crit_mult = WeaponUpgradeHandler.instance.get_crit_damage_modifier(2.0, max(0.0, final_crit - base_crit_rate))
	if is_critical:
		dmg *= crit_mult
	
	# AOE 伤害
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_squared_to(global_position) > explosion_radius_px * explosion_radius_px:
			continue
		
		var armor_coverage: float = 0.0
		if enemy.get("armorCoverage") != null:
			armor_coverage = float(enemy.get("armorCoverage"))
		elif enemy.get("armor_coverage") != null:
			armor_coverage = float(enemy.get("armor_coverage"))
		
		var final_damage = GlobalFomulaManager.calculate_damage(
			dmg,
			GameManager.get_player_hard_attack_multiplier_percent(),
			GameManager.get_player_soft_attack_multiplier_percent(),
			GameManager.get_player_hard_attack_depth_mm(),
			enemy.get("armor_thickness") if enemy.get("armor_thickness") else 0,
			armor_coverage,
			enemy.get("hardAttackDamageReductionPercent") if enemy.get("hardAttackDamageReductionPercent") else 0.0
		)
		var hb = enemy.get_node_or_null("HurtboxComponent")
		if hb:
			hb.apply_damage(final_damage, "weapon", is_critical)
	
	queue_free()
