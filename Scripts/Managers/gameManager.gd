class_name gameManager
extends Node

### **五、存档数据**
#region SaveData
# 天数
var day: int = 1

#时间段(1~3代表早午晚）
var time_phase: int = 1

# 污染值
var pollution: int = 0

# 任务结算标记（避免胜利/失败重复结算）
var mission_resolved: bool = false

# 时间与污染推进参数
const PHASES_PER_DAY: int = 3
const BASE_POLLUTION_INCREASE_PER_PHASE: int = 300

# ========== 关卡进度（存档持久化） ==========
# mission_progress: 每个关卡的解锁/完成状态
# 格式: { "mission_id": { "unlocked": bool, "clear_count": int, "best_score": int,
#          "max_difficulty": int, "completed_objectives": [] } }
# 未来可扩展字段: completed_objectives 用于追踪关卡内目标完成情况
var mission_progress: Dictionary = {}

# chapter_progress: 章节完成状态
# 格式: { "chapter_id": { "unlocked": bool, "completed": bool } }
var chapter_progress: Dictionary = {}

# npc_dialogues: NPC 对话进度追踪（14.2）
# 格式: { "npc_id": int }  — int 为当前对话序列索引
var npc_dialogues: Dictionary = {}

# objectives: 目标（主线/支线）进度
# 格式: { "objective_id": { "description": "", "completed": bool, "progress": 0, "target": 0 } }
# 例如: "clear_stage_1": { "description": "通过关卡1", "completed": false }
#       "talk_to_xxx": { "description": "与XXX对话", "completed": false }
#       "kill_n_xxx":  { "description": "击败N只XXX", "completed": false, "progress": 0, "target": 50 }
var objectives: Dictionary = {}

# ========== 运行时状态（不存档） ==========
# 当前出击的关卡 id（仅运行时使用，不存档）
var current_mission_id: String = ""

# 兼容旧代码的章节号
var chapter: int = 1

# HUD 显示用：当前状态文本（不存档，运行时计算）
var _hud_mission_text: String = "待出击"

# 当前选中车辆
var current_vehicle: int = 0

# 当前选中技能（被动效果）
var current_skill: String = ""

# 每辆车目前的配置方案
var vehicles_config: Dictionary = {
	
}

var unlocked_vehicles: Array = [0]

var unlocked_parts: Dictionary = {
	"主武器类型": [],
	"装甲类型": [],
	"配件": []
}

#升级数据
var current_upgrades = {}

# Roll点系统（用于刷新升级）
var roll_points: int = 0

# Debug模式
var debug_mode: bool = false

# 能量值(钱)
var money: int = 100000

# 素材库（局外持久化，由关卡结算写入）
# 格式: { "material_id": amount, ... }
var materials: Dictionary = {}

# ========== 单局会话数据（不存档，每局开始重置） ==========
# 当局收集到的素材（类型 → 数量）
var session_materials: Dictionary = {}
# 当局玩家是否死亡（用于结算损失比例判定）
var session_player_died: bool = false
# 当局获得的升级 ID 列表（用于解锁配件，Mark E.1）
var session_acquired_upgrades: Array[String] = []

# ========== 升级品质基准值（用于结算返还能量计算） ==========
const QUALITY_BASE_VALUE: Dictionary = {
	"white": 1,
	"blue": 3,
	"purple": 8,
	"red": 20,
}

func init_game():
	"""初始化新游戏数据"""
	# 重置游戏状态
	day = 1
	time_phase = 1
	pollution = 7000
	mission_progress = _default_mission_progress()
	chapter_progress = _default_chapter_progress()
	npc_dialogues = {}
	objectives = _default_objectives()
	current_vehicle = 0
	current_skill = ""
	money = 100000
	mission_resolved = false
	current_mission_id = ""
	chapter = 1
	_hud_mission_text = "待出击"

	# 初始化车辆配置 - 默认改进公务车 + 机炮（英文 id）
	vehicles_config = {
		"0": {
			"车辆类型": "improved_sedan",
			"主武器类型": "machine_gun",
			"装甲类型": null,
			"配件": []
		}
	}

	# 初始化解锁内容
	unlocked_vehicles = [0]
	unlocked_parts = {
		"主武器类型": ["machine_gun"],
		"装甲类型": [],
		"配件": []
	}

	# 初始化升级数据
	current_upgrades = {}
	session_materials = {}
	session_player_died = false
	session_acquired_upgrades = []

func is_vehicle_unlocked(id:int):
	for vehicle_id in unlocked_vehicles:
		if vehicle_id == id:
			return true
	return false


