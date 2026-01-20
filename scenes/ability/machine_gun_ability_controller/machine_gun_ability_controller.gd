extends Node
class_name MachineGunAbilityController

const MAX_RANGE = 200
const FIRE_RATE_MIN = 1

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

var fire_rate_bonus: float = 0.0

func _ready():
	_update_timer_interval()
	$Timer.timeout.connect(on_timer_timeout)
	GameEvents.ability_upgrade_added.connect(on_ability_upgrade_added)
	
	# 初始化时，根据已有升级重新计算属性
	_recalculate_all_attributes(GameManager.current_upgrades)

func _update_timer_interval():
	var effective_rate = max(fire_rate_per_minute * (1 + fire_rate_bonus), FIRE_RATE_MIN)
	$Timer.wait_time = 60.0 / effective_rate

func on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return

	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE, 2)
	)
	if enemies.size() == 0:
		return

	var player_position = player.global_position
	var fire_direction = _resolve_fire_direction(player_position, enemies)

	var shot_count = max(spread_count, 1)
	for i in range(shot_count):
		var angle_offset = (float(i) - float(shot_count - 1) / 2.0) * deg_to_rad(3)
		var bullet_direction = fire_direction.rotated(angle_offset)
		_emit_bullet(player_position, bullet_direction)

func _resolve_fire_direction(player_position: Vector2, enemies: Array) -> Vector2:
	if enemies.size() == 0:
		return Vector2.RIGHT.rotated(randf_range(0, TAU))
	
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
			return delta.normalized()
	
	return Vector2.RIGHT.rotated(randf_range(0, TAU))

func _emit_bullet(player_position: Vector2, direction: Vector2):
	var bullet_instance = machine_gun_ability.instantiate() as MachineGunAbility
	# 在 add_child 之前设置所有参数，确保 _ready() 中的初始化使用正确的值
	bullet_instance.global_position = player_position
	bullet_instance.direction = direction
	bullet_instance.rotation = direction.angle()
	bullet_instance.bullet_lifetime = bullet_lifetime
	bullet_instance.penetration_capacity = bullet_penetration
	bullet_instance.critical_chance = bullet_critical_chance
	bullet_instance.critical_damage_multiplier = bullet_critical_damage_multiplier
	bullet_instance.bullet_speed = bullet_speed
	bullet_instance.splash_count = splash_count
	bullet_instance.splash_damage_ratio = splash_damage_ratio
	bullet_instance.bleed_layers = bleed_layers
	bullet_instance.bleed_damage_per_layer = bleed_damage_per_layer
	# 现在才 add_child，此时 _ready() 会使用正确的 penetration_capacity
	get_tree().get_first_node_in_group("foreground_layer").add_child(bullet_instance)
	bullet_instance.set_base_damage(_compute_bullet_damage())
	bullet_instance.set_hits_remaining(bullet_penetration + 1)

func _compute_bullet_damage() -> float:
	return base_damage

func on_ability_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	# 不再累加，而是重新计算所有属性
	_recalculate_all_attributes(current_upgrades)

func _reset_to_base_values():
	"""重置所有属性到基础值"""
	fire_rate_bonus = 0.0
	bullet_critical_chance = 0.0
	bullet_critical_damage_multiplier = 2.0  # 基础值
	base_damage = 4.0  # 基础值
	bullet_penetration = 0
	spread_count = 1  # 基础值
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
			# mg_rapid_fire_1/2/3 是特殊效果，在这里不处理
			# 可以在其他地方检查 level > 0 来判断是否激活
	
	_update_timer_interval()
