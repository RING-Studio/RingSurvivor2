extends Node

@export var end_screen_scene: PackedScene
@export var objective_manager: ObjectiveManager

var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")

# ========== 收集物系统 ==========
## 当前关卡需要掉落的收集物类型配置
## 格式: [{"type": "energy_core", "color": Color(...), "drop_chance": 0.3}]
var _collectible_drops: Array[Dictionary] = []

# ========== 防守据点 ==========
var _outpost: DefendOutpost = null


func _ready():
	GameManager.start_mission()
	$%Player.health_component.died.connect(on_player_died)
	Transitions.transition(Transitions.transition_type.Diamond, true)
	setup_region_detection()

	# 初始化升级池（根据当前装备状态）
	var upgrade_manager = get_node_or_null("UpgradeManager")
	if upgrade_manager:
		var vehicle_config: Dictionary = GameManager.get_vehicle_config(GameManager.current_vehicle)
		var main_weapon_id = vehicle_config.get("主武器类型", null)
		if main_weapon_id != null:
			upgrade_manager._add_exclusive_upgrades_for_weapon(main_weapon_id)
		upgrade_manager.start_session()

	# 配置关卡目标（由 ObjectiveManager 子节点管理）
	_setup_objectives()

	# 连接 ObjectiveManager 信号
	if objective_manager:
		objective_manager.all_primary_completed.connect(_on_victory)
		objective_manager.primary_failed.connect(_on_defeat)
		objective_manager.objective_state_changed.connect(_on_objective_changed)

	# 监听收集物拾取（全局信号）
	GameEvents.collectible_collected.connect(_on_collectible_collected)


func _setup_objectives() -> void:
	"""根据当前关卡 ID 配置目标。逻辑完全在这里定义。"""
	if not objective_manager:
		return

	var mission_id: String = GameManager.current_mission_id

	match mission_id:
		"recon_patrol":
			objective_manager.add_objective({"id": "survive_90", "display_name": "在巡逻区存活 90 秒", "primary": true, "time_limit": 90, "survive": true})
		"salvage_run":
			objective_manager.add_objective({"id": "collect_cores", "display_name": "收集 20 个能量核心", "primary": true, "target": 20})
			objective_manager.add_objective({"id": "kill_bonus", "display_name": "击杀 30 只敌人", "primary": false, "target": 30})
			# 配置收集物掉落：击杀敌人 30% 概率掉落能量核心
			_collectible_drops.append({"type": "energy_core", "color": Color(0.2, 0.8, 1.0), "drop_chance": 0.3})
		"containment":
			objective_manager.add_objective({"id": "survive_120", "display_name": "在污染区存活 120 秒", "primary": true, "time_limit": 120, "survive": true})
			objective_manager.add_objective({"id": "kill_elites", "display_name": "击杀 5 只精英敌人", "primary": false, "target": 5})
		"extermination":
			objective_manager.add_objective({"id": "kill_50", "display_name": "击杀 50 只敌人", "primary": true, "target": 50, "time_limit": 120})
		"outpost_defense":
			objective_manager.add_objective({"id": "defend_outpost", "display_name": "保护通信据点 150 秒", "primary": true, "time_limit": 150, "survive": true})
			objective_manager.add_objective({"id": "defend_no_hit", "display_name": "据点血量保持 50% 以上", "primary": false})
			# 生成据点
			_spawn_outpost()
		"titan_hunt":
			objective_manager.add_objective({"id": "reach_lair", "display_name": "前往巨兽巢穴", "primary": true})
			objective_manager.add_objective({"id": "kill_titan", "display_name": "击杀污染巨兽", "primary": true, "time_limit": 180, "after": "reach_lair"})
			objective_manager.add_objective({"id": "titan_kill_fast", "display_name": "90 秒内击杀巨兽", "primary": false, "time_limit": 90, "after": "reach_lair"})
		"hive_assault":
			objective_manager.add_objective({"id": "investigate_sources", "display_name": "调查污染源（前往区域中心）", "primary": true})
			objective_manager.add_objective({"id": "kill_hive_mother", "display_name": "击杀孵化母体", "primary": true, "time_limit": 180, "after": "investigate_sources"})
			objective_manager.add_objective({"id": "kill_bloats", "display_name": "击杀 30 只膨爆蜱", "primary": false, "target": 30})
			objective_manager.add_objective({"id": "collect_samples", "display_name": "收集 10 个生物样本", "primary": false, "target": 10})
			# 配置收集物掉落：膨爆蜱 40% 概率掉落生物样本
			_collectible_drops.append({"type": "bio_sample", "color": Color(0.6, 0.2, 0.8), "drop_chance": 0.4, "enemy_filter": "BloatTick"})
		"high_risk_sweep":
			objective_manager.add_objective({"id": "kill_80", "display_name": "击杀 80 只敌人", "primary": true, "target": 80, "time_limit": 150})
			objective_manager.add_objective({"id": "kill_10_elites", "display_name": "击杀 10 只精英敌人", "primary": false, "target": 10})
		_:
			# 自由模式 / 无配置：无限生存
			pass


