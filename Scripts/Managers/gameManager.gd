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

# 任务进度/流程进度（已完成、已解锁、未解锁）
var mission_progress :String= "已解锁"

var chapter :int= 1

# NPC对话进度
var npc_dialogues : String = ""

# 当前选中车辆
var current_vehicle: int = 0

# 当前选中技能（被动效果）
var current_skill: String = ""

# 每辆车目前的配置方案
var vehicles_config : = {
	
}

var unlocked_vehicles := [0]

var unlocked_parts := {
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

# 科技已移除，保留空字典避免 TechScene 等引用报错
var tech_upgrades: Dictionary = {}

func init_game():
	"""初始化新游戏数据"""
	# 重置游戏状态
	day = 1
	time_phase = 1
	pollution = 7000
	mission_progress = "已解锁"
	chapter = 1
	npc_dialogues = ""
	current_vehicle = 0
	current_skill = ""
	money = 100000

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
	"""带入配件的等级。当前固定为 1；之后可从 vehicles_config[vehicle_id][\"配件等级\"][accessory_id] 读取。"""
	var config = get_vehicle_config(vehicle_id)
	if config == null:
		return 1
	var levels = config.get("配件等级", {})
	if typeof(levels) != TYPE_DICTIONARY:
		return 1
	return int(levels.get(accessory_id, 1))

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

#全局暴击率
func get_global_crit_rate() -> float:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_global_crit_rate_bonus"):
		return player.get_global_crit_rate_bonus()
	return 0.0

#end region
