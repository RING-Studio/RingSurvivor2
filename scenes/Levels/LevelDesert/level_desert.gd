extends BaseLevel
## LevelDesert — 开阔沙漠关卡（大型，用于巡逻/回收类任务）
## 对应任务：recon_patrol, salvage_run
## 场地约 19200×10800（LevelTest 的 ~10 倍），单区域，无 Boss

# ========== 区域 ==========
var _play_area: Area2D = null
var _entered_play_area: bool = false


func _configure_level() -> void:
	# 连接唯一的大区域
	_play_area = get_node_or_null("Regions/PlayArea") as Area2D
	if _play_area:
		_connect_area_signal(_play_area, _on_play_area_entered, _on_play_area_exited)
	# 默认激活生成
	var em: Node = _get_enemy_manager()
	if em:
		em.set_current_region(em.RegionType.REGION_TYPE_1)


func _setup_objectives() -> void:
	if not objective_manager:
		return

	var mission_id: String = GameManager.current_mission_id

	match mission_id:
		"recon_patrol":
			# 沙漠巡逻：存活 600 秒（10 分钟），次要目标击杀
			objective_manager.add_objective({
				"id": "survive_patrol",
				"display_name": "在沙漠巡逻区存活 600 秒",
				"primary": true,
				"time_limit": 600,
				"survive": true
			})
			objective_manager.add_objective({
				"id": "kill_30",
				"display_name": "击杀 60 只敌人",
				"primary": false,
				"target": 60
			})
		"salvage_run":
			# 残骸回收：收集 80 个能量核心，次要目标击杀
			objective_manager.add_objective({
				"id": "collect_cores",
				"display_name": "收集 80 个能量核心",
				"primary": true,
				"target": 80
			})
			objective_manager.add_objective({
				"id": "kill_bonus",
				"display_name": "击杀 100 只敌人",
				"primary": false,
				"target": 100
			})
			# 击杀掉落能量核心（30% 概率）
			_collectible_drops.append({
				"type": "energy_core",
				"color": Color(0.2, 0.8, 1.0),
				"drop_chance": 0.30
			})

	# 通用掉落：沙漠关卡所有任务都有少量素材掉落
	_collectible_drops.append({
		"type": "scarab_chitin",
		"color": Color(0.6, 0.45, 0.2),
		"drop_chance": 0.08,
		"enemy_filter": "SandScarab"
	})
	_collectible_drops.append({
		"type": "scrap_metal",
		"color": Color(0.5, 0.5, 0.55),
		"drop_chance": 0.12,
		"enemy_filter": "RustHulk"
	})
	_collectible_drops.append({
		"type": "scarab_chitin",
		"color": Color(0.6, 0.45, 0.2),
		"drop_chance": 0.06,
		"enemy_filter": "DuneBeetle"
	})


func _get_victory_bonus() -> Dictionary:
	match GameManager.current_mission_id:
		"recon_patrol":
			return {"money": 200}
		"salvage_run":
			return {"money": 260}
	return {}

func _get_objective_rewards() -> Dictionary:
	match GameManager.current_mission_id:
		"recon_patrol":
			return {
				"kill_30": {"display_name": "击杀 60 只敌人", "money": 100},
			}
		"salvage_run":
			return {
				"kill_bonus": {"display_name": "击杀 100 只敌人", "money": 150, "materials": {"scrap_metal": 1}},
			}
	return {}


func _on_enemy_killed_objectives(enemy: Node2D, is_elite: bool, is_boss: bool, enemy_class: String) -> void:
	for obj in objective_manager.get_all_objectives():
		var oid: String = obj["id"]
		if obj["state"] != "active" or obj["target"] <= 0:
			continue
		if oid in ["kill_30", "kill_bonus"]:
			objective_manager.report_progress(oid)


func _on_collectible_collected_objectives(collectible_type: String) -> void:
	if collectible_type == "energy_core":
		if objective_manager.is_active("collect_cores"):
			objective_manager.report_progress("collect_cores")


# ========== 区域信号 ==========

func _on_play_area_entered(body: Node) -> void:
	if _is_player(body):
		_entered_play_area = true
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.REGION_TYPE_1)

func _on_play_area_exited(body: Node) -> void:
	if _is_player(body):
		_entered_play_area = false
		var em: Node = _get_enemy_manager()
		if em:
			em.set_current_region(em.RegionType.NONE)
