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

# 敌人场景 — 全部使用新设计的沙漠/污染主题敌人
var sand_scarab_scene: PackedScene = preload("res://scenes/game_object/sand_scarab/sand_scarab.tscn")
var spore_caster_scene: PackedScene = preload("res://scenes/game_object/spore_caster/spore_caster.tscn")
var dune_beetle_scene: PackedScene = preload("res://scenes/game_object/charger_enemy/charger_enemy.tscn")
var bloat_tick_scene: PackedScene = preload("res://scenes/game_object/bomber_enemy/bomber_enemy.tscn")
var rust_hulk_scene: PackedScene = preload("res://scenes/game_object/tank_enemy/tank_enemy.tscn")
var acid_spitter_scene: PackedScene = preload("res://scenes/game_object/spitter_enemy/spitter_enemy.tscn")

# Boss 场景
var boss_titan_scene: PackedScene = preload("res://scenes/game_object/boss_titan/boss_titan.tscn")
var boss_hive_scene: PackedScene = preload("res://scenes/game_object/boss_hive/boss_hive.tscn")

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

# ========== 关卡难度系数（从 MissionData.difficulty 读取）==========
# difficulty 1~5 → 不同缩放
var mission_difficulty: int = 1

## 难度对应的属性倍率加成（叠加在区域倍率之上）
func get_difficulty_hp_multiplier() -> float:
	# difficulty 1=1.0, 2=1.2, 3=1.5, 4=1.8, 5=2.2
	match mission_difficulty:
		1: return 1.0
		2: return 1.2
		3: return 1.5
		4: return 1.8
		5: return 2.2
		_: return 1.0

## 难度对应的生成上限加成
func get_difficulty_spawn_bonus() -> int:
	# difficulty 1=0, 2=+2, 3=+4, 4=+6, 5=+8
	return max(0, (mission_difficulty - 1) * 2)

## 难度对应的精英生成概率
func get_difficulty_elite_chance() -> float:
	# difficulty 1=12%, 2=15%, 3=20%, 4=25%, 5=30%
	match mission_difficulty:
		1: return 0.12
		2: return 0.15
		3: return 0.20
		4: return 0.25
		5: return 0.30
		_: return 0.12


func _ready():
	# 读取关卡难度
	var mission: Dictionary = MissionData.get_mission(GameManager.current_mission_id)
	mission_difficulty = int(mission.get("difficulty", 1))

	# 权重：圣甲虫(基础近战)4, 孢子投手(远程)2, 沙丘甲虫(冲锋)2, 膨爆蜱(自爆)1, 锈壳重甲(重装)1, 酸液射手(远程)1
	enemy_table.add_item(sand_scarab_scene, 4)
	enemy_table.add_item(spore_caster_scene, 2)
	enemy_table.add_item(dune_beetle_scene, 2)
	enemy_table.add_item(bloat_tick_scene, 1)
	enemy_table.add_item(rust_hulk_scene, 1)
	enemy_table.add_item(acid_spitter_scene, 1)

	base_spawn_time = timer.wait_time
	timer.timeout.connect(on_timer_timeout)
	arena_time_manager.arena_difficulty_increased.connect(on_arena_difficulty_increased)
	
	# 难度缩放：高难度缩短生成间隔
	if mission_difficulty >= 3:
		var speed_factor: float = 1.0 - 0.05 * float(mission_difficulty - 2)
		timer.wait_time = max(base_spawn_time * speed_factor, 0.3)
		base_spawn_time = timer.wait_time


func get_spawn_position():
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		print("what")
		return Vector2.ZERO
	
	var spawn_position: Vector2 = Vector2.ZERO
	var random_direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
		var additional_check_offset: Vector2 = random_direction * 20

		var query_paramaters: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(player.global_position, spawn_position + additional_check_offset, 1)
		var result: Dictionary = get_tree().root.world_2d.direct_space_state.intersect_ray(query_paramaters)

		if result.is_empty():
			break
		else:
			random_direction = random_direction.rotated(deg_to_rad(90))
	
	return spawn_position