func is_parts_unlocked(table_name:String, id: Variant):
	if table_name in unlocked_parts:
		for part_id in unlocked_parts[table_name]:
			if part_id == id:
				return true
	return false

func get_vehicle_config(vehicle_id:int):
	return vehicles_config.get(str(vehicle_id))

func get_brought_in_accessories() -> Array:
	"""当前车辆配装中带入的配件 id 列表（来自配置，非 session）。"""
	var config = get_vehicle_config(current_vehicle)
	if config == null:
		return []
	var parts = config.get("配件", [])
	var out: Array = []
	for p in parts:
		if p is String:
			out.append(p)
	return out

func get_brought_in_accessory_level(vehicle_id: int, accessory_id: String) -> int:
	"""带入配件的预升级等级。"""
	var config = get_vehicle_config(vehicle_id)
	if config == null:
		return 1
	var levels = config.get("配件等级", {})
	if typeof(levels) != TYPE_DICTIONARY:
		return 1
	return clampi(int(levels.get(accessory_id, 1)), 1, EquipmentCostData.MAX_ACCESSORY_LEVEL)

func set_accessory_level(vehicle_id: int, accessory_id: String, level: int) -> void:
	"""设置配件预升级等级（策划书 5B.4）。"""
	var config = get_vehicle_config(vehicle_id)
	if config == null:
		return
	if not config.has("配件等级"):
		config["配件等级"] = {}
	var clamped: int = clampi(level, 1, EquipmentCostData.MAX_ACCESSORY_LEVEL)
	if clamped <= 1:
		(config["配件等级"] as Dictionary).erase(accessory_id)
	else:
		config["配件等级"][accessory_id] = clamped

func is_equipped( vehicle_id:int, slot:String, part_id: Variant ):
	var vehicle_data = get_vehicle_config(vehicle_id)
	if vehicle_data == null:
		return false
	var id = vehicle_data.get(slot)
	if id == null:
		return false
	match slot:
		"装甲类型", "主武器类型":
			return id == part_id
		"配件":
			if part_id is not String:
				return false
			for part in id:
				if part == part_id:
					return true
	return false

func equip_part( vehicle_id:int, slot:String, part_id: Variant ):
	if slot == "配件" and part_id is not String:
		return false
	# 未解锁配件不允许装备
	if not is_parts_unlocked(slot, part_id):
		print("[Equip] 配件未解锁: %s" % str(part_id))
		return false
	if is_equipped( vehicle_id, slot, part_id ):
		return false
	var vehicle_data = get_vehicle_config(vehicle_id)
	if vehicle_data == null:
		vehicles_config[str(vehicle_id)] = {}
		vehicle_data = vehicles_config[str(vehicle_id)]
	match slot:
		"装甲类型", "主武器类型":
			vehicle_data[slot] = part_id
		"配件":
			if vehicle_data.get("配件") == null:
				vehicle_data["配件"] = []
			if vehicle_data["配件"].size() >= 4:
				return false
			if part_id not in vehicle_data["配件"]:
				vehicle_data["配件"].append(part_id)
		_:
			push_warning("未知装备槽: %s" % slot)
			return false
	return true

func unload_part( vehicle_id:int, slot:String, part_id: Variant ):
	if slot == "配件" and part_id is not String:
		return false
	if not is_equipped( vehicle_id, slot, part_id ):
		return false
	var vehicle_data = get_vehicle_config(vehicle_id)
	if vehicle_data == null:
		return false
	match slot:
		"装甲类型", "主武器类型":
			if vehicle_data.get(slot) == part_id:
				vehicle_data.erase(slot)
		"配件":
			vehicle_data["配件"].erase(part_id)
			if vehicle_data.has("配件等级") and vehicle_data["配件等级"] is Dictionary:
				(vehicle_data["配件等级"] as Dictionary).erase(part_id)
		_:
			push_warning("未知装备槽: %s" % slot)
	return true

func _default_vehicle_type_by_slot(slot: int) -> String:
	var defaults = ["improved_sedan", "wheeled_vehicle", "armored_car", "tank"]
	if slot >= 0 and slot < defaults.size():
		return defaults[slot]
	return "improved_sedan"