func _on_victory() -> void:
	"""所有主目标达成"""
	var completed_objs: Array[String] = []
	if objective_manager:
		completed_objs = objective_manager.get_completed_secondary_ids()
	if not GameManager.apply_mission_result("victory", completed_objs):
		return
	GlobalSaveData.save_game()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_victory()
	MetaProgression.save()


func _on_defeat() -> void:
	"""任意主目标失败"""
	if not GameManager.apply_mission_result("defeat"):
		return
	GlobalSaveData.save_game()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()


func _on_objective_changed(obj_id: String, new_state: String) -> void:
	"""目标状态变化 — 处理 Boss 条件生成等"""
	if new_state == "active":
		_try_spawn_boss_for_objective(obj_id)


func _try_spawn_boss_for_objective(obj_id: String) -> void:
	"""如果刚激活的是 boss 目标且玩家已在 Region3，立即生成 Boss"""
	var boss_id: String = ""
	if obj_id == "kill_titan":
		boss_id = "boss_titan"
	elif obj_id == "kill_hive_mother":
		boss_id = "boss_hive"
	else:
		return

	var enemy_manager = $EnemyManager
	if enemy_manager.boss_spawned:
		return

	# 检查玩家是否在 Region3
	var region3: Area2D = $Regions.get_node_or_null("Region3") as Area2D
	if region3:
		for body in region3.get_overlapping_bodies():
			if body.is_in_group("player"):
				enemy_manager.spawn_boss(boss_id)
				return


# ========== 外部通知接口（由 EnemyManager 调用） ==========

func notify_enemy_killed(enemy: Node2D) -> void:
	"""敌人被击杀"""
	# 尝试掉落收集物（即使目标已完成也掉落，增加掉落感）
	notify_enemy_killed_drop(enemy)

	if not objective_manager or objective_manager.is_finished():
		return

	var is_elite: bool = false
	var is_boss: bool = false
	var enemy_class: String = ""

	if enemy:
		var script: GDScript = enemy.get_script() as GDScript
		if script:
			enemy_class = script.get_global_name()
		if enemy.get("enemy_rank") != null:
			var rank: int = int(enemy.enemy_rank)
			is_elite = rank >= 1
			is_boss = rank >= 2

	# 通用击杀计数
	for obj in objective_manager.get_all_objectives():
		var oid: String = obj["id"]
		if obj["state"] != "active" or obj["target"] <= 0:
			continue

		# 根据 objective id 判断过滤
		if oid in ["kill_bonus", "kill_50", "kill_80"]:
			objective_manager.report_progress(oid)
		elif oid == "kill_elites" or oid == "kill_10_elites":
			if is_elite:
				objective_manager.report_progress(oid)
		elif oid == "kill_bloats":
			if enemy_class == "BloatTick":
				objective_manager.report_progress(oid)

	# Boss 击杀
	if is_boss:
		if objective_manager.is_active("kill_titan") and enemy_class == "BossTitan":
			objective_manager.report_complete("kill_titan")
			# 同时检查快速击杀
			if objective_manager.is_active("titan_kill_fast"):
				objective_manager.report_complete("titan_kill_fast")
		if objective_manager.is_active("kill_hive_mother") and enemy_class == "BossHive":
			objective_manager.report_complete("kill_hive_mother")