func on_timer_timeout():
	timer.start()
	
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	# 检查是否在有效区域
	if current_region_type == RegionType.NONE:
		return
	
	# 检查随机生成上限
	var max_random_enemies: int = calculate_max_random_enemies()
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
	var time_off: float = (.1 / 12) * arena_difficulty
	time_off = min(time_off, .7)
	timer.wait_time = base_spawn_time - time_off
	
	if (arena_difficulty % 6) == 0:
		number_to_spawn += 1


func initialize_enemy_properties(enemy: Node2D, is_random: bool = true):
	"""
	初始化敌人属性
	只使用区域污染度倍率，不再考虑 arena_difficulty
	is_random: 是否为随机生成的敌人（用于标签）
	"""
	var properties: Dictionary = {}
	var multiplier: float = calculate_enemy_property_multiplier()
	
	# 根据敌人类型计算基础属性
	var base_health: float = 20.0
	if enemy is SandScarab:
		base_health = 20.0
	elif enemy is SporeCaster:
		base_health = 15.0
	elif enemy is DuneBeetle:
		base_health = 12.0
	elif enemy is BloatTick:
		base_health = 8.0
	elif enemy is RustHulk:
		base_health = 40.0
	elif enemy is AcidSpitter:
		base_health = 18.0
	elif enemy is BossTitan:
		base_health = 500.0
	elif enemy is BossHive:
		base_health = 350.0
	properties["max_health"] = base_health * multiplier * get_difficulty_hp_multiplier()
	
	# 调用敌人的初始化方法
	if enemy.has_method("initialize_enemy"):
		enemy.initialize_enemy(properties)
	
	# 添加标签
	if is_random:
		enemy.add_to_group(GROUP_RANDOM_ENEMY)
	else:
		enemy.add_to_group(GROUP_FIXED_ENEMY)
	
	# 如果是随机生成的敌人，追踪其死亡
	if is_random:
		track_enemy_spawned(enemy)


# ========== 区域系统相关方法 ==========

func set_current_region(region_type: int):
	"""设置当前区域类型"""
	current_region_type = region_type


func calculate_point_pollution() -> float:
	"""根据当前区域计算点污染度"""
	var global_pollution: int = GameManager.pollution
	
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return 1000.0 + global_pollution
		RegionType.REGION_TYPE_2:
			var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
			if player:
				var distance: float = player.global_position.distance_to(map_center)
				return 1000.0 + global_pollution + distance
			return 1000.0 + global_pollution
		RegionType.REGION_TYPE_3:
			return 3000.0 + global_pollution
		_:
			return 0.0


func calculate_max_random_enemies() -> int:
	"""根据点污染度和难度计算随机生成上限"""
	var point_pollution: float = calculate_point_pollution()
	var bonus: int = get_difficulty_spawn_bonus()
	
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return int(9 + point_pollution / 1000.0) + bonus
		RegionType.REGION_TYPE_2:
			return int(10 + point_pollution / 500.0) + bonus
		RegionType.REGION_TYPE_3:
			return 10 + bonus
		_:
			return 0


func calculate_enemy_property_multiplier() -> float:
	"""根据点污染度计算属性倍率（与 关卡.md 一致）"""
	var point_pollution: float = calculate_point_pollution()
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return 1.0 + point_pollution / 1000.0
		RegionType.REGION_TYPE_2, RegionType.REGION_TYPE_3:
			return 1.1 + point_pollution / 500.0
		_:
			return 1.0


# ========== 敌人生成方法 ==========

# 精英生成概率（随机敌人生成时）
const ELITE_SPAWN_CHANCE: float = 0.12  # 12% 概率生成精英

func spawn_random_enemy():
	"""生成一个随机敌人"""
	var enemy_scene: PackedScene = enemy_table.pick_item()
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.add_child(enemy)
	enemy.global_position = get_spawn_position()
	
	# 精英标记：按难度调整后的概率生成精英
	var is_elite_spawn: bool = randf() < get_difficulty_elite_chance()
	if is_elite_spawn:
		enemy.scale = Vector2(1.5, 1.5)
		# 通过 enemy_rank 枚举标记（值 1 = ELITE）
		if enemy.get("enemy_rank") != null:
			enemy.enemy_rank = 1  # ELITE
	
	initialize_enemy_properties(enemy, true)
	
	# 精英属性增幅
	if is_elite_spawn:
		# HP × 3, 药瓶必掉
		if enemy.has_node("HealthComponent"):
			var hc: Node = enemy.get_node("HealthComponent")
			hc.max_health *= 3.0
			hc.current_health = hc.max_health
		if enemy.has_node("VialDropComponent"):
			enemy.get_node("VialDropComponent").drop_percent = 1.0


