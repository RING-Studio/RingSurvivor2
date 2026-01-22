extends Node2D
class_name MachineGunAbility

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
var _controller: MachineGunAbilityController = null  # Controller引用，用于通知暴击
var is_split_bullet: bool = false  # 是否是分裂子弹
var ricochet_attempted: bool = false  # 是否已尝试弹射
var has_spread_effect: bool = false  # 是否有扩散效果
var spread_damage_ratio: float = 1.0  # 扩散伤害比例
var lethal_strike_active: bool = false  # 致命一击是否激活

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

func set_controller(controller: MachineGunAbilityController):
	"""设置controller引用"""
	_controller = controller

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

	var target = area.get_parent()
	if !target or not target.is_in_group("enemy"):
		return
	
	# 记录已处理的hurtbox
	_hit_hurtboxes.append(hurtbox)

	# 通知 WeaponUpgradeHandler 命中
	if WeaponUpgradeHandler.instance:
		WeaponUpgradeHandler.instance.on_weapon_hit(target)

	var damage := _compute_damage_against(target)
	var damage_type := "weapon"
	var is_critical := false

	# 计算最终暴击率（使用 WeaponUpgradeHandler）
	var base_crit_rate = critical_chance + GameManager.get_global_crit_rate()
	var final_crit_chance = base_crit_rate
	if WeaponUpgradeHandler.instance:
		final_crit_chance = WeaponUpgradeHandler.instance.get_crit_rate_modifier(base_crit_rate, target)
	
	# 致命一击：如果激活，暴击伤害翻倍
	if WeaponUpgradeHandler.instance:
		lethal_strike_active = WeaponUpgradeHandler.instance.is_lethal_strike_active()
	
	if randf() < final_crit_chance:
		is_critical = true
		# 应用暴击伤害（使用 WeaponUpgradeHandler）
		var crit_rate_bonus = final_crit_chance - base_crit_rate
		var effective_crit_multiplier = critical_damage_multiplier
		if WeaponUpgradeHandler.instance:
			effective_crit_multiplier = WeaponUpgradeHandler.instance.get_crit_damage_modifier(
				critical_damage_multiplier, crit_rate_bonus
			)
		# 致命一击：暴击伤害翻倍
		if lethal_strike_active:
			effective_crit_multiplier *= 2.0
		damage *= effective_crit_multiplier
		damage_type = "critical"
		
		# 通知controller触发激射效果
		if _controller != null:
			_controller.on_critical_hit()
		
		# 通知 WeaponUpgradeHandler 暴击
		if WeaponUpgradeHandler.instance:
			WeaponUpgradeHandler.instance.on_weapon_critical(target)

	# 主目标扣血 + 伤害数字
	apply_damage_to_hurtbox(hurtbox, damage, damage_type)

	# 溅射
	_trigger_splash(target, damage)

	# 溅血（只有暴击且有升级层数时）
	if is_critical and bleed_layers > 0:
		_trigger_bleed(target)
	
	# 弹射判定（在命中后，穿透和分裂前）
	# 分裂子弹也可以弹射
	var ricochet_success = false
	if not ricochet_attempted:
		ricochet_attempted = true
		var ricochet_level = GameManager.current_upgrades.get("ricochet", {}).get("level", 0)
		if ricochet_level > 0:
			var ricochet_chance = 0.10 + 0.10 * ricochet_level  # (10+10lv)%
			if randf() < ricochet_chance:
				# 查找最近敌人（攻击范围内）
				var nearest_enemy = _find_nearest_enemy_for_ricochet(target)
				if nearest_enemy != null:
					# 弹射成功：改变方向弹射，不消耗穿透次数
					direction = (nearest_enemy.global_position - global_position).normalized()
					rotation = direction.angle()
					ricochet_success = true
	
	# 如果弹射成功，不消耗穿透次数，直接返回（不触发分裂）
	if ricochet_success:
		return
	
	# 分裂（仅在弹射失败时触发，暴击时触发）
	if is_critical and not is_split_bullet:
		_trigger_split()

	# 消耗穿透次数
	_hits_remaining -= 1
	if _hits_remaining <= 0:
		queue_free()

func _trigger_splash(target: Node2D, source_damage: float):
	if splash_count <= 0:
		return

	var splash_targets = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy != target and enemy.global_position.distance_to(target.global_position) <= SPLASH_RADIUS
	)
	var splash_damage = source_damage * splash_damage_ratio
	for count in range(splash_count):
		for enemy in splash_targets:
			if enemy:
				var hb = enemy.get_node_or_null("HurtboxComponent")
				if hb:
					apply_damage_to_hurtbox(hb, splash_damage, "weapon")

