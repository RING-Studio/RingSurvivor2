extends BaseLevel
## LevelTest — 迷你测试关卡。
## 所有 8 个任务共用此场景（通过 match mission_id 分支目标）。
## 正式关卡应各有独立场景和脚本。

# ========== 覆写：关卡特有初始化 ==========

func _configure_level() -> void:
	setup_region_detection()


# ========== 覆写：配置目标 ==========

func _setup_objectives() -> void:
	if not objective_manager:
		return

	var mission_id: String = GameManager.current_mission_id

	match mission_id:
		"recon_patrol":
			objective_manager.add_objective({"id": "survive_90", "display_name": "在巡逻区存活 90 秒", "primary": true, "time_limit": 90, "survive": true})
		"salvage_run":
			objective_manager.add_objective({"id": "collect_cores", "display_name": "收集 20 个能量核心", "primary": true, "target": 20})
			objective_manager.add_objective({"id": "kill_bonus", "display_name": "击杀 30 只敌人", "primary": false, "target": 30})
			_collectible_drops.append({"type": "energy_core", "color": Color(0.2, 0.8, 1.0), "drop_chance": 0.3})
		"containment":
			objective_manager.add_objective({"id": "survive_120", "display_name": "在污染区存活 120 秒", "primary": true, "time_limit": 120, "survive": true})
			objective_manager.add_objective({"id": "kill_elites", "display_name": "击杀 5 只精英敌人", "primary": false, "target": 5})
		"extermination":
			objective_manager.add_objective({"id": "kill_50", "display_name": "击杀 50 只敌人", "primary": true, "target": 50, "time_limit": 120})
		"outpost_defense":
			objective_manager.add_objective({"id": "defend_outpost", "display_name": "保护通信据点 150 秒", "primary": true, "time_limit": 150, "survive": true})
			objective_manager.add_objective({"id": "defend_no_hit", "display_name": "据点血量保持 50% 以上", "primary": false})
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
			_collectible_drops.append({"type": "bio_sample", "color": Color(0.6, 0.2, 0.8), "drop_chance": 0.4, "enemy_filter": "BloatTick"})
		"high_risk_sweep":
			objective_manager.add_objective({"id": "kill_80", "display_name": "击杀 80 只敌人", "primary": true, "target": 80, "time_limit": 150})
			objective_manager.add_objective({"id": "kill_10_elites", "display_name": "击杀 10 只精英敌人", "primary": false, "target": 10})
		_:
			pass


# ========== 覆写：击杀目标逻辑 ==========

func _on_enemy_killed_objectives(enemy: Node2D, is_elite: bool, is_boss: bool, enemy_class: String) -> void:
	# 通用击杀计数
	for obj in objective_manager.get_all_objectives():
		var oid: String = obj["id"]
		if obj["state"] != "active" or obj["target"] <= 0:
			continue
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
			if objective_manager.is_active("titan_kill_fast"):
				objective_manager.report_complete("titan_kill_fast")
		if objective_manager.is_active("kill_hive_mother") and enemy_class == "BossHive":
			objective_manager.report_complete("kill_hive_mother")


# ========== 覆写：收集物目标 ==========

func _on_collectible_collected_objectives(collectible_type: String) -> void:
	match collectible_type:
		"energy_core":
			if objective_manager.is_active("collect_cores"):
				objective_manager.report_progress("collect_cores")
		"bio_sample":
			if objective_manager.is_active("collect_samples"):
				objective_manager.report_progress("collect_samples")


# ========== 覆写：区域到达 ==========

func _on_area_reached(area_id: String) -> void:
	if not objective_manager:
		return
	if area_id == "region3":
		if objective_manager.is_active("reach_lair"):
			objective_manager.report_complete("reach_lair")
		if objective_manager.is_active("investigate_sources"):
			objective_manager.report_complete("investigate_sources")


# ========== 覆写：Boss ID ==========

func _get_boss_id_for_objective(obj_id: String) -> String:
	if obj_id == "kill_titan":
		return "boss_titan"
	elif obj_id == "kill_hive_mother":
		return "boss_hive"
	return ""


# ========== 据点 ==========