func get_player_property(property_name: String):
	"""仅读取固定基础数值：车型 + 装甲 + 主武器。配件/科技不在此计算。"""
	var vehicle_config_data = get_vehicle_config(current_vehicle)
	if vehicle_config_data == null:
		return [0, 0, 0]

	# 车型基础（车辆类型，英文 id）
	var vehicle_type_id: Variant = vehicle_config_data.get("车辆类型")
	if vehicle_type_id == null:
		vehicle_type_id = _default_vehicle_type_by_slot(current_vehicle)
	var vehicle_value = 0
	var vehicle_data = JsonManager.get_category_by_id("车辆类型", vehicle_type_id)
	if vehicle_data != null:
		var tmp = vehicle_data.get(property_name)
		if tmp != null:
			vehicle_value = tmp

	# 装甲基础（英文 id）
	var armor_value = 0
	var id = vehicle_config_data.get("装甲类型")
	if id != null:
		var armor = JsonManager.get_category_by_id("装甲类型", id)
		if armor != null:
			var tmp = armor.get(property_name)
			if tmp != null:
				armor_value = tmp

	# 主武器基础（英文 id）
	var equipment_value = 0
	id = vehicle_config_data.get("主武器类型")
	if id != null:
		var equipment = JsonManager.get_category_by_id("主武器类型", id)
		if equipment != null:
			var tmp = equipment.get(property_name)
			if tmp != null:
				equipment_value = tmp

	return [vehicle_value, armor_value, equipment_value]

# 基础伤害（仅车型+装甲+主武器基础，配件在后续节点计算）
func get_player_base_damage():
	var values = get_player_property("BaseDamage")  # [vehicle, armor, equipment]
	return values[2] * (1.0 + values[0] + values[1])  # equipment * (1 + vehicle + armor)

# 硬攻倍率
func get_player_hard_attack_multiplier_percent():
	var values = get_player_property("HardAttackMultiplierPercent")
	return values[0] + values[1] + values[2]

# 软攻倍率
func get_player_soft_attack_multiplier_percent():
	var values = get_player_property("SoftAttackMultiplierPercent")
	return values[0] + values[1] + values[2]

# 硬攻深度
func get_player_hard_attack_depth_mm():
	var values = get_player_property("HardAttackDepthMm")
	return values[0] + values[1] + values[2]

# 装甲厚度
func get_player_armor_thickness():
	var values = get_player_property("ArmorThickness")  # [vehicle, armor, equipment]
	return values[0] + values[1] * (1.0 + values[2])  # vehicle + armor * (1 + equipment)

# 覆甲率
func get_player_armor_coverage():
	var values = get_player_property("ArmorCoverage")
	return values[0] + values[1] + values[2]

# 击穿伤害减免
func get_player_armor_damage_reduction_percent():
	var values = get_player_property("ArmorDamageReductionPercent")
	return values[0] + values[1] + values[2]

func get_player_max_health():
	var config = get_vehicle_config(current_vehicle)
	if config == null:
		return 0
	var vehicle_type_id: Variant = config.get("车辆类型")
	if vehicle_type_id == null:
		vehicle_type_id = _default_vehicle_type_by_slot(current_vehicle)
	var data = JsonManager.get_category_by_id("车辆类型", vehicle_type_id)
	if data == null:
		return 0
	var health = data.get("Health")
	if health == null:
		return 0
	return health

# ========== 关卡/目标 默认数据工厂 ==========

func _default_mission_progress() -> Dictionary:
	"""初始关卡进度：默认解锁第一个关卡。"""
	var out: Dictionary = {}
	var all_missions = MissionData.get_all_missions()
	for i in range(all_missions.size()):
		var m = all_missions[i]
		var mid: String = m.get("id", "")
		if mid.is_empty():
			continue
		out[mid] = {
			"unlocked": (i == 0),  # 默认只解锁第一个
			"clear_count": 0,
			"best_score": 0,
			"max_difficulty": 0,
			"completed_objectives": []
		}
	return out

func _default_chapter_progress() -> Dictionary:
	return {
		"1": { "unlocked": true, "completed": false }
	}

func _default_objectives() -> Dictionary:
	"""初始目标列表（举例，后续可从数据表读取）。"""
	return {
		"clear_scout_ops": { "description": "完成一次侦察清扫", "completed": false, "progress": 0, "target": 1 },
		# 以下为预留示例，暂不在 UI 中展示
		# "talk_to_mechanic": { "description": "与机械师对话", "completed": false },
		# "kill_50_enemies": { "description": "击败50只敌人", "completed": false, "progress": 0, "target": 50 },
	}

func is_mission_unlocked(mission_id: String) -> bool:
	# 优先检查 mission_progress 中是否已标记解锁
	var entry = mission_progress.get(mission_id, {})
	if entry.get("unlocked", false):
		return true
	# 否则检查 MissionData 中的解锁条件是否满足
	var mission: Dictionary = MissionData.get_mission(mission_id)
	if mission.is_empty():
		return false
	return MissionData.check_unlock_condition(mission)

