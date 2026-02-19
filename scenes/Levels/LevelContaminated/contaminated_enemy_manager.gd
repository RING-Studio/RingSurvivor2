extends Node
## 污染带关卡敌人管理器 — 大型场地、高密度、双区域

const SPAWN_RADIUS: int = 1100  # 大型关卡（19200×10800）生成半径

# 敌人场景
var sand_scarab_scene: PackedScene = preload("res://scenes/game_object/sand_scarab/sand_scarab.tscn")
var spore_caster_scene: PackedScene = preload("res://scenes/game_object/spore_caster/spore_caster.tscn")
var dune_beetle_scene: PackedScene = preload("res://scenes/game_object/charger_enemy/charger_enemy.tscn")
var bloat_tick_scene: PackedScene = preload("res://scenes/game_object/bomber_enemy/bomber_enemy.tscn")
var rust_hulk_scene: PackedScene = preload("res://scenes/game_object/tank_enemy/tank_enemy.tscn")
var acid_spitter_scene: PackedScene = preload("res://scenes/game_object/spitter_enemy/spitter_enemy.tscn")

var boss_titan_scene: PackedScene = preload("res://scenes/game_object/boss_titan/boss_titan.tscn")
var boss_hive_scene: PackedScene = preload("res://scenes/game_object/boss_hive/boss_hive.tscn")

@export var arena_time_manager: Node
@export var map_center: Vector2 = Vector2(9600, 5400)  # 大型地图中心（19200×10800）

@onready var timer: Timer = $Timer

var base_spawn_time: float = 0.0
var enemy_table: WeightedTable = WeightedTable.new()
var number_to_spawn: int = 1

enum RegionType { NONE = 0, REGION_TYPE_1 = 1, REGION_TYPE_2 = 2, REGION_TYPE_3 = 3 }
const GROUP_RANDOM_ENEMY: String = "random_enemy"
const GROUP_FIXED_ENEMY: String = "fixed_enemy"

var current_region_type: int = RegionType.NONE
var random_enemy_count: int = 0
var boss_spawned: bool = false
var tracked_enemies: Array[Node2D] = []
var mission_difficulty: int = 1


func get_difficulty_hp_multiplier() -> float:
	match mission_difficulty:
		1: return 1.0
		2: return 1.2
		3: return 1.5
		4: return 1.8
		5: return 2.2
		_: return 1.0

func get_difficulty_spawn_bonus() -> int:
	return max(0, (mission_difficulty - 1) * 2)

func get_difficulty_elite_chance() -> float:
	# 污染带精英概率偏高
	match mission_difficulty:
		1: return 0.15
		2: return 0.18
		3: return 0.24
		4: return 0.30
		5: return 0.36
		_: return 0.15


func _ready() -> void:
	var mission: Dictionary = MissionData.get_mission(GameManager.current_mission_id)
	mission_difficulty = int(mission.get("difficulty", 1))

	# 污染带权重：更多危险敌人
	enemy_table.add_item(sand_scarab_scene, 3)
	enemy_table.add_item(spore_caster_scene, 2)
	enemy_table.add_item(dune_beetle_scene, 2)
	enemy_table.add_item(bloat_tick_scene, 2)
	enemy_table.add_item(rust_hulk_scene, 2)
	enemy_table.add_item(acid_spitter_scene, 2)

	base_spawn_time = timer.wait_time
	timer.timeout.connect(_on_timer_timeout)
	if arena_time_manager:
		arena_time_manager.arena_difficulty_increased.connect(_on_arena_difficulty_increased)

	if mission_difficulty >= 3:
		var speed_factor: float = 1.0 - 0.06 * float(mission_difficulty - 2)
		timer.wait_time = max(base_spawn_time * speed_factor, 0.25)
		base_spawn_time = timer.wait_time


func get_spawn_position() -> Vector2:
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return map_center
	var spawn_position: Vector2 = Vector2.ZERO
	var random_direction: Vector2 = Vector2.RIGHT.rotated(randf_range(0, TAU))
	for i in 4:
		spawn_position = player.global_position + (random_direction * SPAWN_RADIUS)
		var additional_check_offset: Vector2 = random_direction * 20
		var query: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
			player.global_position, spawn_position + additional_check_offset, 1)
		var result: Dictionary = get_tree().root.world_2d.direct_space_state.intersect_ray(query)
		if result.is_empty():
			break
		else:
			random_direction = random_direction.rotated(deg_to_rad(90))
	return spawn_position


func _on_timer_timeout() -> void:
	timer.start()
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if current_region_type == RegionType.NONE:
		return
	var max_enemies: int = calculate_max_random_enemies()
	if random_enemy_count >= max_enemies:
		return
	for i in number_to_spawn:
		if random_enemy_count >= max_enemies:
			break
		spawn_random_enemy()