func _spawn_outpost() -> void:
	var em: Node = _get_enemy_manager()
	if not em:
		return
	var outpost: DefendOutpost = _spawn_outpost_at(em.map_center, 100.0)
	outpost.destroyed.connect(_on_outpost_destroyed)
	outpost.health_ratio_changed.connect(_on_outpost_health_changed)
	print("[LevelTest] 据点已生成于 %s" % str(outpost.global_position))


func _on_outpost_destroyed() -> void:
	if objective_manager and objective_manager.is_active("defend_outpost"):
		objective_manager.report_fail("defend_outpost")


func _on_outpost_health_changed(ratio: float) -> void:
	if ratio < 0.5:
		if objective_manager and objective_manager.is_active("defend_no_hit"):
			objective_manager.report_fail("defend_no_hit")


# ========== 区域检测 ==========

func setup_region_detection() -> void:
	var regions_node: Node = $Regions
	for i in range(1, 5):
		var region: Area2D = regions_node.get_node_or_null("Region1_" + str(i)) as Area2D
		if region:
			_connect_area_signal(region, _on_region1_entered, _on_region1_exited)
	for i in range(1, 5):
		var region: Area2D = regions_node.get_node_or_null("Region2_" + str(i)) as Area2D
		if region:
			_connect_area_signal(region, _on_region2_entered, _on_region2_exited)
	var region3: Area2D = regions_node.get_node_or_null("Region3") as Area2D
	if region3:
		_connect_area_signal(region3, _on_region3_entered, _on_region3_exited)


func _on_region1_entered(body: Node) -> void:
	if _is_player(body):
		$EnemyManager.set_current_region($EnemyManager.RegionType.REGION_TYPE_1)

func _on_region1_exited(body: Node) -> void:
	if _is_player(body):
		_check_still_in_regions("Region1_", 4, func(): _recheck_current_region())

func _on_region2_entered(body: Node) -> void:
	if _is_player(body):
		$EnemyManager.set_current_region($EnemyManager.RegionType.REGION_TYPE_2)

func _on_region2_exited(body: Node) -> void:
	if _is_player(body):
		_check_still_in_regions("Region2_", 4, func(): _recheck_current_region())

func _on_region3_entered(body: Node) -> void:
	if _is_player(body):
		$EnemyManager.set_current_region($EnemyManager.RegionType.REGION_TYPE_3)
		_on_area_reached("region3")
		# Boss 条件生成
		if not $EnemyManager.boss_spawned:
			var boss_id: String = _get_active_boss_id()
			if not boss_id.is_empty():
				$EnemyManager.spawn_boss(boss_id)

func _on_region3_exited(body: Node) -> void:
	if _is_player(body):
		_recheck_current_region()


func _get_active_boss_id() -> String:
	if objective_manager:
		if objective_manager.is_active("kill_titan"):
			return "boss_titan"
		if objective_manager.is_active("kill_hive_mother"):
			return "boss_hive"
	if GameManager.current_mission_id.is_empty():
		return "boss_titan"
	return ""


func _check_still_in_regions(prefix: String, count: int, fallback: Callable) -> void:
	var regions_node: Node = $Regions
	for i in range(1, count + 1):
		var region: Area2D = regions_node.get_node_or_null(prefix + str(i)) as Area2D
		if region and region.has_overlapping_bodies():
			for body in region.get_overlapping_bodies():
				if body.is_in_group("player"):
					return
	fallback.call()


func _recheck_current_region() -> void:
	var regions_node: Node = $Regions
	var em: Node = $EnemyManager
	var region3: Area2D = regions_node.get_node_or_null("Region3") as Area2D
	if region3 and _has_player_in_area(region3):
		em.set_current_region(em.RegionType.REGION_TYPE_3)
		return
	for i in range(1, 5):
		var r: Area2D = regions_node.get_node_or_null("Region2_" + str(i)) as Area2D
		if r and _has_player_in_area(r):
			em.set_current_region(em.RegionType.REGION_TYPE_2)
			return
	for i in range(1, 5):
		var r: Area2D = regions_node.get_node_or_null("Region1_" + str(i)) as Area2D
		if r and _has_player_in_area(r):
			em.set_current_region(em.RegionType.REGION_TYPE_1)
			return
	em.set_current_region(em.RegionType.NONE)