func get_mission_clear_count(mission_id: String) -> int:
	var entry = mission_progress.get(mission_id, {})
	return int(entry.get("clear_count", 0))

func unlock_mission(mission_id: String) -> void:
	if not mission_progress.has(mission_id):
		mission_progress[mission_id] = { "unlocked": true, "clear_count": 0, "best_score": 0, "max_difficulty": 0, "completed_objectives": [] }
	else:
		mission_progress[mission_id]["unlocked"] = true

func record_mission_clear(mission_id: String, score: int = 0, completed_obj_ids: Array[String] = []) -> void:
	"""记录关卡通关，并自动解锁满足条件的后续关卡。"""
	if not mission_progress.has(mission_id):
		unlock_mission(mission_id)
	var entry: Dictionary = mission_progress[mission_id]
	entry["clear_count"] = int(entry.get("clear_count", 0)) + 1
	if score > int(entry.get("best_score", 0)):
		entry["best_score"] = score
	# 合并已完成的目标（不重复）
	var existing_objs: Array = entry.get("completed_objectives", [])
	for obj_id in completed_obj_ids:
		if obj_id not in existing_objs:
			existing_objs.append(obj_id)
	entry["completed_objectives"] = existing_objs
	# 自动检查并解锁后续关卡
	_auto_unlock_missions()
	# 14.4：检查章节完成与剧情推进
	check_chapter_completion()


func get_mission_completed_objectives(mission_id: String) -> Array:
	"""获取指定关卡已完成的目标 ID 列表"""
	var entry: Dictionary = mission_progress.get(mission_id, {})
	return entry.get("completed_objectives", [])

func _auto_unlock_missions() -> void:
	"""通关后自动检查并解锁满足条件的关卡。"""
	var all_missions: Array = MissionData.get_all_missions()
	for m in all_missions:
		var mid: String = m.get("id", "")
		if mid.is_empty():
			continue
		# 跳过已解锁的
		var entry = mission_progress.get(mid, {})
		if entry.get("unlocked", false):
			continue
		# 检查是否满足解锁条件
		if MissionData.check_unlock_condition(m):
			unlock_mission(mid)
			print("[Mission] 解锁关卡: %s" % mid)

func advance_objective(objective_id: String, amount: int = 1) -> void:
	"""推进目标进度（通用接口）。"""
	if not objectives.has(objective_id):
		return
	var obj = objectives[objective_id]
	if obj.get("completed", false):
		return
	var target_val = int(obj.get("target", 1))
	var progress_val = int(obj.get("progress", 0)) + amount
	obj["progress"] = progress_val
	if progress_val >= target_val:
		obj["completed"] = true
		print("[Objective] 完成目标: %s" % objective_id)
		_check_story_progression()

func get_hud_mission_text() -> String:
	return _hud_mission_text

# ========== 14.3 章节奖励 + 14.4 剧情推进 ==========

const CHAPTER_DEFINITIONS: Dictionary = {
	"1": {
		"name": "第一章：初入荒野",
		"required_missions": ["recon_patrol", "salvage_run"],
		"rewards": {"money": 500, "materials": {"scrap_metal": 5}},
		"unlock_npc_dialogues": {"npc_mechanic": 2, "npc_quartermaster": 1},
	},
	"2": {
		"name": "第二章：深入污染",
		"required_missions": ["containment", "extermination", "outpost_defense"],
		"rewards": {"money": 1000, "materials": {"bio_sample": 5, "acid_gland": 3}},
		"unlock_npc_dialogues": {"npc_mechanic": 3, "npc_quartermaster": 2},
	},
	"3": {
		"name": "第三章：终局之战",
		"required_missions": ["titan_hunt", "hive_assault"],
		"rewards": {"money": 2000, "materials": {"spore_sample": 5, "energy_core": 5}},
		"unlock_npc_dialogues": {"npc_quartermaster": 3},
	}
}

func check_chapter_completion() -> void:
	"""检查所有章节是否满足完成条件，自动推进。"""
	for ch_id in CHAPTER_DEFINITIONS:
		var ch_data: Dictionary = CHAPTER_DEFINITIONS[ch_id]
		var ch_entry: Dictionary = chapter_progress.get(ch_id, {"unlocked": false, "completed": false})
		if ch_entry.get("completed", false):
			continue
		if not ch_entry.get("unlocked", false):
			continue
		var required: Array = ch_data.get("required_missions", [])
		var all_cleared: bool = true
		for mid in required:
			if get_mission_clear_count(mid) <= 0:
				all_cleared = false
				break
		if all_cleared:
			_complete_chapter(ch_id)

