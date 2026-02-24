extends BaseLevel
## LevelContaminated — 污染带关卡（大型，高密度敌人，有环境伤害区域）
## 对应任务：containment, extermination, outpost_defense, high_risk_sweep
## 场地约 19200×10800，双区域（外围 + 核心），含环境毒雾伤害（4 个毒雾区）

# ========== 环境伤害 ==========
var _hazard_zones: Array[Area2D] = []
var _hazard_timer: float = 0.0
const HAZARD_DAMAGE_INTERVAL: float = 2.0
const HAZARD_DAMAGE: float = 2.0

# ========== 区域 ==========
var _in_core_zone: bool = false


func _configure_level() -> void:
	# 连接区域
	var outer: Area2D = get_node_or_null("Regions/OuterZone") as Area2D
	var core: Area2D = get_node_or_null("Regions/CoreZone") as Area2D
	if outer:
		_connect_area_signal(outer, _on_outer_entered, _on_outer_exited)
	if core:
		_connect_area_signal(core, _on_core_entered, _on_core_exited)

	# 收集环境伤害区域
	var hazards_node: Node = get_node_or_null("HazardZones")
	if hazards_node:
		for child in hazards_node.get_children():
			if child is Area2D:
				_hazard_zones.append(child as Area2D)

	# 默认激活外围
	var em: Node = _get_enemy_manager()
	if em:
		em.set_current_region(em.RegionType.REGION_TYPE_1)


func _process(delta: float) -> void:
	# 环境毒雾伤害
	if _hazard_zones.is_empty():
		return
	_hazard_timer += delta
	if _hazard_timer >= HAZARD_DAMAGE_INTERVAL:
		_hazard_timer -= HAZARD_DAMAGE_INTERVAL
		_apply_hazard_damage()


func _apply_hazard_damage() -> void:
	"""对处于毒雾区域内的玩家造成伤害"""
	var player: Node2D = _get_player()
	if not player:
		return
	for zone in _hazard_zones:
		if not is_instance_valid(zone):
			continue
		if _has_player_in_area(zone):
			if player.has_node("HealthComponent"):
				var hc: Node = player.get_node("HealthComponent")
				if hc.has_method("damage"):
					hc.damage(HAZARD_DAMAGE)
					print("[Contaminated] 环境伤害 %.1f" % HAZARD_DAMAGE)
			break


func _setup_objectives() -> void:
	if not objective_manager:
		return

	var mission_id: String = GameManager.current_mission_id

	match mission_id:
		"containment":
			# 污染封锁：高污染区存活 600 秒（10 分钟）
			objective_manager.add_objective({
				"id": "survive_containment",
				"display_name": "在污染区存活 600 秒",
				"primary": true,
				"time_limit": 600,
				"survive": true
			})
			objective_manager.add_objective({
				"id": "kill_elites",
				"display_name": "击杀 15 只精英敌人",
				"primary": false,
				"target": 15
			})
		"extermination":
			# 歼灭行动：限时击杀 150 只敌人（10 分钟）
			objective_manager.add_objective({
				"id": "kill_80",
				"display_name": "在 600 秒内击杀 150 只敌人",
				"primary": true,
				"target": 150,
				"time_limit": 600
			})
			objective_manager.add_objective({
				"id": "kill_elites_bonus",
				"display_name": "击杀 10 只精英敌人",
				"primary": false,
				"target": 10
			})
		"outpost_defense":
			# 据点保卫：保护据点 600 秒（10 分钟）
			objective_manager.add_objective({
				"id": "defend_outpost",
				"display_name": "保护通信据点 600 秒",
				"primary": true,
				"time_limit": 600,
				"survive": true
			})
			objective_manager.add_objective({
				"id": "defend_no_hit",
				"display_name": "据点血量保持 50% 以上",
				"primary": false
			})
			_spawn_outpost_for_defense()
		"high_risk_sweep":
			# 高危清剿：击杀 200 只敌人（含精英目标）
			objective_manager.add_objective({
				"id": "kill_120",
				"display_name": "击杀 200 只敌人",
				"primary": true,
				"target": 200,
				"time_limit": 600
			})
			objective_manager.add_objective({
				"id": "kill_15_elites",
				"display_name": "击杀 25 只精英敌人",
				"primary": false,
				"target": 25
			})
			# 高危区掉落能量核心
			_collectible_drops.append({
				"type": "energy_core",
				"color": Color(0.8, 0.3, 0.1),
				"drop_chance": 0.15
			})
		_:
			pass

	# 通用掉落：污染带关卡所有任务都有素材掉落
	_collectible_drops.append({
		"type": "bio_sample",
		"color": Color(0.3, 0.85, 0.3),
		"drop_chance": 0.15,
		"enemy_filter": "BloatTick"
	})
	_collectible_drops.append({
		"type": "spore_sample",
		"color": Color(0.7, 0.5, 0.9),
		"drop_chance": 0.10,
		"enemy_filter": "SporeCaster"
	})
	_collectible_drops.append({
		"type": "acid_gland",
		"color": Color(0.9, 0.8, 0.1),
		"drop_chance": 0.10,
		"enemy_filter": "AcidSpitter"
	})
	_collectible_drops.append({
		"type": "scrap_metal",
		"color": Color(0.5, 0.5, 0.55),
		"drop_chance": 0.10,
		"enemy_filter": "RustHulk"
	})