func notify_enemy_killed_drop(enemy: Node2D) -> void:
	"""敌人死亡时尝试掉落收集物"""
	if _collectible_drops.is_empty():
		return
	if not is_instance_valid(enemy) or not (enemy is Node2D):
		return

	var enemy_class: String = ""
	var script: GDScript = enemy.get_script() as GDScript
	if script:
		enemy_class = script.get_global_name()

	for config in _collectible_drops:
		# 敌人过滤
		var filter: String = str(config.get("enemy_filter", ""))
		if not filter.is_empty() and enemy_class != filter:
			continue
		# 概率判定
		if randf() > float(config.get("drop_chance", 0.0)):
			continue
		# 生成收集物
		var type: String = str(config.get("type", ""))
		var color: Color = config.get("color", Color.WHITE)
		var offset: Vector2 = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		Collectible.spawn_at(enemy.global_position + offset, type, color, get_tree())


func _on_collectible_collected(collectible_type: String) -> void:
	"""全局收集物拾取回调 — 转发到 ObjectiveManager"""
	if not objective_manager or objective_manager.is_finished():
		return
	match collectible_type:
		"energy_core":
			if objective_manager.is_active("collect_cores"):
				objective_manager.report_progress("collect_cores")
		"bio_sample":
			if objective_manager.is_active("collect_samples"):
				objective_manager.report_progress("collect_samples")


# ========== 防守据点 ==========

func _spawn_outpost() -> void:
	"""在地图中心附近生成防守据点"""
	var outpost_scene: PackedScene = load("res://scenes/game_object/defend_outpost/defend_outpost.tscn")
	_outpost = outpost_scene.instantiate() as DefendOutpost
	_outpost.max_health = 100.0
	_outpost.current_health = 100.0
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if entities_layer:
		entities_layer.add_child(_outpost)
	else:
		add_child(_outpost)
	# 放置在地图中心（EnemyManager 的 map_center）
	_outpost.global_position = $EnemyManager.map_center
	_outpost.destroyed.connect(_on_outpost_destroyed)
	_outpost.health_ratio_changed.connect(_on_outpost_health_changed)
	print("[LevelTest] 据点已生成于 %s" % str(_outpost.global_position))


func _on_outpost_destroyed() -> void:
	"""据点被摧毁 — 报告主目标失败"""
	if objective_manager and objective_manager.is_active("defend_outpost"):
		objective_manager.report_fail("defend_outpost")


func _on_outpost_health_changed(ratio: float) -> void:
	"""据点血量变化 — 检查次要目标（据点>50%）"""
	if ratio < 0.5:
		if objective_manager and objective_manager.is_active("defend_no_hit"):
			objective_manager.report_fail("defend_no_hit")


func notify_area_reached(area_id: String) -> void:
	"""到达指定区域"""
	if not objective_manager:
		return
	if area_id == "region3":
		if objective_manager.is_active("reach_lair"):
			objective_manager.report_complete("reach_lair")
		if objective_manager.is_active("investigate_sources"):
			objective_manager.report_complete("investigate_sources")


# ========== 区域检测 ==========

func setup_region_detection():
	var regions_node = $Regions
	for i in range(1, 5):
		var region = regions_node.get_node_or_null("Region1_" + str(i))
		if region:
			region.body_entered.connect(_on_region1_entered)
			region.body_exited.connect(_on_region1_exited)
	for i in range(1, 5):
		var region = regions_node.get_node_or_null("Region2_" + str(i))
		if region:
			region.body_entered.connect(_on_region2_entered)
			region.body_exited.connect(_on_region2_exited)
	var region3 = regions_node.get_node_or_null("Region3")
	if region3:
		region3.body_entered.connect(_on_region3_entered)
		region3.body_exited.connect(_on_region3_exited)


func _on_region1_entered(body):
	if body.is_in_group("player"):
		$EnemyManager.set_current_region($EnemyManager.RegionType.REGION_TYPE_1)

func _on_region1_exited(body):
	if body.is_in_group("player"):
		_check_still_in_regions("Region1_", 4, func(): check_current_region())

func _on_region2_entered(body):
	if body.is_in_group("player"):
		$EnemyManager.set_current_region($EnemyManager.RegionType.REGION_TYPE_2)

func _on_region2_exited(body):
	if body.is_in_group("player"):
		_check_still_in_regions("Region2_", 4, func(): check_current_region())