func _complete_chapter(ch_id: String) -> void:
	"""完成章节：发放奖励、解锁下一章、推进 NPC 对话。"""
	if not chapter_progress.has(ch_id):
		chapter_progress[ch_id] = {"unlocked": true, "completed": false}
	chapter_progress[ch_id]["completed"] = true
	chapter = max(chapter, int(ch_id) + 1)
	print("[Chapter] 完成章节: %s" % ch_id)
	
	var ch_data: Dictionary = CHAPTER_DEFINITIONS.get(ch_id, {})
	
	# 发放奖励
	var rewards: Dictionary = ch_data.get("rewards", {})
	if rewards.has("money"):
		money += int(rewards["money"])
	var mat_rewards: Dictionary = rewards.get("materials", {})
	for mat_type in mat_rewards:
		if not materials.has(mat_type):
			materials[mat_type] = 0
		materials[mat_type] = int(materials[mat_type]) + int(mat_rewards[mat_type])
	
	# 解锁下一章
	var next_ch: String = str(int(ch_id) + 1)
	if CHAPTER_DEFINITIONS.has(next_ch):
		if not chapter_progress.has(next_ch):
			chapter_progress[next_ch] = {"unlocked": true, "completed": false}
		else:
			chapter_progress[next_ch]["unlocked"] = true
		print("[Chapter] 解锁下一章: %s" % next_ch)
	
	# 推进 NPC 对话
	var npc_unlocks: Dictionary = ch_data.get("unlock_npc_dialogues", {})
	for npc_id in npc_unlocks:
		var min_index: int = int(npc_unlocks[npc_id])
		var current_index: int = int(npc_dialogues.get(npc_id, 0))
		if current_index < min_index:
			npc_dialogues[npc_id] = min_index

func _check_story_progression() -> void:
	"""在目标/任务完成后调用，检查是否需要推进剧情。"""
	check_chapter_completion()

func get_progression_summary() -> Dictionary:
	"""获取整体游戏进度摘要（供 UI 使用）。"""
	var total_missions: int = MissionData.get_all_missions().size()
	var cleared_count: int = 0
	for mid in mission_progress:
		if int(mission_progress[mid].get("clear_count", 0)) > 0:
			cleared_count += 1
	
	var current_chapter_name: String = ""
	for ch_id in CHAPTER_DEFINITIONS:
		var ch_entry: Dictionary = chapter_progress.get(ch_id, {})
		if ch_entry.get("unlocked", false) and not ch_entry.get("completed", false):
			current_chapter_name = CHAPTER_DEFINITIONS[ch_id].get("name", "")
			break
	if current_chapter_name.is_empty():
		current_chapter_name = "全部章节已完成"
	
	return {
		"total_missions": total_missions,
		"cleared_missions": cleared_count,
		"current_chapter": current_chapter_name,
		"chapter_progress": chapter_progress.duplicate(),
		"day": day,
		"pollution": pollution
	}

# ========== 出击费用系统（Mark E.2：策划书 5B.3） ==========

func get_total_sortie_cost() -> Dictionary:
	"""根据当前车辆配装计算出击总费用。"""
	var config: Dictionary = get_vehicle_config(current_vehicle)
	if config == null:
		return {}
	return EquipmentCostData.calc_total_sortie_cost(config)

func can_afford_sortie() -> bool:
	"""检查当前配装能否负担出击费用。"""
	var cost: Dictionary = get_total_sortie_cost()
	if cost.is_empty():
		return true
	return EquipmentCostData.can_afford(cost, money, materials)

func deduct_sortie_cost() -> bool:
	"""扣除出击费用。返回 true 表示扣除成功。"""
	var cost: Dictionary = get_total_sortie_cost()
	if cost.is_empty():
		return true
	if not EquipmentCostData.can_afford(cost, money, materials):
		return false
	for resource_type in cost:
		var amount: int = int(cost[resource_type])
		if resource_type == "money":
			money -= amount
		else:
			if not materials.has(resource_type):
				materials[resource_type] = 0
			materials[resource_type] = int(materials[resource_type]) - amount
	print("[Sortie] 出击费用已扣除: %s" % EquipmentCostData.format_cost(cost))
	return true

func get_sortie_missing_resources() -> Array[String]:
	"""获取出击费用不足的资源列表（供 UI 提示）。"""
	var cost: Dictionary = get_total_sortie_cost()
	return EquipmentCostData.get_missing_resources(cost, money, materials)

# ========== 关卡选择/出击/结算 ==========

