extends Node
class_name MachineGunAbilityController

const MAX_RANGE = 200
const FIRE_RATE_MIN = 1
const RECOIL_SPREAD_INCREASE_PER_SHOT_DEG = 0.4
const RECOIL_SPREAD_DECAY_DEG_PER_SEC = 1.5

enum SpreadPattern {
	FOCUSED,  # 集中散射：按散射角在基础方向两侧分布
	UNIFORM,  # 均匀分布：360° 均匀分布（风车）
	RANDOM    # 随机分布：每发独立随机方向（乱射）
}

@export var machine_gun_ability: PackedScene
@export var bullet_lifetime: float = 3.0  # 子弹生存时间（秒）
@export var bullet_penetration: int = 0
@export var bullet_critical_chance: float = 0.0
@export var bullet_critical_damage_multiplier: float = 2.0
@export var spread_count: int = 1
@export var splash_count: int = 0
@export var splash_damage_ratio: float = 0.5
@export var bleed_layers: int = 0
@export var bleed_damage_per_layer: float = 1.0
@export var fire_rate_per_minute: float = 300.0
@export var base_damage: float = 4.0
@export var bullet_speed: float = 1000.0

# 散射角（度）：集中散射时每发弹道相对基础方向的夹角，可被强化影响
var spread_angle_deg: float = 3.0
var fire_rate_bonus: float = 0.0
var _recoil_spread_bonus_deg: float = 0.0

func _ready():
	_update_timer_interval()
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	
	# 初始化时，根据已有升级重新计算属性
	_recalculate_all_attributes(GameManager.current_upgrades)

func _process(delta: float):
	if _recoil_spread_bonus_deg <= 0.0:
		return
	_recoil_spread_bonus_deg = max(_recoil_spread_bonus_deg - RECOIL_SPREAD_DECAY_DEG_PER_SEC * delta, 0.0)

func _update_timer_interval():
	var base_rate = fire_rate_per_minute
	var modifier = 0.0
	
	# 使用 WeaponUpgradeHandler 获取射速修正
	if WeaponUpgradeHandler.instance:
		modifier = WeaponUpgradeHandler.instance.get_fire_rate_modifier()
	
	# 加上原有的机炮专属射速加成
	modifier += fire_rate_bonus
	
	var effective_rate = max(base_rate * (1.0 + modifier), FIRE_RATE_MIN)
	$Timer.wait_time = 60.0 / effective_rate

func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE, 2)
	)
	# 无敌人时：仅当拥有扫射/风车/乱射（射击方向变更）时仍射击
	if enemies.size() == 0:
		var current_upgrades = GameManager.current_upgrades
		var has_fire_direction_change = (
			current_upgrades.get("sweep_fire", {}).get("level", 0) > 0 or
			current_upgrades.get("windmill", {}).get("level", 0) > 0 or
			current_upgrades.get("chaos_fire", {}).get("level", 0) > 0
		)
		if not has_fire_direction_change:
			return

	var player_position = player.global_position
	_apply_recoil_on_fire()
	
	# 通知 WeaponUpgradeHandler 武器发射
	var extra_shot_count = 0
	if WeaponUpgradeHandler.instance:
		extra_shot_count = WeaponUpgradeHandler.instance.on_weapon_fire()

	# 正常射击：计算基础方向（指向最近敌人/顺时针旋转/随机方向）
	var fire_direction = _resolve_fire_direction(player_position, enemies)
	_fire_shot(player_position, fire_direction)
	
	# 散弹额外射击：每次额外射击使用随机方向
	for i in range(extra_shot_count):
		var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		_fire_shot(player_position, random_direction)

func _get_spread_pattern() -> SpreadPattern:
	"""根据当前升级返回弹道分布模式"""
	var current_upgrades = GameManager.current_upgrades
	if current_upgrades.get("windmill", {}).get("level", 0) > 0:
		return SpreadPattern.UNIFORM
	if current_upgrades.get("chaos_fire", {}).get("level", 0) > 0:
		return SpreadPattern.RANDOM
	return SpreadPattern.FOCUSED

func _get_base_spread_angle_deg() -> float:
	var base = spread_angle_deg
	if WeaponUpgradeHandler.instance:
		base *= WeaponUpgradeHandler.instance.get_spread_angle_modifier()
	return base

func _get_recoil_extra_cap_deg(base_spread: float) -> float:
	var cap_modifier = 1.0
	if WeaponUpgradeHandler.instance:
		cap_modifier = WeaponUpgradeHandler.instance.get_recoil_cap_modifier()
	return max(base_spread * 2.0 * cap_modifier, 0.0)

