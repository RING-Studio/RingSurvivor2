extends Node

const SPAWN_RADIUS = 375

# 区域类型枚举
enum RegionType {
	NONE = 0,
	REGION_TYPE_1 = 1,  # Region1_x 系列
	REGION_TYPE_2 = 2,  # Region2_x 系列
	REGION_TYPE_3 = 3   # Region3
}

# 怪物生成类型标签
const GROUP_RANDOM_ENEMY = "random_enemy"  # 随机生成的怪物
const GROUP_FIXED_ENEMY = "fixed_enemy"   # 固定生成的怪物（如 BOSS）

@export var basic_enemy_scene: PackedScene
@export var wizard_enemy_scene: PackedScene
@export var arena_time_manager: Node
@export var map_center: Vector2 = Vector2(960, 540)  # 地图中心位置

@onready var timer = $Timer

var base_spawn_time = 0
var enemy_table = WeightedTable.new()
var number_to_spawn = 1

# 区域系统相关变量
var current_region_type: int = RegionType.NONE
var random_enemy_count: int = 0  # 当前随机生成的敌人数量
var boss_spawned: bool = false  # Region3 BOSS 是否已生成
var tracked_enemies: Array[Node2D] = []  # 追踪的随机生成敌人列表


func _ready():
	enemy_table.add_item(basic_enemy_scene, 4)
	enemy_table.add_item(wizard_enemy_scene, 1)

	base_spawn_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)


func get_spawn_position():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		print("what")
		return Vector2.ZERO
	
	var spawn_position = Vector2.ZERO
	var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
		var additional_check_offset = random_direction * 20

		var query_paramaters = PhysicsRayQueryParameters2D.create(player.global_position, spawn_position + additional_check_offset, 1)
		var result = get_tree().root.world_2d.direct_space_state.intersect_ray(query_paramaters)

		if result.is_empty():
			break
		else:
			random_direction = random_direction.rotated(deg_to_rad(90))
	
	return spawn_position


func on_timer_timeout():
	timer.start()
	
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	# 检查是否在有效区域
	if current_region_type == RegionType.NONE:
		return
	
	# 检查随机生成上限
	var max_random_enemies = calculate_max_random_enemies()
	if random_enemy_count >= max_random_enemies:
		return
	
	# Region3 使用特殊的三人组生成逻辑
	if current_region_type == RegionType.REGION_TYPE_3:
		# 检查是否有足够空间生成三人组（需要至少 3 个空位）
		if random_enemy_count + 3 <= max_random_enemies:
			spawn_region3_group()
	else:
		# Region1 和 Region2 使用常规生成逻辑
		for i in number_to_spawn:
			if random_enemy_count >= max_random_enemies:
				break
			spawn_random_enemy()


func on_arena_difficulty_increased(arena_difficulty: int):
	var time_off = (.1 / 12) * arena_difficulty
	time_off = min(time_off, .7)
	timer.wait_time = base_spawn_time - time_off
	
	# if arena_difficulty == 6:
	

	# elif arena_difficulty == 18:
	# 	enemy_table.add_item(bat_enemy_scene, 8)
		
	if (arena_difficulty % 6) == 0:
		number_to_spawn += 1


func initialize_enemy_properties(enemy: Node2D, is_random: bool = true):
	"""
	初始化敌人属性
	只使用区域污染度倍率，不再考虑 arena_difficulty
	is_random: 是否为随机生成的敌人（用于标签）
	"""
	var properties = {}
	var multiplier = calculate_enemy_property_multiplier()
	
	# 根据敌人类型计算基础属性
	if enemy is BasicEnemy:
		var base_health = 20.0
		properties["max_health"] = base_health * multiplier
	elif enemy is WizardEnemy:
		var base_health = 15.0
		properties["max_health"] = base_health * multiplier
	
	# 应用倍率到其他属性（如果需要）
	# properties["base_damage"] = 1.0 * multiplier
	
	# 调用敌人的初始化方法
	if enemy.has_method("initialize_enemy"):
		enemy.initialize_enemy(properties)
	
	# 添加标签
	if is_random:
		enemy.add_to_group(GROUP_RANDOM_ENEMY)
	else:
		enemy.add_to_group(GROUP_FIXED_ENEMY)
	
	# TODO: 设置精英/BOSS标签（根据scale判断）
	# 使用 get() 检查属性是否存在（不存在返回 null）
	if enemy.get("is_elite") != null and enemy.get("is_boss") != null:
		# BOSS判断：scale >= 4.0 或 is_in_group("fixed_enemy")且scale较大
		if enemy.scale.x >= 4.0 or (enemy.is_in_group(GROUP_FIXED_ENEMY) and enemy.scale.x >= 3.0):
			enemy.is_boss = true
		# 精英判断：scale >= 2.0 且 < 4.0
		elif enemy.scale.x >= 2.0 and enemy.scale.x < 4.0:
			enemy.is_elite = true
	
	# 如果是随机生成的敌人，追踪其死亡
	if is_random:
		track_enemy_spawned(enemy)


# ========== 区域系统相关方法 ==========

func set_current_region(region_type: int):
	"""设置当前区域类型"""
	current_region_type = region_type