func select_mission(mission_id: String) -> bool:
	"""选择关卡出击（基地阶段调用）。"""
	var mission = MissionData.get_mission(mission_id)
	if mission.is_empty():
		return false
	if not is_mission_unlocked(mission_id):
		return false
	if not MissionData.is_phase_allowed(mission, time_phase):
		return false
	var time_cost = MissionData.get_time_cost(mission)
	if time_cost > get_remaining_time_phases():
		return false
	current_mission_id = mission_id
	_hud_mission_text = "待出击：" + mission.get("name", mission_id)
	return true

func get_remaining_time_phases() -> int:
	return max(PHASES_PER_DAY - time_phase + 1, 0)

func start_mission():
	"""进入关卡时调用，重置任务结算状态和局内升级。"""
	mission_resolved = false
	# Roguelike 核心：每局开始时清空上一局的升级
	current_upgrades = {}
	roll_points = 0
	# 重置会话追踪
	session_materials = {}
	session_player_died = false
	session_acquired_upgrades = []
	# 连接升级获取信号（用于追踪当局获得的配件）
	if not GameEvents.ability_upgrade_added.is_connected(_on_session_upgrade_added):
		GameEvents.ability_upgrade_added.connect(_on_session_upgrade_added)
	var mission_name: String = get_current_mission_name()
	if not mission_name.is_empty():
		_hud_mission_text = "执行中：" + mission_name

func _on_session_upgrade_added(upgrade_id: String, _current: Dictionary) -> void:
	"""当局获得升级时记录（用于结算后解锁配件）"""
	if upgrade_id not in session_acquired_upgrades:
		session_acquired_upgrades.append(upgrade_id)

# ========== NPC 对话进度追踪（14.2） ==========

func get_npc_dialogue_index(npc_id: String) -> int:
	"""获取 NPC 当前对话序列索引"""
	return int(npc_dialogues.get(npc_id, 0))

func advance_npc_dialogue(npc_id: String) -> void:
	"""推进 NPC 对话序列索引"""
	var current_idx: int = get_npc_dialogue_index(npc_id)
	npc_dialogues[npc_id] = current_idx + 1
	print("[NPC] %s 对话推进: %d → %d" % [npc_id, current_idx, current_idx + 1])

func get_npc_dialogue_title(npc_id: String, sequence: Array) -> String:
	"""根据 NPC 进度获取当前对话标题。如已看完序列则循环最后一个。"""
	if sequence.is_empty():
		return "start"
	var idx: int = get_npc_dialogue_index(npc_id)
	# 如果超出序列范围，返回最后一个（可重复对话）
	idx = min(idx, sequence.size() - 1)
	return sequence[idx]

func has_new_npc_dialogue(npc_id: String, sequence: Array) -> bool:
	"""检查 NPC 是否有未看过的新对话"""
	if sequence.is_empty():
		return false
	var idx: int = get_npc_dialogue_index(npc_id)
	return idx < sequence.size() - 1

func collect_session_material(material_type: String, amount: int = 1) -> void:
	"""关卡中拾取素材时调用，累加到会话计数器。"""
	if material_type.is_empty():
		return
	if not session_materials.has(material_type):
		session_materials[material_type] = 0
	session_materials[material_type] = int(session_materials[material_type]) + amount

func apply_mission_result(result: String, completed_obj_ids: Array[String] = [], victory_bonus: Dictionary = {}, objective_rewards: Dictionary = {}) -> bool:
	"""结算关卡（胜利/失败均推进时段并应用污染变化）。返回 true 表示首次结算。"""
	if mission_resolved:
		return false
	mission_resolved = true
	var mission: Dictionary = MissionData.get_mission(current_mission_id)
	var time_cost: int = MissionData.get_time_cost(mission)
	_advance_time_phase_by(time_cost)
	if mission.is_empty():
		_apply_pollution_change_for_result(result)
	else:
		pollution = MissionData.calc_pollution_after(pollution, mission, result)
		pollution = max(pollution, 0)
	# 记录通关（含已完成的目标 ID）
	if result == "victory" and not current_mission_id.is_empty():
		record_mission_clear(current_mission_id, 0, completed_obj_ids)
	# 结算信息（供 end_screen 等显示）
	_last_settlement = _build_settlement(result, completed_obj_ids, victory_bonus, objective_rewards)
	# HUD 文本
	var result_text: String = "完成"
	match result:
		"victory":
			result_text = "胜利"
		"defeat":
			result_text = "失败"
		"skip":
			result_text = "跳过"
	var mission_name = get_current_mission_name()
	if mission_name.is_empty():
		_hud_mission_text = "待出击"
	else:
		_hud_mission_text = mission_name + "（" + result_text + "）"
	return true

