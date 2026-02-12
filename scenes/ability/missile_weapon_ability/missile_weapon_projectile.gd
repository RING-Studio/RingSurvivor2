extends Node2D
class_name MissileWeaponProjectile

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/CollisionShape2D

var target: Node2D = null
var speed_pixels_per_second: float = 520.0
var lifetime_seconds: float = 4.0

var explosion_radius_px: float = 96.0
var base_damage: float = 0.0
var damage_ratio: float = 1.0
var _has_exploded: bool = false

func _ready():
	queue_redraw()
	var t = get_tree().create_timer(lifetime_seconds)
	t.timeout.connect(func(): _explode())
	# 碰撞检测
	if hitbox_component:
		hitbox_component.area_entered.connect(_on_hitbox_area_entered)
		hitbox_component.damage_type = "weapon"
	# 同步爆炸半径到 Area2D 碰撞形状
	_sync_explosion_shape()

func _on_hitbox_area_entered(area: Area2D):
	if _has_exploded:
		return
	if not area is HurtboxComponent:
		return
	var hit_target = area.get_parent()
	if hit_target == null or not hit_target.is_in_group("enemy"):
		return
	_explode()

func _process(delta: float):
	if _has_exploded:
		return
	if target == null or not is_instance_valid(target):
		global_position += Vector2.RIGHT.rotated(rotation) * speed_pixels_per_second * delta
		return
	var delta_pos = target.global_position - global_position
	# 距离足够近时爆炸（作为碰撞检测的补充）
	if delta_pos.length_squared() < 100.0:  # 10px
		_explode()
		return
	rotation = delta_pos.angle()
	global_position += delta_pos.normalized() * speed_pixels_per_second * delta

func setup(t: Node2D, dmg: float, radius_px: float, ratio: float = 1.0):
	target = t
	base_damage = dmg
	explosion_radius_px = radius_px
	damage_ratio = ratio
	if target:
		rotation = (target.global_position - global_position).angle()
	_sync_explosion_shape()

func _sync_explosion_shape():
	if explosion_collision and explosion_collision.shape is CircleShape2D:
		(explosion_collision.shape as CircleShape2D).radius = explosion_radius_px

func _draw():
	# 占位：黄色小点
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.8, 0.2, 1.0))

func _explode():
	if _has_exploded:
		return
	_has_exploded = true
	if not is_inside_tree():
		return
	# 视觉占位：红色 alpha=64 圆形（范围伤害）
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = global_position
		fx.setup(explosion_radius_px, Color(1.0, 0.2, 0.2, 64.0 / 255.0), 0.22)
		layer.add_child(fx)
	
	var base_dmg := base_damage * damage_ratio
	
	# AOE 伤害：通过 ExplosionArea 获取范围内的 HurtboxComponent
	var enemies: Array[Node2D] = []
	if explosion_area:
		var overlapping = explosion_area.get_overlapping_areas()
		for area in overlapping:
			if area is HurtboxComponent:
				var enemy = area.get_parent()
				if enemy and enemy.is_in_group("enemy") and is_instance_valid(enemy):
					if not enemies.has(enemy):
						enemies.append(enemy)
	
	for enemy in enemies:
		# 伤害修正（主武器通用强化 + 目标特定加成）
		var dmg := base_dmg
		if WeaponUpgradeHandler.instance:
			dmg = WeaponUpgradeHandler.instance.get_damage_modifier(dmg, enemy)
		
		# 暴击
		var base_crit_rate = GameManager.get_global_crit_rate()
		var final_crit = base_crit_rate
		if WeaponUpgradeHandler.instance:
			final_crit = WeaponUpgradeHandler.instance.get_crit_rate_modifier(base_crit_rate, enemy)
		var is_critical = randf() < final_crit
		var crit_mult = 2.0
		if WeaponUpgradeHandler.instance:
			crit_mult = WeaponUpgradeHandler.instance.get_crit_damage_modifier(2.0, max(0.0, final_crit - base_crit_rate))
		if is_critical:
			dmg *= crit_mult
			if WeaponUpgradeHandler.instance:
				WeaponUpgradeHandler.instance.on_weapon_critical(enemy)
		
		# 命中通知
		if WeaponUpgradeHandler.instance:
			WeaponUpgradeHandler.instance.on_weapon_hit(enemy)
		
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
			# 击杀检测
			var e_hc = enemy.get_node_or_null("HealthComponent")
			if e_hc and e_hc.current_health <= 0:
				if WeaponUpgradeHandler.instance:
					WeaponUpgradeHandler.instance.on_enemy_killed(enemy)
					if is_critical:
						WeaponUpgradeHandler.instance.on_enemy_killed_by_critical(enemy)
	
	queue_free()
