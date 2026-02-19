extends Node
class_name MissionData

## 关卡配置表 — 纯数据供 MissionMap 显示
## objectives 只存显示信息，不含逻辑参数
## 关卡内的目标逻辑由各关卡场景的 ObjectiveManager 子节点控制

# ========== 目的地定义（MissionMap 图标） ==========
const DESTINATIONS: Array[Dictionary] = [
	{
		"id": "patrol_zone",
		"name": "外围巡逻区",
		"map_position": Vector2(0.2, 0.5),
		"icon": "patrol",
		"missions": ["recon_patrol"]
	},
	{
		"id": "scrapyard",
		"name": "废弃工厂",
		"map_position": Vector2(0.35, 0.3),
		"icon": "factory",
		"missions": ["salvage_run"]
	},
	{
		"id": "contamination_belt",
		"name": "污染带",
		"map_position": Vector2(0.5, 0.6),
		"icon": "hazard",
		"missions": ["containment", "extermination", "high_risk_sweep"]
	},
	{
		"id": "comm_outpost",
		"name": "通信据点",
		"map_position": Vector2(0.6, 0.35),
		"icon": "outpost",
		"missions": ["outpost_defense"]
	},
	{
		"id": "titan_lair",
		"name": "巨兽巢穴",
		"map_position": Vector2(0.75, 0.55),
		"icon": "boss",
		"missions": ["titan_hunt"]
	},
	{
		"id": "deep_hive",
		"name": "虫巢深处",
		"map_position": Vector2(0.85, 0.4),
		"icon": "boss",
		"missions": ["hive_assault"]
	}
]