# ========== 最近一次结算信息（供 end_screen 显示） ==========
var _last_settlement: Dictionary = {}

func get_last_settlement() -> Dictionary:
	"""获取最近一次关卡结算详情（供 end_screen 显示）。"""
	return _last_settlement

func _build_settlement(result: String, completed_obj_ids: Array[String], victory_bonus: Dictionary = {}, objective_rewards: Dictionary = {}) -> Dictionary:
	"""构建结算信息字典并实际发放带出物品。
	- 升级返还能量：品质基准 × 等级 / max(等级上限, 等级) × 10
	- 素材带出：session_materials 按损失比例保留
	- 损失规则：胜利 100%，失败存活损失 10-30%，失败死亡损失 60-90%
	- 胜利奖励：victory_bonus 通关奖励 + objective_rewards 次要目标奖励"""

	# 1. 计算升级返还能量
	var total_upgrade_energy: int = 0
	var upgrade_details: Array[Dictionary] = []
	for upgrade_id in current_upgrades.keys():
		var upgrade_entry: Dictionary = current_upgrades[upgrade_id]
		var level: int = int(upgrade_entry.get("level", 0))
		if level <= 0:
			continue
		var data: Dictionary = _find_upgrade_data(upgrade_id)
		var quality: String = data.get("quality", "white")
		var max_level: int = int(data.get("max_level", -1))
		var base_val: int = QUALITY_BASE_VALUE.get(quality, 1)
		var denominator: int = max(max_level, level) if max_level > 0 else level
		var energy: int = int(float(base_val) * float(level) / float(max(denominator, 1)) * 10.0)
		total_upgrade_energy += energy
		upgrade_details.append({
			"id": upgrade_id,
			"name": data.get("name", upgrade_id),
			"quality": quality,
			"level": level,
			"energy": energy,
		})

	# 2. 计算损失比例
	var keep_ratio: float = 1.0
	var loss_desc: String = ""
	if result == "victory":
		keep_ratio = 1.0
		loss_desc = "胜利：全部带出"
	elif session_player_died:
		var loss: float = randf_range(0.6, 0.9)
		keep_ratio = 1.0 - loss
		loss_desc = "失败（阵亡）：损失 %d%%" % int(loss * 100)
	else:
		var loss: float = randf_range(0.1, 0.3)
		keep_ratio = 1.0 - loss
		loss_desc = "失败（存活）：损失 %d%%" % int(loss * 100)

	# 3. 应用损失比例到能量
	var final_energy: int = int(float(total_upgrade_energy) * keep_ratio)

	# 4. 应用损失比例到素材
	var final_materials: Dictionary = {}
	var raw_materials: Dictionary = session_materials.duplicate()
	for mat_type in raw_materials.keys():
		var raw_count: int = int(raw_materials[mat_type])
		var kept: int = max(int(float(raw_count) * keep_ratio), 0)
		if kept > 0:
			final_materials[mat_type] = kept

	# 5. 实际发放到局外持久化数据
	if final_energy > 0:
		if not materials.has("pollution_energy"):
			materials["pollution_energy"] = 0
		materials["pollution_energy"] = int(materials["pollution_energy"]) + final_energy

	for mat_type in final_materials.keys():
		if not materials.has(mat_type):
			materials[mat_type] = 0
		materials[mat_type] = int(materials[mat_type]) + int(final_materials[mat_type])

	# 6. 解锁配件（Mark E.1：在局内选取过的配件自动解锁）
	var newly_unlocked: Array[String] = []
	for uid in session_acquired_upgrades:
		var udata: Dictionary = _find_upgrade_data(uid)
		if udata.get("upgrade_type", "") == "accessory":
			if not is_parts_unlocked("配件", uid):
				if not unlocked_parts.has("配件"):
					unlocked_parts["配件"] = []
				unlocked_parts["配件"].append(uid)
				newly_unlocked.append(uid)
				print("[Unlock] 配件已解锁: %s (%s)" % [udata.get("name", uid), uid])

	# 7. 处理通关奖励 + 次要目标奖励（仅胜利时发放，不受损失比例影响）
	var victory_bonus_money: int = 0
	var victory_bonus_materials: Dictionary = {}
	var obj_reward_details: Array[Dictionary] = []
	var total_obj_money: int = 0
	var total_obj_materials: Dictionary = {}

	if result == "victory":
		# 基础通关奖励
		victory_bonus_money = int(victory_bonus.get("money", 0))
		var vb_mats: Dictionary = victory_bonus.get("materials", {})
		for mat_type in vb_mats:
			victory_bonus_materials[mat_type] = int(vb_mats[mat_type])

		# 次要目标奖励
		for obj_id in completed_obj_ids:
			if not objective_rewards.has(obj_id):
				continue
			var reward: Dictionary = objective_rewards[obj_id]
			var reward_money: int = int(reward.get("money", 0))
			var reward_mats: Dictionary = reward.get("materials", {})
			var display_name: String = str(reward.get("display_name", obj_id))
			total_obj_money += reward_money
			obj_reward_details.append({
				"obj_id": obj_id,
				"display_name": display_name,
				"money": reward_money,
				"materials": reward_mats.duplicate(),
			})
			for mat_type in reward_mats:
				if not total_obj_materials.has(mat_type):
					total_obj_materials[mat_type] = 0
				total_obj_materials[mat_type] += int(reward_mats[mat_type])

		# 发放通关奖励
		money += victory_bonus_money
		for mat_type in victory_bonus_materials:
			if not materials.has(mat_type):
				materials[mat_type] = 0
			materials[mat_type] = int(materials[mat_type]) + int(victory_bonus_materials[mat_type])

		# 发放次要目标奖励
		money += total_obj_money
		for mat_type in total_obj_materials:
			if not materials.has(mat_type):
				materials[mat_type] = 0
			materials[mat_type] = int(materials[mat_type]) + int(total_obj_materials[mat_type])

	# 断开会话信号
	if GameEvents.ability_upgrade_added.is_connected(_on_session_upgrade_added):
		GameEvents.ability_upgrade_added.disconnect(_on_session_upgrade_added)

	# 8. 构建结算字典
	var settlement: Dictionary = {
		"result": result,
		"mission_id": current_mission_id,
		"completed_obj_ids": completed_obj_ids,
		"player_died": session_player_died,
		"loss_desc": loss_desc,
		"keep_ratio": keep_ratio,
		"total_upgrade_energy_raw": total_upgrade_energy,
		"total_upgrade_energy_final": final_energy,
		"upgrade_details": upgrade_details,
		"raw_materials": raw_materials,
		"final_materials": final_materials,
		"newly_unlocked": newly_unlocked,
		"victory_bonus_money": victory_bonus_money,
		"victory_bonus_materials": victory_bonus_materials,
		"obj_reward_details": obj_reward_details,
		"total_obj_money": total_obj_money,
		"total_obj_materials": total_obj_materials,
	}
	var total_reward_money: int = victory_bonus_money + total_obj_money
	print("[Settlement] %s — mission=%s, energy=%d→%d, materials=%s, rewards=%d金币, loss=%s" % [
		result, current_mission_id, total_upgrade_energy, final_energy,
		str(final_materials), total_reward_money, loss_desc])
	return settlement