func _on_arena_difficulty_increased(arena_difficulty: int) -> void:
	var time_off: float = (.1 / 12) * arena_difficulty
	time_off = min(time_off, .7)
	timer.wait_time = base_spawn_time - time_off
	if (arena_difficulty % 5) == 0:
		number_to_spawn += 1

	# 精英波事件：每隔一段时间触发一波精英（污染带更频繁）
	if (arena_difficulty % 8) == 0 and arena_difficulty > 0:
		_spawn_elite_wave(3 + arena_difficulty / 8)


func set_current_region(region_type: int) -> void:
	current_region_type = region_type


func calculate_point_pollution() -> float:
	var global_pollution: int = GameManager.pollution
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return 1200.0 + global_pollution
		RegionType.REGION_TYPE_2:
			# 核心区更高污染
			return 2000.0 + global_pollution
		_:
			return 0.0


func calculate_max_random_enemies() -> int:
	var point_pollution: float = calculate_point_pollution()
	var bonus: int = get_difficulty_spawn_bonus()
	# 大型关卡（19200×10800）：提升上限，确保大地图不空旷
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return int(20 + point_pollution / 500.0) + bonus
		RegionType.REGION_TYPE_2:
			return int(26 + point_pollution / 350.0) + bonus
		_:
			return 0


func calculate_enemy_property_multiplier() -> float:
	var point_pollution: float = calculate_point_pollution()
	match current_region_type:
		RegionType.REGION_TYPE_1:
			return 1.1 + point_pollution / 800.0
		RegionType.REGION_TYPE_2:
			return 1.3 + point_pollution / 500.0
		_:
			return 1.0


func initialize_enemy_properties(enemy: Node2D, is_random: bool = true) -> void:
	var properties: Dictionary = {}
	var multiplier: float = calculate_enemy_property_multiplier()
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
	properties["max_health"] = base_health * multiplier * get_difficulty_hp_multiplier()
	if enemy.has_method("initialize_enemy"):
		enemy.initialize_enemy(properties)
	if is_random:
		enemy.add_to_group(GROUP_RANDOM_ENEMY)
		_track_enemy(enemy)
	else:
		enemy.add_to_group(GROUP_FIXED_ENEMY)


func spawn_random_enemy() -> void:
	var enemy_scene: PackedScene = enemy_table.pick_item()
	var enemy: Node2D = enemy_scene.instantiate() as Node2D
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.add_child(enemy)
	enemy.global_position = get_spawn_position()

	var is_elite_spawn: bool = randf() < get_difficulty_elite_chance()
	if is_elite_spawn:
		enemy.scale = Vector2(1.5, 1.5)
		if enemy.get("enemy_rank") != null:
			enemy.enemy_rank = 1

	initialize_enemy_properties(enemy, true)

	if is_elite_spawn:
		if enemy.has_node("HealthComponent"):
			var hc: Node = enemy.get_node("HealthComponent")
			hc.max_health *= 3.0
			hc.current_health = hc.max_health
		if enemy.has_node("VialDropComponent"):
			enemy.get_node("VialDropComponent").drop_percent = 1.0


func spawn_boss(boss_id: String = "boss_titan") -> void:
	# 污染带暂无 Boss，保留接口
	pass


func _spawn_elite_wave(count: int) -> void:
	"""生成一波精英敌人"""
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if entities_layer == null:
		return
	print("[ContaminatedEM] 精英波! 数量=%d" % count)
	for i in count:
		var enemy_scene: PackedScene = enemy_table.pick_item()
		var enemy: Node2D = enemy_scene.instantiate() as Node2D
		entities_layer.add_child(enemy)
		var angle: float = randf_range(0, TAU)
		enemy.global_position = player.global_position + Vector2.RIGHT.rotated(angle) * (SPAWN_RADIUS * 0.8)
		# 强制精英
		enemy.scale = Vector2(1.5, 1.5)
		if enemy.get("enemy_rank") != null:
			enemy.enemy_rank = 1
		initialize_enemy_properties(enemy, true)
		if enemy.has_node("HealthComponent"):
			var hc: Node = enemy.get_node("HealthComponent")
			hc.max_health *= 3.0
			hc.current_health = hc.max_health
		if enemy.has_node("VialDropComponent"):
			enemy.get_node("VialDropComponent").drop_percent = 1.0


func _track_enemy(enemy: Node2D) -> void:
	random_enemy_count += 1
	tracked_enemies.append(enemy)
	if enemy.has_node("HealthComponent"):
		var hc: Node = enemy.get_node("HealthComponent")
		hc.died.connect(_on_random_enemy_died.bind(enemy))


func _on_random_enemy_died(enemy: Node2D) -> void:
	if enemy in tracked_enemies:
		tracked_enemies.erase(enemy)
		random_enemy_count = max(0, random_enemy_count - 1)
	var level_script: Node = get_parent()
	if level_script and level_script.has_method("notify_enemy_killed"):
		level_script.notify_enemy_killed(enemy)
