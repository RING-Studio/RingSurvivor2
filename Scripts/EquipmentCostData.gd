extends Node
class_name EquipmentCostData

## 装备出击费用表 — 每次出击按当前配装扣除资源（策划书 5B.3）
## 资源不在装备时扣除，而是在出击时结算
## 配件预升级费用同样在出击时结算（策划书 5B.4）

const MAX_ACCESSORY_LEVEL: int = 3

# ========== 主武器费用 ==========
const WEAPON_COSTS: Dictionary = {
	"machine_gun": {},
	"howitzer": {"money": 300, "scrap_metal": 1},
	"tank_gun": {"money": 500, "scrap_metal": 2},
	"missile": {"money": 600, "scrap_metal": 1, "energy_core": 1},
}

# ========== 装甲费用 ==========
const ARMOR_COSTS: Dictionary = {
}

# ========== 配件费用 ==========
const ACCESSORY_COSTS: Dictionary = {
	# Tier 1 — 基础 (money 100)
	"mine": {"money": 100},
	"smoke_grenade": {"money": 100},
	"spall_liner": {"money": 100},
	"era_block": {"money": 100},
	"ir_counter": {"money": 100},
	"scrap_collector": {"money": 100},
	"cooling_device": {"money": 100},
	# Tier 2 — 中级 (money 200)
	"decoy_drone": {"money": 200},
	"chaff_launcher": {"money": 200},
	"flare_dispenser": {"money": 200},
	"nano_armor": {"money": 200},
	"med_spray": {"money": 200},
	"kinetic_barrier": {"money": 200},
	"fuel_injector_module": {"money": 200},
	"adrenaline_stim": {"money": 200},
	# Tier 3 — 高级 (money 400 + scrap_metal 1)
	"radio_support": {"money": 400, "scrap_metal": 1},
	"laser_suppress": {"money": 400, "scrap_metal": 1},
	"external_missile": {"money": 400, "scrap_metal": 1},
	"cluster_mine": {"money": 400, "scrap_metal": 1},
	"repair_beacon": {"money": 400, "scrap_metal": 1},
	"cryo_canister": {"money": 400, "scrap_metal": 1},
	"incendiary_canister": {"money": 400, "scrap_metal": 1},
	"acid_sprayer": {"money": 400, "scrap_metal": 1},
	"grav_trap": {"money": 400, "scrap_metal": 1},
	"grapeshot_pod": {"money": 400, "scrap_metal": 1},
	# Tier 4 — 顶级 (money 600 + 特殊素材 2)
	"auto_turret": {"money": 600, "scrap_metal": 2},
	"emp_pulse": {"money": 600, "energy_core": 2},
	"shield_emitter": {"money": 600, "energy_core": 2},
	"thunder_coil": {"money": 600, "energy_core": 2},
	"orbital_ping": {"money": 600, "energy_core": 2},
	"ballistic_computer_pod": {"money": 600, "scrap_metal": 2},
	"jammer_field": {"money": 600, "scrap_metal": 2},
	"overwatch_uav": {"money": 600, "scrap_metal": 2},
	"sonar_scanner": {"money": 600, "scrap_metal": 2},
}

# ========== 素材显示名称 ==========
const MATERIAL_DISPLAY_NAMES: Dictionary = {
	"money": "金币",
	"pollution_energy": "污染能量",
	"scarab_chitin": "甲虫甲壳",
	"scrap_metal": "废金属",
	"bio_sample": "生物样本",
	"spore_sample": "孢子样本",
	"acid_gland": "酸液腺",
	"energy_core": "能量核心",
}

# ========== 静态查询接口 ==========

static func get_accessory_total_cost(accessory_id: String, level: int) -> Dictionary:
	"""获取指定配件在指定等级下的出击总费用（基础 + 升级加成）。"""
	var base: Dictionary = ACCESSORY_COSTS.get(accessory_id, {})
	if level <= 1 or base.is_empty():
		return base.duplicate()
	var result: Dictionary = base.duplicate()
	var extra_levels: int = level - 1
	for key in base:
		var base_val: int = int(base[key])
		if key == "money":
			result[key] = base_val + int(base_val * 0.5) * extra_levels
		else:
			result[key] = base_val + base_val * extra_levels
	return result

static func get_weapon_cost(weapon_id: String) -> Dictionary:
	return WEAPON_COSTS.get(weapon_id, {})

static func get_armor_cost(armor_id: String) -> Dictionary:
	return ARMOR_COSTS.get(armor_id, {})

static func get_accessory_cost(accessory_id: String) -> Dictionary:
	return ACCESSORY_COSTS.get(accessory_id, {})

static func get_material_name(material_id: String) -> String:
	return MATERIAL_DISPLAY_NAMES.get(material_id, material_id)

static func calc_total_sortie_cost(vehicle_config: Dictionary) -> Dictionary:
	"""根据车辆配装计算出击总费用。返回 { resource_type: amount }。"""
	var total: Dictionary = {}

	# 主武器费用
	var weapon_id: Variant = vehicle_config.get("主武器类型")
	if weapon_id is String:
		_merge_cost(total, get_weapon_cost(weapon_id))

	# 装甲费用
	var armor_id: Variant = vehicle_config.get("装甲类型")
	if armor_id is String:
		_merge_cost(total, get_armor_cost(armor_id))

	# 配件费用（最多 4 个），含预升级等级加成
	var accessories: Variant = vehicle_config.get("配件", [])
	var acc_levels: Variant = vehicle_config.get("配件等级", {})
	if typeof(acc_levels) != TYPE_DICTIONARY:
		acc_levels = {}
	if accessories is Array:
		for acc_id in accessories:
			if acc_id is String:
				var lv: int = int((acc_levels as Dictionary).get(acc_id, 1))
				_merge_cost(total, get_accessory_total_cost(acc_id, lv))

	return total

static func can_afford(total_cost: Dictionary, money: int, materials: Dictionary) -> bool:
	"""检查玩家是否能承担出击费用。"""
	for resource_type in total_cost:
		var needed: int = int(total_cost[resource_type])
		if needed <= 0:
			continue
		if resource_type == "money":
			if money < needed:
				return false
		else:
			var owned: int = int(materials.get(resource_type, 0))
			if owned < needed:
				return false
	return true

static func get_missing_resources(total_cost: Dictionary, money: int, materials: Dictionary) -> Array[String]:
	"""返回不足的资源描述列表（用于 UI 提示）。"""
	var missing: Array[String] = []
	for resource_type in total_cost:
		var needed: int = int(total_cost[resource_type])
		if needed <= 0:
			continue
		var owned: int = 0
		if resource_type == "money":
			owned = money
		else:
			owned = int(materials.get(resource_type, 0))
		if owned < needed:
			var name: String = get_material_name(resource_type)
			missing.append("%s（需 %d / 拥有 %d）" % [name, needed, owned])
	return missing

static func format_cost(cost: Dictionary) -> String:
	"""将费用字典格式化为可读字符串。"""
	if cost.is_empty():
		return "免费"
	var parts: Array[String] = []
	# money 优先显示
	if cost.has("money"):
		parts.append("%s %d" % [get_material_name("money"), int(cost["money"])])
	for key in cost:
		if key == "money":
			continue
		parts.append("%s %d" % [get_material_name(key), int(cost[key])])
	return ", ".join(parts)

static func _merge_cost(total: Dictionary, cost: Dictionary) -> void:
	for key in cost:
		if not total.has(key):
			total[key] = 0
		total[key] = int(total[key]) + int(cost[key])