func _apply_recoil_on_fire():
	var base_spread = _get_base_spread_angle_deg()
	var extra_cap = _get_recoil_extra_cap_deg(base_spread)
	if extra_cap <= 0.0:
		_recoil_spread_bonus_deg = 0.0
		return
	_recoil_spread_bonus_deg = min(
		_recoil_spread_bonus_deg + RECOIL_SPREAD_INCREASE_PER_SHOT_DEG,
		extra_cap
	)

func _get_effective_spread_angle_deg() -> float:
	return _get_base_spread_angle_deg() + _recoil_spread_bonus_deg

func _fire_shot(player_position: Vector2, base_direction: Vector2):
	"""
	执行一次射击（处理多弹道逻辑）
	base_direction: 基础射击方向（由外部决定：指向敌人/顺时针旋转/随机方向）
	"""
	# 获取有效弹道数
	var effective_spread_count = spread_count
	if WeaponUpgradeHandler.instance:
		effective_spread_count = WeaponUpgradeHandler.instance.get_spread_modifier(effective_spread_count)
	
	var shot_count = max(effective_spread_count, 1)
	var pattern = _get_spread_pattern()
	_distribute_bullets(pattern, base_direction, shot_count, player_position)

func _distribute_bullets(pattern: SpreadPattern, base_direction: Vector2, shot_count: int, player_position: Vector2):
	"""根据弹道分布模式发射子弹"""
	match pattern:
		SpreadPattern.FOCUSED:
			# 集中散射：每发按散射角在基础方向两侧分布
			var spread_angle = _get_effective_spread_angle_deg()
			for i in range(shot_count):
				var angle_offset = (float(i) - float(shot_count - 1) / 2.0) * deg_to_rad(spread_angle)
				var bullet_direction = base_direction.rotated(angle_offset)
				_emit_bullet(player_position, bullet_direction)
		SpreadPattern.UNIFORM:
			# 均匀分布：360° 均匀分布（风车）
			var angle_step = TAU / float(shot_count)
			for i in range(shot_count):
				var angle_offset = float(i) * angle_step
				var bullet_direction = base_direction.rotated(angle_offset)
				_emit_bullet(player_position, bullet_direction)
		SpreadPattern.RANDOM:
			# 随机分布：每发独立随机方向（乱射）
			for i in range(shot_count):
				var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
				_emit_bullet(player_position, random_direction)

func _resolve_fire_direction(player_position: Vector2, enemies: Array) -> Vector2:
	# 先计算基础方向
	var base_direction: Vector2
	if enemies.size() == 0:
		base_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	else:
		var nearest_enemy: Node2D = null
		var nearest_distance_squared: float = INF
		
		for enemy in enemies:
			var delta = enemy.global_position - player_position
			var distance_squared = delta.length_squared()
			if distance_squared < nearest_distance_squared:
				nearest_distance_squared = distance_squared
				nearest_enemy = enemy
		
		if nearest_enemy != null:
			var delta = nearest_enemy.global_position - player_position
			if delta.length_squared() >= 0.0001:
				base_direction = delta.normalized()
			else:
				base_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
		else:
			base_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	
	# 使用 WeaponUpgradeHandler 获取方向修正（处理扫射、乱射、风车）
	if WeaponUpgradeHandler.instance:
		return WeaponUpgradeHandler.instance.get_fire_direction_modifier(base_direction, player_position)
	
	return base_direction