func _get_victory_bonus() -> Dictionary:
	match GameManager.current_mission_id:
		"containment":
			return {"money": 300}
		"extermination":
			return {"money": 320}
		"outpost_defense":
			return {"money": 350}
		"high_risk_sweep":
			return {"money": 500}
	return {}

func _get_objective_rewards() -> Dictionary:
	match GameManager.current_mission_id:
		"containment":
			return {
				"kill_elites": {"display_name": "击杀 15 只精英敌人", "money": 200, "materials": {"bio_sample": 2}},
			}
		"extermination":
			return {
				"kill_elites_bonus": {"display_name": "击杀 10 只精英敌人", "money": 180},
			}
		"outpost_defense":
			return {
				"defend_no_hit": {"display_name": "据点血量保持 50% 以上", "money": 250, "materials": {"energy_core": 1}},
			}
		"high_risk_sweep":
			return {
				"kill_15_elites": {"display_name": "击杀 25 只精英敌人", "money": 300, "materials": {"acid_gland": 2}},
			}
	return {}


func _on_enemy_killed_objectives(enemy: Node2D, is_elite: bool, is_boss: bool, enemy_class: String) -> void:
	for obj in objective_manager.get_all_objectives():
		var oid: String = obj["id"]
		if obj["state"] != "active" or obj["target"] <= 0:
			continue
		# 通用击杀计数
		if oid in ["kill_80", "kill_120"]:
			objective_manager.report_progress(oid)
		# 精英击杀
		elif oid in ["kill_elites", "kill_elites_bonus", "kill_15_elites"]:
			if is_elite:
				objective_manager.report_progress(oid)


func _on_collectible_collected_objectives(collectible_type: String) -> void:
	# 当前无收集目标，留作扩展
	pass


# ========== 据点 ==========

func _spawn_outpost_for_defense() -> void:
	var em: Node = _get_enemy_manager()
	if not em:
		return
	var outpost: DefendOutpost = _spawn_outpost_at(em.map_center, 150.0)
	outpost.destroyed.connect(_on_outpost_destroyed)
	outpost.health_ratio_changed.connect(_on_outpost_health_changed)
	print("[Contaminated] 据点已生成于 %s，HP=%.0f" % [str(outpost.global_position), outpost.max_health])


func _on_outpost_destroyed() -> void:
	if objective_manager and objective_manager.is_active("defend_outpost"):
		objective_manager.report_fail("defend_outpost")


func _on_outpost_health_changed(ratio: float) -> void:
	if ratio < 0.5:
		if objective_manager and objective_manager.is_active("defend_no_hit"):
			objective_manager.report_fail("defend_no_hit")


# ========== 区域信号 ==========

func _on_outer_entered(body: Node) -> void:
	if _is_player(body):
		var em: Node = _get_enemy_manager()
		if em and not _in_core_zone:
			em.set_current_region(em.RegionType.REGION_TYPE_1)

func _on_outer_exited(body: Node) -> void:
	if _is_player(body):
		if not _in_core_zone:
			var em: Node = _get_enemy_manager()
			if em:
				em.set_current_region(em.RegionType.NONE)

func _on_core_entered(body: Node) -> void:
	if _is_player(body):
		_in_core_zone = true
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.REGION_TYPE_2)

func _on_core_exited(body: Node) -> void:
	if _is_player(body):
		_in_core_zone = false
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.REGION_TYPE_1)