func spawn_region3_group():
	"""Region3 特殊生成：一次性生成 圣甲虫x2 + 孢子投手x1 三体组"""
	var base_position: Vector2 = get_spawn_position()
	var group_offset_radius: float = 50.0  # 三体组之间的偏移半径
	
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	
	# 生成第一个圣甲虫
	var enemy1: Node2D = sand_scarab_scene.instantiate() as Node2D
	entities_layer.add_child(enemy1)
	enemy1.global_position = base_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * group_offset_radius
	initialize_enemy_properties(enemy1, true)
	
	# 生成第二个圣甲虫
	var enemy2: Node2D = sand_scarab_scene.instantiate() as Node2D
	entities_layer.add_child(enemy2)
	enemy2.global_position = base_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * group_offset_radius
	initialize_enemy_properties(enemy2, true)
	
	# 生成孢子投手
	var enemy3: Node2D = spore_caster_scene.instantiate() as Node2D
	entities_layer.add_child(enemy3)
	enemy3.global_position = base_position + Vector2.RIGHT.rotated(randf_range(0, TAU)) * group_offset_radius
	initialize_enemy_properties(enemy3, true)


func spawn_boss(boss_id: String = "boss_titan"):
	"""在 Region3 生成 BOSS。boss_id: "boss_titan" 或 "boss_hive" """
	if boss_spawned:
		return
	
	boss_spawned = true

	# 选择 Boss 场景
	var boss_scene: PackedScene = boss_titan_scene
	var base_hp: float = 500.0
	if boss_id == "boss_hive":
		boss_scene = boss_hive_scene
		base_hp = 350.0
	
	var boss: Node2D = boss_scene.instantiate() as Node2D
	
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.call_deferred("add_child", boss)
	boss.global_position = map_center
	
	# 计算属性倍率（包含区域污染度倍率 + 关卡难度）
	var region_multiplier: float = calculate_enemy_property_multiplier()
	var boss_multiplier: float = 3.0  # Boss 倍率（.tscn 已配置基础 HP，此处为难度缩放）
	var final_multiplier: float = boss_multiplier * region_multiplier * get_difficulty_hp_multiplier()
	
	var properties: Dictionary = {
		"max_health": base_hp * final_multiplier,
	}
	
	# 调用敌人的初始化方法
	if boss.has_method("initialize_enemy"):
		boss.initialize_enemy(properties)
	
	# BOSS 是固定生成的，不计入随机生成数量
	boss.add_to_group(GROUP_FIXED_ENEMY)
	
	# enemy_rank 已在 Boss 脚本中默认为 BOSS(2)，无需额外设置
	
	# 追踪 BOSS 死亡（用于清理）
	if boss.has_node("HealthComponent"):
		var health_component: Node = boss.get_node("HealthComponent")
		health_component.died.connect(_on_boss_died.bind(boss))


# ========== 敌人追踪方法 ==========

func track_enemy_spawned(enemy: Node2D):
	"""追踪随机生成的敌人生成"""
	if enemy.is_in_group(GROUP_RANDOM_ENEMY):
		random_enemy_count += 1
		tracked_enemies.append(enemy)
		
		# 连接死亡信号
		if enemy.has_node("HealthComponent"):
			var health_component: Node = enemy.get_node("HealthComponent")
			health_component.died.connect(_on_random_enemy_died.bind(enemy))


func _on_random_enemy_died(enemy: Node2D):
	"""随机生成的敌人死亡回调"""
	if enemy in tracked_enemies:
		tracked_enemies.erase(enemy)
		random_enemy_count = max(0, random_enemy_count - 1)
	# 通知关卡脚本（用于目标追踪）
	_notify_level_kill(enemy)


func _on_boss_died(boss: Node2D):
	"""BOSS 死亡回调"""
	_notify_level_kill(boss)


func _notify_level_kill(enemy: Node2D) -> void:
	"""通知关卡脚本有敌人被击杀"""
	var level_script: Node = get_parent()
	if level_script and level_script.has_method("notify_enemy_killed"):
		level_script.notify_enemy_killed(enemy)