func _emit_bullet(player_position: Vector2, direction: Vector2):
	var bullet_instance = machine_gun_ability.instantiate() as MachineGunAbility
	var speed_multiplier = 1.0
	var lifetime_multiplier = 1.0
	if WeaponUpgradeHandler.instance:
		speed_multiplier = WeaponUpgradeHandler.instance.get_bullet_speed_modifier()
		lifetime_multiplier = WeaponUpgradeHandler.instance.get_bullet_lifetime_modifier()
	# 在 add_child 之前设置所有参数，确保 _ready() 中的初始化使用正确的值
	bullet_instance.global_position = player_position
	bullet_instance.direction = direction
	bullet_instance.rotation = direction.angle()
	bullet_instance.bullet_lifetime = bullet_lifetime * lifetime_multiplier
	bullet_instance.penetration_capacity = bullet_penetration
	bullet_instance.critical_chance = bullet_critical_chance
	bullet_instance.critical_damage_multiplier = bullet_critical_damage_multiplier
	bullet_instance.bullet_speed = bullet_speed * speed_multiplier
	bullet_instance.splash_count = splash_count
	bullet_instance.splash_damage_ratio = splash_damage_ratio
	bullet_instance.bleed_layers = bleed_layers
	bullet_instance.bleed_damage_per_layer = bleed_damage_per_layer
	# 检查扩散效果
	var spread_level = GameManager.current_upgrades.get("spread_shot", {}).get("level", 0)
	if spread_level > 0:
		bullet_instance.has_spread_effect = true
		bullet_instance.spread_damage_ratio = [0.50, 0.40, 0.30][min(spread_level - 1, 2)]
	# 设置controller引用，用于通知暴击
	if bullet_instance.has_method("set_controller"):
		bullet_instance.set_controller(self)
	# 现在才 add_child，此时 _ready() 会使用正确的 penetration_capacity
	get_tree().get_first_node_in_group("foreground_layer").add_child(bullet_instance)
	bullet_instance.set_base_damage(_compute_bullet_damage())
	bullet_instance.set_hits_remaining(bullet_penetration + 1)

func _compute_bullet_damage() -> float:
	var damage = base_damage
	# 使用 WeaponUpgradeHandler 获取伤害修正（在计算护甲之前）
	if WeaponUpgradeHandler.instance:
		damage = WeaponUpgradeHandler.instance.get_damage_modifier(damage)
	return damage

func on_ability_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	# 不再累加，而是重新计算所有属性
	_recalculate_all_attributes(current_upgrades)

func _reset_to_base_values():
	"""重置所有属性到基础值。基础伤害来自 GameManager（车型+装甲+主武器）。"""
	fire_rate_bonus = 0.0
	bullet_critical_chance = 0.0
	bullet_critical_damage_multiplier = 2.0  # 基础值
	base_damage = GameManager.get_player_base_damage()  # 与配装一致
	bullet_penetration = 0
	spread_count = 1  # 基础值
	spread_angle_deg = 3.0  # 散射角（度），可被强化修正
	bleed_layers = 0

func _recalculate_all_attributes(current_upgrades: Dictionary):
	"""根据当前所有升级重新计算属性"""
	# 先重置到基础值
	_reset_to_base_values()
	
	# 遍历所有机炮相关升级，累加效果
	for upgrade_id in current_upgrades.keys():
		if not upgrade_id.begins_with("mg_"):
			continue
		
		var level = current_upgrades[upgrade_id].get("level", 0)
		if level <= 0:
			continue
		
		var effect_value = UpgradeEffectManager.get_effect(upgrade_id, level)
		
		match upgrade_id:
			"mg_fire_rate_1", "mg_fire_rate_2", "mg_fire_rate_3":
				fire_rate_bonus += effect_value
			"mg_precision_1", "mg_precision_2", "mg_precision_3":
				bullet_critical_chance += effect_value
			"mg_crit_damage":
				bullet_critical_damage_multiplier += effect_value
			"mg_damage_1", "mg_damage_2":
				base_damage += effect_value
			"mg_penetration":
				bullet_penetration += int(effect_value)
			"mg_spread":
				spread_count += int(effect_value)
			"mg_bleed":
				bleed_layers += int(effect_value)
			"mg_heavy_round":
				# 射速 -10lv%，基础伤害+1lv
				fire_rate_bonus -= 0.10 * float(level)
				base_damage += float(level)
			"mg_he_round":
				# 基础伤害+3，穿透固定为1
				base_damage += 3.0
				bullet_penetration = 1  # 固定为1
			# mg_rapid_fire_1/2/3 是特殊效果，在这里不处理
			# mg_overload 在 WeaponUpgradeHandler 中处理
	
	# 使用 WeaponUpgradeHandler 获取穿透和弹道修正
	if WeaponUpgradeHandler.instance:
		bullet_penetration = WeaponUpgradeHandler.instance.get_penetration_modifier(bullet_penetration)
		spread_count = WeaponUpgradeHandler.instance.get_spread_modifier(spread_count)
	
	var base_spread = _get_base_spread_angle_deg()
	_recoil_spread_bonus_deg = min(_recoil_spread_bonus_deg, _get_recoil_extra_cap_deg(base_spread))
	
	_update_timer_interval()

func on_critical_hit():
	"""当机炮造成暴击时调用此方法（保留用于未来扩展）"""
	# 激射效果已移除，此方法保留用于未来可能的扩展
	pass