func _on_region3_entered(body):
	if body.is_in_group("player"):
		$EnemyManager.set_current_region($EnemyManager.RegionType.REGION_TYPE_3)
		notify_area_reached("region3")

		# Boss 条件生成
		if not $EnemyManager.boss_spawned:
			var boss_id: String = _get_active_boss_id()
			if not boss_id.is_empty():
				$EnemyManager.spawn_boss(boss_id)

func _on_region3_exited(body):
	if body.is_in_group("player"):
		check_current_region()


func _get_active_boss_id() -> String:
	if objective_manager:
		if objective_manager.is_active("kill_titan"):
			return "boss_titan"
		if objective_manager.is_active("kill_hive_mother"):
			return "boss_hive"
	# 自由模式
	if GameManager.current_mission_id.is_empty():
		return "boss_titan"
	return ""


func _check_still_in_regions(prefix: String, count: int, fallback: Callable) -> void:
	var regions_node = $Regions
	for i in range(1, count + 1):
		var region = regions_node.get_node_or_null(prefix + str(i))
		if region and region.has_overlapping_bodies():
			for body in region.get_overlapping_bodies():
				if body.is_in_group("player"):
					return
	fallback.call()


func check_current_region():
	var regions_node = $Regions
	var player = get_tree().get_first_node_in_group("player")
	var em = $EnemyManager
	if not player:
		em.set_current_region(em.RegionType.NONE)
		return
	var region3 = regions_node.get_node_or_null("Region3")
	if region3 and _has_player(region3):
		em.set_current_region(em.RegionType.REGION_TYPE_3)
		return
	for i in range(1, 5):
		var r = regions_node.get_node_or_null("Region2_" + str(i))
		if r and _has_player(r):
			em.set_current_region(em.RegionType.REGION_TYPE_2)
			return
	for i in range(1, 5):
		var r = regions_node.get_node_or_null("Region1_" + str(i))
		if r and _has_player(r):
			em.set_current_region(em.RegionType.REGION_TYPE_1)
			return
	em.set_current_region(em.RegionType.NONE)


func _has_player(area: Area2D) -> bool:
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


# ========== Debug ==========
var debug_input_buffer: String = ""
var debug_sequence: String = "DEBUG"

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		add_child(pause_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()

	if event is InputEventKey and event.pressed:
		var keycode = event.keycode
		if keycode >= KEY_A and keycode <= KEY_Z:
			debug_input_buffer += char(keycode - KEY_A + 65)
			if debug_input_buffer.length() > debug_sequence.length():
				debug_input_buffer = debug_input_buffer.substr(debug_input_buffer.length() - debug_sequence.length())
			if debug_input_buffer == debug_sequence:
				GameManager.debug_mode = not GameManager.debug_mode
				print("Debug模式: ", "开启" if GameManager.debug_mode else "关闭")
				debug_input_buffer = ""
				get_tree().root.set_input_as_handled()
				return
		elif keycode >= KEY_0 and keycode <= KEY_9:
			debug_input_buffer += char(keycode - KEY_0 + 48)
			if debug_input_buffer.length() > debug_sequence.length():
				debug_input_buffer = debug_input_buffer.substr(debug_input_buffer.length() - debug_sequence.length())
			if debug_input_buffer == debug_sequence:
				GameManager.debug_mode = not GameManager.debug_mode
				print("Debug模式: ", "开启" if GameManager.debug_mode else "关闭")
				debug_input_buffer = ""
				get_tree().root.set_input_as_handled()
				return
		else:
			debug_input_buffer = ""

	if GameManager.debug_mode and event is InputEventKey and event.pressed:
		if event.keycode == KEY_EQUAL or (event.keycode == KEY_PLUS and not event.shift_pressed):
			var experience_manager = get_node_or_null("ExperienceManager")
			if experience_manager == null:
				experience_manager = get_tree().get_first_node_in_group("experience_manager")
			if experience_manager:
				experience_manager.increment_experience(1.0)
				print("Debug: 获得1点经验")
				get_tree().root.set_input_as_handled()


func on_player_died():
	if not GameManager.apply_mission_result("defeat"):
		return
	GlobalSaveData.save_game()
	var end_screen_instance = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	MetaProgression.save()