func calculate_point_pollution() -> float:
	"""根据当前区域计算点污染度"""
	var global_pollution = GameManager.pollution
	
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return 1000.0 + global_pollution
		RegionType.REGION_TYPE_2:
			var player = get_tree().get_first_node_in_group("player") as Node2D
			if player:
				var distance = player.global_position.distance_to(map_center)
				return 1000.0 + global_pollution + distance
			return 1000.0 + global_pollution
		RegionType.REGION_TYPE_3:
			return 3000.0 + global_pollution
		_:
			return 0.0


func calculate_max_random_enemies() -> int:
	"""根据点污染度计算随机生成上限"""
	var point_pollution = calculate_point_pollution()
	
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return int(9 + point_pollution / 1000.0)
		RegionType.REGION_TYPE_2:
			return int(10 + point_pollution / 500.0)
		RegionType.REGION_TYPE_3:
			return 10  # 固定值
		_:
			return 0


func calculate_enemy_property_multiplier() -> float:
	"""根据点污染度计算属性倍率"""
	var point_pollution = calculate_point_pollution()
	print(point_pollution)
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return 1.0 + point_pollution / 10000.0
		RegionType.REGION_TYPE_2, RegionType.REGION_TYPE_3:
			return 1.1 + point_pollution / 10000.0
		_:
			return 1.0


# ========== 敌人生成方法 ==========

func spawn_random_enemy():
	"""生成一个随机敌人"""
	var enemy_scene = enemy_table.pick_item()
	var enemy = enemy_scene.instantiate() as Node2D
	
	var entities_layer = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.add_child(enemy)
	enemy.global_position = get_spawn_position()
	
	initialize_enemy_properties(enemy, true)


func spawn_region3_group():
	"""Region3 特殊生成：一次性生成 basic、basic、wizard 三人组"""
	var base_position = get_spawn_position()
	var group_offset_radius = 50.0  # 三人组之间的偏移半径
	
	var entities_layer = get_tree().get_first_node_in_group("entities_layer")
	
	# 生成第一个 basic
	var enemy1 = basic_enemy_scene.instantiate() as BasicEnemy
	entities_layer.add_child(enemy1)
	enemy1.global_position = base_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * group_offset_radius
	initialize_enemy_properties(enemy1, true)
	
	# 生成第二个 basic
	var enemy2 = basic_enemy_scene.instantiate() as BasicEnemy
	entities_layer.add_child(enemy2)
	enemy2.global_position = base_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * group_offset_radius
	initialize_enemy_properties(enemy2, true)
	
	# 生成 wizard
	var enemy3 = wizard_enemy_scene.instantiate() as WizardEnemy
	entities_layer.add_child(enemy3)
	enemy3.global_position = base_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * group_offset_radius
	initialize_enemy_properties(enemy3, true)


func spawn_boss():
	"""在 Region3 生成 BOSS"""
	if boss_spawned:
		return
	
	boss_spawned = true
	var boss = wizard_enemy_scene.instantiate() as WizardEnemy
	
	var entities_layer = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.call_deferred("add_child", boss)
	boss.global_position = map_center
	
	# 计算属性倍率（包含区域污染度倍率）
	var region_multiplier = calculate_enemy_property_multiplier()
	var boss_multiplier = 10.0  # BOSS 基础倍率
	var final_multiplier = boss_multiplier * region_multiplier  # BOSS 也会受到区域污染度倍率影响
	
	var properties = {
		"max_health": 15.0 * final_multiplier,  # WizardEnemy 基础生命值
		"base_damage": 1 * region_multiplier,
		# 其他属性也可以乘以 final_multiplier
	}
	
	# 调用敌人的初始化方法
	if boss.has_method("initialize_enemy"):
		boss.initialize_enemy(properties)
	
	# BOSS 是固定生成的，不计入随机生成数量
	boss.add_to_group(GROUP_FIXED_ENEMY)
	
	# 设置体型 scale 翻四倍
	boss.scale = Vector2(4.0, 4.0)
	
	# 设置BOSS标记（用于地雷·AT等判定）
	boss.is_boss = true
	
	# 追踪 BOSS 死亡（用于清理）
	if boss.has_node("HealthComponent"):
		var health_component = boss.get_node("HealthComponent")
		health_component.died.connect(_on_boss_died.bind(boss))


# ========== 敌人追踪方法 ==========

func track_enemy_spawned(enemy: Node2D):
	"""追踪随机生成的敌人生成"""
	if enemy.is_in_group(GROUP_RANDOM_ENEMY):
		random_enemy_count += 1
		tracked_enemies.append(enemy)
		
		# 连接死亡信号
		if enemy.has_node("HealthComponent"):
			var health_component = enemy.get_node("HealthComponent")
			health_component.died.connect(_on_random_enemy_died.bind(enemy))


func _on_random_enemy_died(enemy: Node2D):
	"""随机生成的敌人死亡回调"""
	if enemy in tracked_enemies:
		tracked_enemies.erase(enemy)
		random_enemy_count = max(0, random_enemy_count - 1)


func _on_boss_died(boss: Node2D):
	"""BOSS 死亡回调（如果需要特殊处理）"""
	pass
