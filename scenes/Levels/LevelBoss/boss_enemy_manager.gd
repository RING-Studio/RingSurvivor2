extends Node
## Boss 关卡敌人管理器 — 中型场地、Boss 战专用
## 分两阶段：接近阶段（低密度小怪）+ Boss 战阶段（Boss + 小怪浪）

const SPAWN_RADIUS: int = 800

enum RegionType { NONE = 0, REGION_TYPE_1 = 1, REGION_TYPE_2 = 2, REGION_TYPE_3 = 3 }
const GROUP_RANDOM_ENEMY: String = "random_enemy"
const GROUP_FIXED_ENEMY: String = "fixed_enemy"

var sand_scarab_scene: PackedScene = preload("res://scenes/game_object/sand_scarab/sand_scarab.tscn")
var spore_caster_scene: PackedScene = preload("res://scenes/game_object/spore_caster/spore_caster.tscn")
var dune_beetle_scene: PackedScene = preload("res://scenes/game_object/charger_enemy/charger_enemy.tscn")
var bloat_tick_scene: PackedScene = preload("res://scenes/game_object/bomber_enemy/bomber_enemy.tscn")
var rust_hulk_scene: PackedScene = preload("res://scenes/game_object/tank_enemy/tank_enemy.tscn")
var acid_spitter_scene: PackedScene = preload("res://scenes/game_object/spitter_enemy/spitter_enemy.tscn")
var boss_titan_scene: PackedScene = preload("res://scenes/game_object/boss_titan/boss_titan.tscn")
var boss_hive_scene: PackedScene = preload("res://scenes/game_object/boss_hive/boss_hive.tscn")

@export var arena_time_manager: Node
@export var map_center: Vector2 = Vector2(4800, 2700)

@onready var timer: Timer = $Timer

var base_spawn_time: float = 0.0
var enemy_table: WeightedTable = WeightedTable.new()
var boss_phase_enemy_table: WeightedTable = WeightedTable.new()
var number_to_spawn: int = 1

var current_region_type: int = RegionType.NONE
var random_enemy_count: int = 0
var boss_spawned: bool = false
var in_boss_phase: bool = false
var tracked_enemies: Array[Node2D] = []
var mission_difficulty: int = 1
var _current_mission_id: String = ""

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
	match mission_difficulty:
		1: return 0.12
		2: return 0.15
		3: return 0.20
		4: return 0.25
		5: return 0.30
		_: return 0.12


func _ready() -> void:
	var mission: Dictionary = MissionData.get_mission(GameManager.current_mission_id)
	mission_difficulty = int(mission.get("difficulty", 1))
	_current_mission_id = GameManager.current_mission_id

	# 接近阶段权重（通用）
	enemy_table.add_item(sand_scarab_scene, 4)
	enemy_table.add_item(spore_caster_scene, 2)
	enemy_table.add_item(dune_beetle_scene, 2)
	enemy_table.add_item(rust_hulk_scene, 1)
	enemy_table.add_item(acid_spitter_scene, 1)

	# Boss 战阶段权重（根据任务不同调整）
	match _current_mission_id:
		"hive_assault":
			# 蜂巢战：大量膨爆蜱 + 孢子投手
			boss_phase_enemy_table.add_item(bloat_tick_scene, 6)
			boss_phase_enemy_table.add_item(spore_caster_scene, 2)
			boss_phase_enemy_table.add_item(sand_scarab_scene, 2)
		"titan_hunt":
			# 巨兽战：重甲 + 甲虫 + 冲锋
			boss_phase_enemy_table.add_item(sand_scarab_scene, 3)
			boss_phase_enemy_table.add_item(rust_hulk_scene, 3)
			boss_phase_enemy_table.add_item(dune_beetle_scene, 2)
			boss_phase_enemy_table.add_item(acid_spitter_scene, 2)
		_:
			boss_phase_enemy_table.add_item(sand_scarab_scene, 3)
			boss_phase_enemy_table.add_item(bloat_tick_scene, 2)
			boss_phase_enemy_table.add_item(rust_hulk_scene, 2)

	base_spawn_time = timer.wait_time
	timer.timeout.connect(_on_timer_timeout)
	if arena_time_manager:
		arena_time_manager.arena_difficulty_increased.connect(_on_arena_difficulty_increased)

	if mission_difficulty >= 3:
		var speed_factor: float = 1.0 - 0.05 * float(mission_difficulty - 2)
		timer.wait_time = max(base_spawn_time * speed_factor, 0.3)
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

	var table: WeightedTable = boss_phase_enemy_table if in_boss_phase else enemy_table
	for i in number_to_spawn:
		if random_enemy_count >= max_enemies:
			break
		_spawn_from_table(table)