func _trigger_bleed(target: Node2D):
	var effect = BleedEffectScene.instantiate()
	effect.target = target
	effect.layers = bleed_layers
	# 流血伤害基于基础伤害计算
	var calculated_bleed_damage = max(_base_damage * bleed_damage_per_layer, 1.0)
	effect.damage_per_layer = calculated_bleed_damage
	target.add_child(effect)

func apply_damage_to_hurtbox(hurtbox: HurtboxComponent, amount: float, damage_type: String):
	hurtbox.apply_damage(amount, damage_type)

func _compute_damage_against(enemy: Node2D) -> float:
	var base_damage = _base_damage
	
	# 扩散伤害比例
	if has_spread_effect:
		base_damage *= spread_damage_ratio
	
	var armor_thickness: int = 0
	var armor_coverage: float = 0.0
	var hard_attack_damage_reduction: float = 0.0

	if enemy.get("armor_thickness") != null:
		armor_thickness = int(enemy.get("armor_thickness"))
	elif enemy.get("armor") != null:
		armor_thickness = int(enemy.get("armor"))

	if enemy.get("armorCoverage") != null:
		armor_coverage = float(enemy.get("armorCoverage"))
	elif enemy.get("armor_coverage") != null:
		armor_coverage = float(enemy.get("armor_coverage"))

	if enemy.get("hardAttackDamageReductionPercent") != null:
		hard_attack_damage_reduction = float(enemy.get("hardAttackDamageReductionPercent"))

	return GlobalFomulaManager.calculate_damage(
		base_damage,
		GameManager.get_player_hard_attack_multiplier_percent(),
		GameManager.get_player_soft_attack_multiplier_percent(),
		GameManager.get_player_hard_attack_depth_mm(),
		armor_thickness,
		armor_coverage,
		hard_attack_damage_reduction
	)

func _find_nearest_enemy_for_ricochet(exclude_target: Node2D) -> Node2D:
	"""查找最近敌人用于弹射（攻击范围内）"""
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest_enemy: Node2D = null
	var nearest_distance_squared = INF
	var MAX_RANGE_SQUARED = pow(200, 2)  # 继承自发射者的攻击范围
	
	for enemy in enemies:
		if enemy == exclude_target:
			continue
		var distance_squared = enemy.global_position.distance_squared_to(global_position)
		if distance_squared <= MAX_RANGE_SQUARED and distance_squared < nearest_distance_squared:
			nearest_distance_squared = distance_squared
			nearest_enemy = enemy
	
	return nearest_enemy

func _trigger_split():
	"""触发分裂效果"""
	var split_level = GameManager.current_upgrades.get("split_shot", {}).get("level", 0)
	if split_level <= 0:
		return
	
	var split_count = [2, 3][min(split_level - 1, 1)]  # 2/3发
	
	# 获取子弹场景
	var bullet_scene = preload("res://scenes/ability/machine_gun_ability/machine_gun_ability.tscn")
	
	# 创建分裂子弹
	for i in range(split_count):
		var split_bullet = bullet_scene.instantiate() as MachineGunAbility
		split_bullet.global_position = global_position
		# 复制当前状态，避免立即命中同一目标
		split_bullet._hit_hurtboxes = _hit_hurtboxes.duplicate()
		split_bullet.is_split_bullet = true  # 标记为分裂子弹
		split_bullet._base_damage = _base_damage * 0.5  # 50%伤害
		# 分散角度
		var angle_offset = (float(i) - float(split_count - 1) / 2.0) * deg_to_rad(15)
		split_bullet.direction = direction.rotated(angle_offset)
		split_bullet.rotation = split_bullet.direction.angle()
		split_bullet.penetration_capacity = penetration_capacity
		split_bullet.set_hits_remaining(penetration_capacity + 1)
		# 分裂子弹继承原子弹的所有属性
		split_bullet.critical_chance = critical_chance
		split_bullet.critical_damage_multiplier = critical_damage_multiplier
		split_bullet.bullet_speed = bullet_speed
		split_bullet.bullet_lifetime = bullet_lifetime
		split_bullet.bleed_layers = bleed_layers
		split_bullet.bleed_damage_per_layer = bleed_damage_per_layer
		split_bullet.splash_count = splash_count
		split_bullet.splash_damage_ratio = splash_damage_ratio
		split_bullet.has_spread_effect = has_spread_effect
		split_bullet.spread_damage_ratio = spread_damage_ratio
		split_bullet.ricochet_attempted = false  # 分裂子弹可以弹射
		if _controller != null:
			split_bullet.set_controller(_controller)
		get_tree().get_first_node_in_group("foreground_layer").call_deferred("add_child", split_bullet)
		split_bullet.set_base_damage(_base_damage * 0.5)