# ========== 关卡配置 ==========
# objectives 仅用于 MissionMap/UI 显示，不含 params / trigger / 逻辑
const MISSIONS: Array[Dictionary] = [
	{
		"id": "recon_patrol",
		"name": "野外侦察",
		"description": "在广阔的沙漠巡逻区域存活 10 分钟，熟悉各类敌人。",
		"destination_id": "patrol_zone",
		"difficulty": 1,
		"time_cost": 1,
		"allow_phases": [1, 2, 3],
		"reward_preview": "能量 +200",
		"pollution_rules": {
			"victory": {"mult": 0.95, "add": 250},
			"defeat": {"mult": 1.00, "add": 300}
		},
		"unlock_condition": {},
		"objectives": [
			{"id": "survive_patrol", "display_name": "在沙漠巡逻区存活 600 秒", "primary": true},
			{"id": "kill_30", "display_name": "击杀 60 只敌人（额外奖励）", "primary": false}
		]
	},
	{
		"id": "salvage_run",
		"name": "残骸回收",
		"description": "在废弃工厂区域击杀敌人，收集散落的能量核心。",
		"destination_id": "scrapyard",
		"difficulty": 1,
		"time_cost": 1,
		"allow_phases": [1, 2, 3],
		"reward_preview": "能量 +260",
		"pollution_rules": {
			"victory": {"mult": 0.92, "add": 280},
			"defeat": {"mult": 1.00, "add": 300}
		},
		"unlock_condition": {"clear_mission": "recon_patrol", "clear_count": 1},
		"objectives": [
			{"id": "collect_cores", "display_name": "收集 80 个能量核心", "primary": true},
			{"id": "kill_bonus", "display_name": "击杀 100 只敌人（额外奖励）", "primary": false}
		]
	},
	{
		"id": "containment",
		"name": "污染封锁",
		"description": "在高污染区域存活 10 分钟，毒雾区域需格外小心。",
		"destination_id": "contamination_belt",
		"difficulty": 2,
		"time_cost": 1,
		"allow_phases": [1, 2, 3],
		"reward_preview": "能量 +300",
		"pollution_rules": {
			"victory": {"mult": 0.80, "add": 320},
			"defeat": {"mult": 1.00, "add": 300}
		},
		"unlock_condition": {"clear_mission": "recon_patrol", "clear_count": 1},
		"objectives": [
			{"id": "survive_containment", "display_name": "在污染区存活 600 秒", "primary": true},
			{"id": "kill_elites", "display_name": "击杀 15 只精英敌人（额外奖励）", "primary": false}
		]
	},
	{
		"id": "extermination",
		"name": "歼灭行动",
		"description": "在 10 分钟内击杀 150 只敌人，构筑足够强力的升级组合。",
		"destination_id": "contamination_belt",
		"difficulty": 2,
		"time_cost": 1,
		"allow_phases": [1, 2],
		"reward_preview": "能量 +320",
		"pollution_rules": {
			"victory": {"mult": 0.88, "add": 300},
			"defeat": {"mult": 1.00, "add": 300}
		},
		"unlock_condition": {"clear_any": ["salvage_run", "containment"], "clear_count": 1},
		"objectives": [
			{"id": "kill_80", "display_name": "在 600 秒内击杀 150 只敌人", "primary": true},
			{"id": "kill_elites_bonus", "display_name": "击杀 10 只精英敌人（额外奖励）", "primary": false}
		]
	},
	{
		"id": "outpost_defense",
		"name": "据点保卫",
		"description": "保护通信据点 10 分钟不被摧毁，敌人会持续进攻。",
		"destination_id": "comm_outpost",
		"difficulty": 3,
		"time_cost": 1,
		"allow_phases": [1, 2],
		"reward_preview": "能量 +350",
		"pollution_rules": {
			"victory": {"mult": 0.85, "add": 350},
			"defeat": {"mult": 1.00, "add": 350}
		},
		"unlock_condition": {"clear_mission": "extermination", "clear_count": 1},
		"objectives": [
			{"id": "defend_outpost", "display_name": "保护通信据点 600 秒", "primary": true},
			{"id": "defend_no_hit", "display_name": "据点血量保持 50% 以上（额外奖励）", "primary": false}
		]
	},
	{
		"id": "titan_hunt",
		"name": "巨兽讨伐",
		"description": "深入巨兽巢穴，击杀污染巨兽。",
		"destination_id": "titan_lair",
		"difficulty": 3,
		"time_cost": 2,
		"allow_phases": [1, 2],
		"reward_preview": "能量 +400",
		"pollution_rules": {
			"victory": {"mult": 0.75, "add": 400},
			"defeat": {"mult": 1.00, "add": 300}
		},
		"unlock_condition": {"clear_mission": "outpost_defense", "clear_count": 1},
		"objectives": [
			{"id": "reach_lair", "display_name": "前往巨兽巢穴", "primary": true},
			{"id": "kill_titan", "display_name": "击杀污染巨兽（前置完成后出现）", "primary": true},
			{"id": "titan_kill_fast", "display_name": "90 秒内击杀巨兽（额外奖励）", "primary": false}
		]
	},
	{
		"id": "hive_assault",
		"name": "虫巢清剿",
		"description": "深入虫巢击杀孵化母体。沿途需要调查污染源并清剿虫群。",
		"destination_id": "deep_hive",
		"difficulty": 4,
		"time_cost": 2,
		"allow_phases": [1, 2],
		"reward_preview": "能量 +450",
		"pollution_rules": {
			"victory": {"mult": 0.70, "add": 450},
			"defeat": {"mult": 1.00, "add": 350}
		},
		"unlock_condition": {"clear_mission": "titan_hunt", "clear_count": 1},
		"objectives": [
			{"id": "investigate_sources", "display_name": "调查污染源（前往区域中心）", "primary": true},
			{"id": "kill_hive_mother", "display_name": "击杀孵化母体（前置完成后出现）", "primary": true},
			{"id": "kill_bloats", "display_name": "击杀 30 只膨爆蜱（额外奖励）", "primary": false},
			{"id": "collect_samples", "display_name": "收集 10 个生物样本（额外奖励）", "primary": false}
		]
	},
	{
		"id": "high_risk_sweep",
		"name": "高危清剿",
		"description": "在极度危险的区域击杀大量敌人。精英出现率翻倍，掉落能量核心。",
		"destination_id": "contamination_belt",
		"difficulty": 4,
		"time_cost": 2,
		"allow_phases": [1, 2],
		"reward_preview": "能量 +500",
		"pollution_rules": {
			"victory": {"mult": 0.85, "add": 500},
			"defeat": {"mult": 1.00, "add": 300}
		},
		"unlock_condition": {"clear_any": ["titan_hunt", "hive_assault"], "clear_count": 1},
		"objectives": [
			{"id": "kill_120", "display_name": "击杀 200 只敌人", "primary": true},
			{"id": "kill_15_elites", "display_name": "击杀 25 只精英敌人（额外奖励）", "primary": false}
		]
	}
]

const DEFAULT_SCENE_PATH: String = "res://scenes/Levels/LevelTest/LevelTest.tscn"

