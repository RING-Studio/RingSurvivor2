extends BaseLevel
## LevelBoss — Boss 战专用关卡
## 对应任务：titan_hunt, hive_assault
## 中型场地 9600×5400，外围+中央 Boss 竞技场两区域
## 进入中央区域触发 Boss 生成

var _boss_arena: Area2D = null
var _outer_zone: Area2D = null
var _entered_boss_arena: bool = false


func _configure_level() -> void:
	_outer_zone = get_node_or_null("Regions/OuterZone") as Area2D
	_boss_arena = get_node_or_null("Regions/BossArena") as Area2D
	if _outer_zone:
		_connect_area_signal(_outer_zone, _on_outer_entered, _on_outer_exited)
	if _boss_arena:
		_connect_area_signal(_boss_arena, _on_boss_arena_entered, _on_boss_arena_exited)

	# 默认激活外围区域生成
	var em: Node = _get_enemy_manager()
	if em:
		em.set_current_region(em.RegionType.REGION_TYPE_1)


func _setup_objectives() -> void:
	if not objective_manager:
		return

	var mission_id: String = GameManager.current_mission_id

	match mission_id:
		"titan_hunt":
			objective_manager.add_objective({
				"id": "reach_lair",
				"display_name": "前往巨兽巢穴（地图中心）",
				"primary": true
			})
			objective_manager.add_objective({
				"id": "kill_titan",
				"display_name": "击杀污染巨兽",
				"primary": true,
				"time_limit": 300,
				"after": "reach_lair"
			})
			objective_manager.add_objective({
				"id": "titan_kill_fast",
				"display_name": "120 秒内击杀巨兽",
				"primary": false,
				"time_limit": 120,
				"after": "reach_lair"
			})
			# 素材掉落：沙漠甲虫掉甲壳、重甲掉废金属
			_collectible_drops.append({
				"type": "scarab_chitin",
				"color": Color(0.6, 0.45, 0.2),
				"drop_chance": 0.10,
				"enemy_filter": "SandScarab"
			})
			_collectible_drops.append({
				"type": "scrap_metal",
				"color": Color(0.5, 0.5, 0.55),
				"drop_chance": 0.15,
				"enemy_filter": "RustHulk"
			})

		"hive_assault":
			objective_manager.add_objective({
				"id": "investigate_sources",
				"display_name": "调查污染源（前往地图中心）",
				"primary": true
			})
			objective_manager.add_objective({
				"id": "kill_hive_mother",
				"display_name": "击杀孵化母体",
				"primary": true,
				"time_limit": 300,
				"after": "investigate_sources"
			})
			objective_manager.add_objective({
				"id": "kill_bloats",
				"display_name": "击杀 30 只膨爆蜱",
				"primary": false,
				"target": 30
			})
			objective_manager.add_objective({
				"id": "collect_samples",
				"display_name": "收集 10 个生物样本",
				"primary": false,
				"target": 10
			})
			# 膨爆蜱掉落生物样本
			_collectible_drops.append({
				"type": "bio_sample",
				"color": Color(0.6, 0.2, 0.8),
				"drop_chance": 0.40,
				"enemy_filter": "BloatTick"
			})
			_collectible_drops.append({
				"type": "spore_sample",
				"color": Color(0.3, 0.7, 0.2),
				"drop_chance": 0.12,
				"enemy_filter": "SporeCaster"
			})


func _get_victory_bonus() -> Dictionary:
	match GameManager.current_mission_id:
		"titan_hunt":
			return {"money": 400, "materials": {"scrap_metal": 1}}
		"hive_assault":
			return {"money": 450, "materials": {"bio_sample": 2}}
	return {}

func _get_objective_rewards() -> Dictionary:
	match GameManager.current_mission_id:
		"titan_hunt":
			return {
				"titan_kill_fast": {"display_name": "120 秒内击杀巨兽", "money": 300, "materials": {"scarab_chitin": 2}},
			}
		"hive_assault":
			return {
				"kill_bloats": {"display_name": "击杀 30 只膨爆蜱", "money": 150},
				"collect_samples": {"display_name": "收集 10 个生物样本", "money": 200, "materials": {"spore_sample": 1}},
			}
	return {}


func _on_enemy_killed_objectives(enemy: Node2D, is_elite: bool, is_boss: bool, enemy_class: String) -> void:
	# 通用击杀计数
	for obj in objective_manager.get_all_objectives():
		var oid: String = obj["id"]
		if obj["state"] != "active" or obj["target"] <= 0:
			continue
		if oid == "kill_bloats" and enemy_class == "BloatTick":
			objective_manager.report_progress(oid)

	# Boss 击杀
	if is_boss:
		if objective_manager.is_active("kill_titan") and enemy_class == "BossTitan":
			objective_manager.report_complete("kill_titan")
			if objective_manager.is_active("titan_kill_fast"):
				objective_manager.report_complete("titan_kill_fast")
		if objective_manager.is_active("kill_hive_mother") and enemy_class == "BossHive":
			objective_manager.report_complete("kill_hive_mother")


func _on_collectible_collected_objectives(collectible_type: String) -> void:
	if collectible_type == "bio_sample":
		if objective_manager.is_active("collect_samples"):
			objective_manager.report_progress("collect_samples")


func _on_area_reached(area_id: String) -> void:
	if not objective_manager:
		return
	if area_id == "boss_arena":
		if objective_manager.is_active("reach_lair"):
			objective_manager.report_complete("reach_lair")
		if objective_manager.is_active("investigate_sources"):
			objective_manager.report_complete("investigate_sources")


func _get_boss_id_for_objective(obj_id: String) -> String:
	if obj_id == "kill_titan":
		return "boss_titan"
	elif obj_id == "kill_hive_mother":
		return "boss_hive"
	return ""


# ========== 区域信号 ==========

func _on_outer_entered(body: Node) -> void:
	if _is_player(body):
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.REGION_TYPE_1)

func _on_outer_exited(body: Node) -> void:
	if _is_player(body) and not _entered_boss_arena:
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.NONE)

func _on_boss_arena_entered(body: Node) -> void:
	if _is_player(body):
		_entered_boss_arena = true
		_on_area_reached("boss_arena")
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.REGION_TYPE_2)
			# 首次进入 Boss 竞技场 → 生成 Boss
			if not em.boss_spawned:
				var boss_id: String = _get_active_boss_id()
				if not boss_id.is_empty():
					em.spawn_boss(boss_id)

func _on_boss_arena_exited(body: Node) -> void:
	if _is_player(body):
		_entered_boss_arena = false
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.REGION_TYPE_1)


func _get_active_boss_id() -> String:
	if objective_manager:
		if objective_manager.is_active("kill_titan"):
			return "boss_titan"
		if objective_manager.is_active("kill_hive_mother"):
			return "boss_hive"
	if GameManager.current_mission_id == "titan_hunt":
		return "boss_titan"
	elif GameManager.current_mission_id == "hive_assault":
		return "boss_hive"
	return "boss_titan"