func _find_upgrade_data(upgrade_id: String) -> Dictionary:
	"""在 AbilityUpgradeData 中查找升级条目数据"""
	var entry: Variant = AbilityUpgradeData.get_entry(upgrade_id)
	if entry != null and entry is Dictionary:
		return entry as Dictionary
	# fallback：返回白品质默认值
	return {"quality": "white", "max_level": -1, "name": upgrade_id}

func advance_time_without_mission() -> void:
	"""不进行任务时推进一个时间段（仅污染+300）。"""
	_advance_time_phase_by(1)
	_apply_pollution_change_for_result("skip")

func _advance_time_phase_by(steps: int) -> void:
	"""推进时间段：支持消耗多个时段。"""
	var remaining = max(1, steps)
	while remaining > 0:
		time_phase += 1
		if time_phase > PHASES_PER_DAY:
			time_phase = 1
			day += 1
		remaining -= 1

func get_current_mission_name() -> String:
	var mission = MissionData.get_mission(current_mission_id)
	return mission.get("name", "")

func _apply_pollution_change_for_result(result: String) -> void:
	"""污染变化规则（默认）：胜利*90%后+300；失败/不出击+300。"""
	match result:
		"victory":
			pollution = int(floor(pollution * 0.9))
			pollution += BASE_POLLUTION_INCREASE_PER_PHASE
		"defeat", "skip":
			pollution += BASE_POLLUTION_INCREASE_PER_PHASE
		_:
			pollution += BASE_POLLUTION_INCREASE_PER_PHASE
	pollution = max(pollution, 0)

#全局暴击率
func get_global_crit_rate() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_global_crit_rate_bonus"):
		return player.get_global_crit_rate_bonus()
	return 0.0

#end region
