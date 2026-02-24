extends Node2D
class_name TankGunShell

@onready var hitbox_component: HitboxComponent = $HitboxComponent

var direction: Vector2 = Vector2.RIGHT
var speed_pixels_per_second: float = 860.0
var lifetime_seconds: float = 2.5

var penetration_capacity: int = 0
var base_damage: float = 0.0
var damage_ratio: float = 1.0
var depth_bonus_mm: float = 0.0

var _hits_remaining: int = 1
var _hit_hurtboxes: Array[HurtboxComponent] = []
var _has_hit_anything: bool = false

func _ready():
	queue_redraw()
	var t = get_tree().create_timer(lifetime_seconds)
	t.timeout.connect(_on_lifetime_expired)
	hitbox_component.area_entered.connect(_on_hitbox_area_entered)
	hitbox_component.damage_type = "weapon"
	_set_hits_remaining()

func _process(delta: float):
	global_position += direction.normalized() * speed_pixels_per_second * delta

func setup(dir: Vector2, dmg: float, pen_capacity: int, ratio: float = 1.0, depth_bonus: float = 0.0):
	direction = dir
	base_damage = dmg
	penetration_capacity = pen_capacity
	damage_ratio = ratio
	depth_bonus_mm = depth_bonus
	_set_hits_remaining()
	rotation = dir.angle()  # 让 Sprite2D 朝向移动方向

func _draw():
	# 占位：坦克炮弹更亮一点
	draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.9, 0.6, 1.0))

func _set_hits_remaining():
	_hits_remaining = max(penetration_capacity + 1, 1)

func _on_hitbox_area_entered(area: Area2D):
	if not area is HurtboxComponent:
		return
	var hurtbox = area as HurtboxComponent
	if hurtbox in _hit_hurtboxes:
		return
	if _hits_remaining <= 0:
		return
	var target = area.get_parent()
	if target == null or not target.is_in_group("enemy"):
		return
	_hit_hurtboxes.append(hurtbox)
	_hits_remaining -= 1
	_has_hit_anything = true
	
	if WeaponUpgradeHandler.instance:
		WeaponUpgradeHandler.instance.on_weapon_hit(target)
	
	var dmg: float = base_damage * damage_ratio
	if WeaponUpgradeHandler.instance:
		dmg = WeaponUpgradeHandler.instance.get_damage_modifier(dmg, target)
	
	# 暴击
	var base_crit_rate = GameManager.get_global_crit_rate()
	var final_crit = base_crit_rate
	if WeaponUpgradeHandler.instance:
		final_crit = WeaponUpgradeHandler.instance.get_crit_rate_modifier(base_crit_rate, target)
	var is_critical = randf() < final_crit
	var crit_mult = 2.0
	if WeaponUpgradeHandler.instance:
		crit_mult = WeaponUpgradeHandler.instance.get_crit_damage_modifier(2.0, max(0.0, final_crit - base_crit_rate))
	if is_critical:
		dmg *= crit_mult
		if WeaponUpgradeHandler.instance:
			WeaponUpgradeHandler.instance.on_weapon_critical(target)
			var bore_bonus: float = WeaponUpgradeHandler.instance.get_precision_bore_depth_bonus(true)
			if bore_bonus > 0.0:
				dmg *= (1.0 + bore_bonus)
	else:
		if WeaponUpgradeHandler.instance:
			WeaponUpgradeHandler.instance.on_non_crit_hit()
	
	var armor_coverage: float = 0.0
	if target.get("armorCoverage") != null:
		armor_coverage = float(target.get("armorCoverage"))
	elif target.get("armor_coverage") != null:
		armor_coverage = float(target.get("armor_coverage"))
	
	var final_damage = GlobalFomulaManager.calculate_damage(
		dmg,
		GameManager.get_player_hard_attack_multiplier_percent(),
		GameManager.get_player_soft_attack_multiplier_percent(),
		GameManager.get_player_hard_attack_depth_mm() + depth_bonus_mm,
		target.get("armor_thickness") if target.get("armor_thickness") else 0,
		armor_coverage,
		target.get("hardAttackDamageReductionPercent") if target.get("hardAttackDamageReductionPercent") else 0.0
	)
	hurtbox.apply_damage(final_damage, "weapon", is_critical)
	
	# 破片喷流：穿透后附加破片伤害
	if WeaponUpgradeHandler.instance and _hits_remaining > 0:
		var fragment_dmg: float = WeaponUpgradeHandler.instance.get_shock_fragment_damage(final_damage, true)
		if fragment_dmg > 0.0:
			hurtbox.apply_damage(fragment_dmg, "weapon", false)
	
	var t_hc = target.get_node_or_null("HealthComponent")
	if t_hc and t_hc.current_health <= 0:
		if WeaponUpgradeHandler.instance:
			WeaponUpgradeHandler.instance.on_enemy_killed(target)
			if is_critical:
				WeaponUpgradeHandler.instance.on_enemy_killed_by_critical(target)
	
	if _hits_remaining <= 0:
		queue_free()

func _on_lifetime_expired():
	if not _has_hit_anything and WeaponUpgradeHandler.instance:
		WeaponUpgradeHandler.instance.on_weapon_miss()
	queue_free()