func _on_arena_difficulty_increased(arena_difficulty: int) -> void:
	var time_off: float = (.1 / 12) * arena_difficulty
	time_off = min(time_off, .7)
	timer.wait_time = base_spawn_time - time_off
	if (arena_difficulty % 6) == 0:
		number_to_spawn += 1


func set_current_region(region_type: int) -> void:
	current_region_type = region_type


func enter_boss_phase() -> void:
	"""进入 Boss 战阶段：切换敌人组成、加速生成"""
	in_boss_phase = true
	timer.wait_time = max(base_spawn_time * 0.7, 0.3)
	number_to_spawn = max(number_to_spawn, 2)


func calculate_point_pollution() -> float:
	var global_pollution: int = GameManager.pollution
	if in_boss_phase:
		return 2000.0 + global_pollution
	return 1000.0 + global_pollution


func calculate_max_random_enemies() -> int:
	var bonus: int = get_difficulty_spawn_bonus()
	if in_boss_phase:
		return 12 + bonus
	return 8 + bonus


func calculate_enemy_property_multiplier() -> float:
	var point_pollution: float = calculate_point_pollution()
	if in_boss_phase:
		return 1.1 + point_pollution / 500.0
	return 1.0 + point_pollution / 1000.0


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
	elif enemy is BossTitan:
		base_health = 500.0
	elif enemy is BossHive:
		base_health = 350.0
	properties["max_health"] = base_health * multiplier * get_difficulty_hp_multiplier()
	if enemy.has_method("initialize_enemy"):
		enemy.initialize_enemy(properties)
	if is_random:
		enemy.add_to_group(GROUP_RANDOM_ENEMY)
		_track_enemy(enemy)
	else:
		enemy.add_to_group(GROUP_FIXED_ENEMY)


func _spawn_from_table(table: WeightedTable) -> void:
	var enemy_scene: PackedScene = table.pick_item()
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

func spawn_random_enemy() -> void:
	_spawn_from_table(enemy_table)


func spawn_boss(boss_id: String = "boss_titan") -> void:
	if boss_spawned:
		return
	boss_spawned = true
	enter_boss_phase()

	var boss_scene: PackedScene = boss_titan_scene
	var base_hp: float = 500.0
	if boss_id == "boss_hive":
		boss_scene = boss_hive_scene
		base_hp = 350.0

	var boss: Node2D = boss_scene.instantiate() as Node2D
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	entities_layer.call_deferred("add_child", boss)
	boss.global_position = map_center

	var region_multiplier: float = calculate_enemy_property_multiplier()
	var boss_multiplier: float = 3.0
	var final_multiplier: float = boss_multiplier * region_multiplier * get_difficulty_hp_multiplier()

	var properties: Dictionary = {
		"max_health": base_hp * final_multiplier,
	}
	if boss.has_method("initialize_enemy"):
		boss.initialize_enemy(properties)
	boss.add_to_group(GROUP_FIXED_ENEMY)

	if boss.has_node("HealthComponent"):
		var health_component: Node = boss.get_node("HealthComponent")
		health_component.died.connect(_on_boss_died.bind(boss))

	print("[BossEM] Boss 已生成: %s (HP=%.0f)" % [boss_id, base_hp * final_multiplier])


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


func _on_boss_died(boss: Node2D) -> void:
	var level_script: Node = get_parent()
	if level_script and level_script.has_method("notify_enemy_killed"):
		level_script.notify_enemy_killed(boss)
