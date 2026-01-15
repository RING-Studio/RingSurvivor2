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

#科技数据(TODO:科技升级的数值可能有bug)
var tech_upgrades: Dictionary

# 能量值(钱)
var money: int = 100000

func init_game():
	"""初始化新游戏数据"""
	# 重置游戏状态
	day = 1
	time_phase = 1
	pollution = 7000  # 初始污染值
	mission_progress = "已解锁"
	chapter = 1
	npc_dialogues = ""
	current_vehicle = 0
	current_skill = ""
	money = 100000

	# 初始化车辆配置 - 设置默认机炮
	vehicles_config = {
		"0": {  # 改进公务车
			"主武器类型": 1,  # 机炮ID=1
			"装甲类型": null,
			"配件": []
		}
	}

	# 初始化解锁内容
	unlocked_vehicles = [0]  # 默认解锁改进公务车
	unlocked_parts = {
		"主武器类型": [1],  # 解锁机炮
		"装甲类型": [],
		"配件": []
	}

	# 初始化升级数据
	current_upgrades = {}
	tech_upgrades = {
		0: 0,  # 引擎
		1: 0,  # 装甲耐久
		2: 0,  # 装甲
		3: 0,  # 攻击力
		4: 0,  # 攻击速度
		5: 0,  # 暴击
		6: 0,  # 爆伤
		7: 0   # 污染转化率
	}

func is_vehicle_unlocked(id:int):
	for vehicle_id in unlocked_vehicles:
		if vehicle_id == id:
			return true
	return false


func is_parts_unlocked(table_name:String, id:int):
	if table_name in unlocked_parts:
		for part_id in unlocked_parts[table_name]:
			if part_id == id:
				return true
	return false

func get_vehicle_config(vehicle_id:int):
	return vehicles_config.get(str(vehicle_id))	
	
func is_equipped( vehicle_id:int, slot:String, part_id:int ):
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
			# return part_id in id
			for part in id:
				if part == part_id:
					return true

	return false

func equip_part( vehicle_id:int, slot:String, part_id:int ):
	if is_equipped( vehicle_id, slot, part_id ):
		return false

	var vehicle_data = get_vehicle_config(vehicle_id)
	if vehicle_data == null:
		vehicles_config[str(vehicle_id)] = {}
		vehicle_data = vehicles_config[str(vehicle_id)]
		
	match slot:
		"装甲类型", "主武器类型":
			vehicle_data[slot] = part_id   # 单装备槽
		"配件":
			if vehicle_data.get("配件") == null:
				vehicle_data["配件"] = []
			
			if vehicle_data["配件"].size() >= 4:
				return
			
			if part_id not in vehicle_data["配件"]:
				vehicle_data["配件"].append(part_id)  # 多装备槽
		_:
			push_warning("未知装备槽: %s" % slot)
	
	return true

func unload_part( vehicle_id:int, slot:String, part_id:int ):
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

func get_player_property(property_name:String):
	var vehicle_config_data = get_vehicle_config(current_vehicle)
	if vehicle_config_data == null:
		return [0, 0, 0, 0] # [装备属性, 装甲属性, 配件属性, 科技属性]

	var equipment_value = 0
	var id = vehicle_config_data.get("主武器类型")
	if id != null:
		var equipment = JsonManager.get_category_by_id("主武器类型", id)
		if equipment != null:
			var tmp = equipment.get(property_name)
			if tmp != null:
				equipment_value = tmp

	var armor_value = 0
	id = vehicle_config_data.get("装甲类型")
	if id != null:
		var armor = JsonManager.get_category_by_id("装甲类型", id)
		if armor != null:
			var tmp = armor.get(property_name)
			if tmp != null:
				armor_value = tmp

	var part_value = 0
	var parts = vehicle_config_data.get("配件")
	if parts != null:
		for part_id in parts:
			var part = JsonManager.get_category_by_id("配件", part_id)
			if part:
				var tmp = part.get(property_name)
				if tmp != null:
					var level = 1
					if current_upgrades.has(int(part_id)):
						level = current_upgrades[int(part_id)]["level"]

					tmp *= level
					part_value += tmp
	
	var tech_value = 0
	var techs : Dictionary[int, Variant] = {}
	for tech in JsonManager.get_category("科研"):
		var tech_id := int(tech["ID"])
		if tech.has(property_name):
			tech_value += float(tech[property_name]) * tech_upgrades[tech_id]

	return [equipment_value, armor_value, part_value, tech_value]

#基础伤害
func get_player_base_damage():
	var values = get_player_property("BaseDamage")
	return values[0] * ( 1.0 + values[1] + values[2] + values[3] )

#基础伤害修改比例
func get_player_base_damage_modifier_ratio():
	var values = get_player_property("BaseDamageModifierRatio")
	return values[0] + values[1] + values[2] + values[3]

#穿甲攻击倍率
func get_player_penetration_attack_multiplier_percent():
	var values = get_player_property("PenetrationAttackMultiplierPercent")
	return values[0] + values[1] + values[2] + values[3]

#软攻倍率
func get_player_soft_attack_multiplier_percent():
	var values = get_player_property("SoftAttackMultiplierPercent")
	return values[0] + values[1] + values[2] + values[3]

#穿深
func get_player_penetration_depth_mm():
	var values = get_player_property("PenetrationDepthMm")
	return values[0] + values[1] + values[2] + values[3]

#装甲厚度
func get_player_armor_thickness():
	var values = get_player_property("ArmorThickness")
	return values[0] + values[1] * (1.0 + values[2] + values[3])

#覆甲率
func get_player_armor_coverage():
	var values = get_player_property("ArmorCoverage")
	return values[0] + values[1] + values[2] + values[3]

#击穿伤害减免
func get_player_armor_damage_reduction_percent():
	var values = get_player_property("ArmorDamageReductionPercent")
	return values[0] + values[1] + values[2] + values[3]

func get_player_max_health():
	var data = JsonManager.get_category_by_id("车辆类型", GameManager.current_vehicle)
	if data == null:
		return 0
	var health = data.get("Health")
	if health == null:
		return 0
	
	return health

#end region
