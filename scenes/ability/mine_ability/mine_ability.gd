extends Node2D
class_name Mine

signal exploded(mine: Mine)

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox_component: HitboxComponent = $HitboxComponent
@onready var explosion_area: Area2D = $ExplosionArea
@onready var explosion_collision: CollisionShape2D = $ExplosionArea/CollisionShape2D

var explosion_radius: float
var base_damage: float
var elite_only: bool = false  # 是否仅精英/BOSS触发
var setup_called: bool = false

func _ready():
	# 如果setup已经调用过，应用设置
	if setup_called:
		_apply_setup()

func setup(radius: float, damage: float, elite_only_flag: bool):
	explosion_radius = radius
	base_damage = damage
	elite_only = elite_only_flag
	setup_called = true
	
	# 如果节点已准备好，立即应用设置
	if is_node_ready():
		_apply_setup()
	else:
		# 否则等待_ready
		await ready
		_apply_setup()

func _apply_setup():
	"""应用设置（在节点准备好后调用）"""
	# 设置爆炸范围
	if explosion_collision and explosion_collision.shape is CircleShape2D:
		explosion_collision.shape.radius = explosion_radius
	
	# 连接HitboxComponent的area_entered信号（检测与敌人HurtboxComponent的碰撞）
	if hitbox_component and not hitbox_component.area_entered.is_connected(_on_hitbox_area_entered):
		hitbox_component.area_entered.connect(_on_hitbox_area_entered)

func _on_hitbox_area_entered(area: Area2D):
	"""当HitboxComponent检测到HurtboxComponent时触发"""
	if not area is HurtboxComponent:
		return
	
	var enemy = area.get_parent()
	if not enemy or not enemy.is_in_group("enemy"):
		return
	
	# 检查是否仅精英/BOSS触发
	if elite_only:
		# 使用 get() 获取敌人的is_elite和is_boss属性
		var is_elite_flag = enemy.get("is_elite")
		var is_boss_flag = enemy.get("is_boss")
		if is_elite_flag != null and is_boss_flag != null:
			if not is_elite_flag and not is_boss_flag:
				return
		else:
			# 兼容旧代码：如果没有属性，使用scale判断
			var is_boss = enemy.scale.x >= 4.0 or (enemy.is_in_group("fixed_enemy") and enemy.scale.x >= 3.0)
			var is_elite = enemy.scale.x >= 2.0 and enemy.scale.x < 4.0
			if not is_elite and not is_boss:
				return
	
	# 触发爆炸
	trigger_explosion()

func trigger_explosion():
	"""触发爆炸"""
	# 获取范围内所有敌人（使用ExplosionArea检测HurtboxComponent）
	var enemies = []
	if explosion_area:
		var overlapping_areas = explosion_area.get_overlapping_areas()
		for area in overlapping_areas:
			if area is HurtboxComponent:
				var enemy = area.get_parent()
				if enemy and enemy.is_in_group("enemy"):
					enemies.append(enemy)
	
	# 对每个敌人造成伤害
	for enemy in enemies:
		_deal_damage_to_enemy(enemy)
	
	# 播放爆炸效果
	_play_explosion_effect()
	
	# 发出信号并移除
	exploded.emit(self)
	queue_free()

func _deal_damage_to_enemy(enemy: Node2D):
	"""对敌人造成伤害（走护甲计算）"""
	var damage = base_damage
	
	# 应用伤害加成（伤害强化影响所有伤害来源，包括配件）
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		damage *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	# 计算暴击
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0  # 默认暴击伤害倍率
	
	# 应用暴击伤害加成
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	var is_critical = randf() < base_crit_rate
	var damage_source = "accessory"
	
	if is_critical:
		damage *= crit_damage_multiplier
	
	# 走护甲计算
	var final_damage = GlobalFomulaManager.calculate_damage(
		damage,
		GameManager.get_player_hard_attack_multiplier_percent(),
		GameManager.get_player_soft_attack_multiplier_percent(),
		GameManager.get_player_hard_attack_depth_mm(),
		enemy.get("armor_thickness") if enemy.get("armor_thickness") else 0,
		enemy.get("armor_coverage") if enemy.get("armor_coverage") else 0.0,
		enemy.get("hardAttackDamageReductionPercent") if enemy.get("hardAttackDamageReductionPercent") else 0.0
	)
	
	# 应用伤害
	var hurtbox = enemy.get_node_or_null("HurtboxComponent")
	if hurtbox:
		hurtbox.apply_damage(final_damage, damage_source, is_critical)

func _play_explosion_effect():
	"""播放爆炸效果（可选）"""
	# TODO: 添加爆炸动画/粒子效果
	pass