# ========== 场景路由 ==========
# mission_id → 对应的关卡场景路径
# 未配置的任务使用 DEFAULT_SCENE_PATH（LevelTest）
const MISSION_SCENE_MAP: Dictionary = {
	"recon_patrol": "res://scenes/Levels/LevelDesert/LevelDesert.tscn",
	"salvage_run": "res://scenes/Levels/LevelDesert/LevelDesert.tscn",
	"containment": "res://scenes/Levels/LevelContaminated/LevelContaminated.tscn",
	"extermination": "res://scenes/Levels/LevelContaminated/LevelContaminated.tscn",
	"outpost_defense": "res://scenes/Levels/LevelContaminated/LevelContaminated.tscn",
	"high_risk_sweep": "res://scenes/Levels/LevelContaminated/LevelContaminated.tscn",
	# titan_hunt / hive_assault 暂用 LevelTest（需要 Boss + Region3 机制）
}

const PHASE_LABELS: Dictionary = {
	1: "早",
	2: "午",
	3: "晚"
}

const DEFAULT_POLLUTION_ADD: int = 300

# ========== 查询函数 ==========

static func get_all_missions() -> Array[Dictionary]:
	return MISSIONS.duplicate(true)

static func get_mission(mission_id: String) -> Dictionary:
	for mission in MISSIONS:
		if mission.get("id", "") == mission_id:
			var result: Dictionary = mission.duplicate(true)
			if not result.has("scene_path"):
				# 优先从场景路由表查找，否则使用默认
				result["scene_path"] = MISSION_SCENE_MAP.get(mission_id, DEFAULT_SCENE_PATH)
			return result
	return {}

static func get_all_destinations() -> Array[Dictionary]:
	return DESTINATIONS.duplicate(true)

static func get_destination(dest_id: String) -> Dictionary:
	for dest in DESTINATIONS:
		if dest.get("id", "") == dest_id:
			return dest.duplicate(true)
	return {}

static func get_missions_for_destination(dest_id: String) -> Array[Dictionary]:
	var dest: Dictionary = get_destination(dest_id)
	var mission_ids: Array = dest.get("missions", [])
	var result: Array[Dictionary] = []
	for mid in mission_ids:
		var m: Dictionary = get_mission(str(mid))
		if not m.is_empty():
			result.append(m)
	return result

static func get_phase_label(phase: int) -> String:
	return PHASE_LABELS.get(phase, str(phase))

static func get_phase_labels(phases: Array) -> String:
	var labels: Array[String] = []
	for p in phases:
		labels.append(get_phase_label(int(p)))
	return "/".join(labels)

static func is_phase_allowed(mission: Dictionary, phase: int) -> bool:
	var phases: Array = mission.get("allow_phases", [])
	if phases.size() == 0:
		return true
	return phase in phases

static func get_time_cost(mission: Dictionary) -> int:
	return max(1, int(mission.get("time_cost", 1)))

static func get_difficulty_stars(mission: Dictionary) -> String:
	var d: int = int(mission.get("difficulty", 1))
	return "★".repeat(d) + "☆".repeat(max(0, 5 - d))

static func get_objectives(mission: Dictionary) -> Array:
	return mission.get("objectives", [])

static func check_unlock_condition(mission: Dictionary) -> bool:
	var condition: Dictionary = mission.get("unlock_condition", {})
	if condition.is_empty():
		return true
	var required_count: int = int(condition.get("clear_count", 1))
	if condition.has("clear_mission"):
		var req_id: String = condition["clear_mission"]
		return GameManager.get_mission_clear_count(req_id) >= required_count
	if condition.has("clear_any"):
		var req_ids: Array = condition["clear_any"]
		for rid in req_ids:
			if GameManager.get_mission_clear_count(str(rid)) >= required_count:
				return true
		return false
	return true

static func calc_pollution_after(current_pollution: int, mission: Dictionary, result: String) -> int:
	if mission.is_empty():
		return _calc_default_pollution_after(current_pollution, result)
	var rules: Dictionary = mission.get("pollution_rules", {})
	var rule: Dictionary = rules.get(result, {})
	if rule.is_empty():
		return _calc_default_pollution_after(current_pollution, result)
	var mult: float = float(rule.get("mult", 1.0))
	var add: int = int(rule.get("add", DEFAULT_POLLUTION_ADD))
	var min_val: int = int(rule.get("min", 0))
	var max_val: int = int(rule.get("max", -1))
	var value: int = int(floor(float(current_pollution) * mult)) + add
	value = max(value, min_val)
	if max_val >= 0:
		value = min(value, max_val)
	return value

static func _calc_default_pollution_after(current_pollution: int, result: String) -> int:
	match result:
		"victory":
			return max(int(floor(float(current_pollution) * 0.9)) + DEFAULT_POLLUTION_ADD, 0)
		"defeat", "skip":
			return max(current_pollution + DEFAULT_POLLUTION_ADD, 0)
		_:
			return max(current_pollution + DEFAULT_POLLUTION_ADD, 0)
