extends Node

@export var experience_manager: Node
@export var upgrade_screen_scene: PackedScene

# 升级池数据库：存储所有升级条目（包括专属强化）
var upgrade_database: Dictionary = {}
var database_initialized: bool = false

# 局内升级池：当前对局中实际可抽取的升级
var active_pools: Dictionary = {
	"white": WeightedTable.new(),
	"blue": WeightedTable.new(),
	"purple": WeightedTable.new(),
	"red": WeightedTable.new()
}

# 已装备的配件列表（局内）
var session_equipped_accessories: Array[String] = []

# 冷却类配件（用于决定“冷却装置”是否应进入升级池）
# 说明：当前版本尚未完整落地这些配件，因此 cooling_device 会被自动隐藏，避免出现“无效果升级”。
const COOLDOWN_ACCESSORY_IDS: Array[String] = [
	"radio_support",
	"laser_suppress",
	"external_missile",
]

func _ready():
	# 初始化数据库（全局，只初始化一次）
	initialize_database()
	GameEvents.level_up.connect(on_level_up)

func initialize_database():
	"""初始化升级数据库（所有升级条目，包括专属强化）"""
	if database_initialized:
		return
	
	for entry in AbilityUpgradeData.entries:
		var upgrade_id = entry["id"]
		upgrade_database[upgrade_id] = entry.duplicate()
		if not GameManager.current_upgrades.has(upgrade_id):
			GameManager.current_upgrades[upgrade_id] = {"level": 0}
	
	database_initialized = true

func initialize_active_pools():
	"""初始化局内升级池（根据当前装备状态）"""
	# 清空现有池子
	for quality in active_pools:
		active_pools[quality] = WeightedTable.new()
	
	# 获取当前主武器（从vehicle_config或session状态）
	var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
	var main_weapon_id = vehicle_config.get("主武器类型", null)
	
	# 已装备的配件 = 带入的（从 vehicle_config 读）+ 局内选的（session）
	var brought_in: Array = vehicle_config.get("配件", [])
	var equipped_accessories: Array = []
	for a in brought_in:
		if a is String:
			equipped_accessories.append(a)
	for a in session_equipped_accessories:
		equipped_accessories.append(a)
	
	# 遍历数据库，决定哪些加入局内池
	for upgrade_id in upgrade_database:
		var entry = upgrade_database[upgrade_id]
		var exclusive_for = entry.get("exclusive_for", "")
		
		# 检查专属条件
		var should_add = true
		if exclusive_for != "":
			if exclusive_for == "mg":
				# 主武器专属：检查是否装备了对应主武器
				should_add = (main_weapon_id == "machine_gun")
			else:
				# 通用前置检查：检查前置升级/配件是否已拥有（level > 0）
				var parent_level = GameManager.current_upgrades.get(exclusive_for, {}).get("level", 0)
				if parent_level <= 0:
					# 也检查是否在已装备配件中
					should_add = (exclusive_for in equipped_accessories)
		
		# 冷却装置：仅当存在【冷却类】配件时才进入池（避免当前版本出现无效升级）
		if should_add and upgrade_id == "cooling_device":
			var has_cooldown_accessory := false
			for accessory_id in equipped_accessories:
				if accessory_id in COOLDOWN_ACCESSORY_IDS:
					has_cooldown_accessory = true
					break
			should_add = has_cooldown_accessory
		
		if should_add:
			var quality = entry.get("quality", "white")
			var current_level = GameManager.current_upgrades.get(upgrade_id, {}).get("level", 0)
			var max_level = entry.get("max_level", -1)
			
			# 未满级才加入
			if max_level == -1 or current_level < max_level:
				active_pools[quality].add_item(upgrade_id, 1)

func equip_brought_in_accessories():
	"""读取当前车辆配装中的「带入配件」，写入 current_upgrades 并加入专属池。不写入 session。"""
	var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
	if vehicle_config == null:
		return
	var brought_in: Array = vehicle_config.get("配件", [])
	for accessory_id in brought_in:
		if accessory_id is not String:
			push_error("配件 id 必须为 String，实际类型: %s" % typeof(accessory_id))
			continue
		var level: int = GameManager.get_brought_in_accessory_level(GameManager.current_vehicle, accessory_id)
		GameManager.current_upgrades[accessory_id] = {"level": level}
		_add_exclusive_upgrades_for(accessory_id)

func start_session():
	"""开始新对局时调用：清空 session，用独立函数装备带入配件，再初始化池。"""
	if not database_initialized:
		initialize_database()
	session_equipped_accessories.clear()
	equip_brought_in_accessories()
	initialize_active_pools()

func get_session_equipped_accessories() -> Array[String]:
	"""获取局内已装备的配件列表"""
	return session_equipped_accessories

func apply_upgrade(upgrade_id: String):
	if not database_initialized:
		initialize_database()
	
	if not GameManager.current_upgrades.has(upgrade_id):
		GameManager.current_upgrades[upgrade_id] = {"level": 0}

	var entry = upgrade_database.get(upgrade_id)
	if entry == null:
		push_warning("无法找到升级数据: %s" % upgrade_id)
		return
	
	var upgrade_type = entry.get("upgrade_type", "enhancement")
	
	# 处理配件
	if upgrade_type == "accessory":
		if upgrade_id not in session_equipped_accessories:
			# 首次获得配件
			session_equipped_accessories.append(upgrade_id)
			GameManager.current_upgrades[upgrade_id]["level"] = 1
		else:
			# 已拥有，升级
			GameManager.current_upgrades[upgrade_id]["level"] += 1
	else:
		# 处理强化
		GameManager.current_upgrades[upgrade_id]["level"] += 1
	
	# 添加该升级的衍生强化到池中（通用：配件、强化均适用）
	_add_exclusive_upgrades_for(upgrade_id)
	
	# 检查是否满级，从局内池移除
	var max_level = entry.get("max_level", 0)
	if max_level != -1 and GameManager.current_upgrades[upgrade_id]["level"] >= max_level:
		var quality = entry.get("quality", "white")
		active_pools[quality].remove_item(upgrade_id)
	
	# 处理定向词条互斥逻辑
	_handle_prefix_exclusivity(upgrade_id)
	
	# 每次升级增加1个roll点
	GameManager.roll_points += 1
	
	GameEvents.emit_ability_upgrade_added(upgrade_id, GameManager.current_upgrades)

func _add_exclusive_upgrades_for(parent_id: String):
	"""当玩家选择某升级后，将以它为前置（exclusive_for）的衍生强化加入局内池。
	适用于配件、强化等任何类型的升级。"""
	if not database_initialized:
		initialize_database()
	
	for upgrade_id in upgrade_database:
		var entry = upgrade_database[upgrade_id]
		if entry.get("exclusive_for", "") == parent_id:
			var quality = entry.get("quality", "white")
			var current_level = GameManager.current_upgrades.get(upgrade_id, {}).get("level", 0)
			var max_level = entry.get("max_level", -1)
			
			# 检查是否已在池中（避免重复添加）
			var already_in_pool = false
			for item in active_pools[quality].items:
				if item["item"] == upgrade_id:
					already_in_pool = true
					break
			
			if not already_in_pool and (max_level == -1 or current_level < max_level):
				active_pools[quality].add_item(upgrade_id, 1)

func _add_exclusive_upgrades_for_weapon(weapon_id: Variant):
	"""当玩家装备主武器后，将其专属强化加入局内池。weapon_id 为英文 id 字符串，如 machine_gun。"""
	if not database_initialized:
		initialize_database()
	
	var exclusive_prefix = ""
	if weapon_id is String:
		match weapon_id:
			"machine_gun":
				exclusive_prefix = "mg"
			# "howitzer", "tank_gun", "missile" 等可在此扩展
	
	if exclusive_prefix == "":
		return
	
	_add_exclusive_upgrades_for(exclusive_prefix)

func _get_quality_probabilities(current_level: int) -> Dictionary:
	"""
	计算品质概率分布
	基础：白:蓝:紫:红 = 85:13:2:0
	50级及以上固定：白:蓝:紫:红 = 30:40:20:10
	线性增长
	"""
	var level_factor = min(float(current_level) / 50.0, 1.0)
	
	var white_prob = 85.0 - (level_factor * 55.0)  # 85 -> 30
	var blue_prob = 13.0 + (level_factor * 27.0)   # 13 -> 40
	var purple_prob = 2.0 + (level_factor * 18.0)  # 2 -> 20
	var red_prob = 0.0 + (level_factor * 10.0)      # 0 -> 10
	
	return {
		"white": white_prob,
		"blue": blue_prob,
		"purple": purple_prob,
		"red": red_prob
	}

func _get_available_qualities() -> Array[String]:
	"""获取有可用升级的品质列表"""
	var available: Array[String] = []
	for quality in ["white", "blue", "purple", "red"]:
		if active_pools[quality].items.size() > 0:
			available.append(quality)
	return available

func _pick_quality(probabilities: Dictionary, available_qualities: Array[String]) -> String:
	"""根据概率分布和可用品质，随机选择一个品质"""
	if available_qualities.size() == 0:
		push_error("所有品质池都为空！")
		return ""
	
	# 只计算可用品质的总权重
	var total_weight = 0.0
	for quality in available_qualities:
		total_weight += probabilities[quality]
	
	if total_weight <= 0:
		# 如果总权重为0，随机选择一个可用品质
		return available_qualities[randi() % available_qualities.size()]
	
	var chosen_weight = randf() * total_weight
	var iteration_sum = 0.0
	
	for quality in available_qualities:
		iteration_sum += probabilities[quality]
		if chosen_weight <= iteration_sum:
			return quality
	
	# 兜底：返回第一个可用品质
	return available_qualities[0]

func _pick_quality_with_retry(current_level: int, exclude: Array[String], max_retries: int = 10) -> String:
	"""判定品质，如果品质池为空则重试"""
	var probabilities = _get_quality_probabilities(current_level)
	var available_qualities = _get_available_qualities()
	
	if available_qualities.size() == 0:
		push_error("所有品质池都为空，无法选择升级！")
		return ""
	
	for retry in range(max_retries):
		var quality = _pick_quality(probabilities, available_qualities)
		
		# 检查该品质池中是否有不在exclude中的升级
		var pool = active_pools[quality]
		var has_available = false
		for item in pool.items:
			if item["item"] not in exclude:
				has_available = true
				break
		
		if has_available:
			return quality
		
		# 如果该品质池中没有可用升级，从可用列表中移除并重试
		available_qualities.erase(quality)
		if available_qualities.size() == 0:
			break
	
	# 如果所有重试都失败，返回第一个有可用升级的品质（忽略概率）
	available_qualities = _get_available_qualities()
	for quality in available_qualities:
		var pool = active_pools[quality]
		for item in pool.items:
			if item["item"] not in exclude:
				return quality
	
	push_error("无法找到可用的升级！")
	return ""

func pick_upgrades() -> Array[Dictionary]:
	"""从局内升级池中抽取（不再过滤）"""
	var chosen_upgrades: Array[Dictionary] = []
	var exclude: Array[String] = []
	
	# 获取当前玩家等级
	var current_level = 1
	if experience_manager != null:
		current_level = experience_manager.current_level
	
	for i in 3:
		# 判定品质
		var quality = _pick_quality_with_retry(current_level, exclude)
		if quality == "":
			break
		
		# 从局内池中抽取
		var chosen_id = active_pools[quality].pick_item(exclude)
		if chosen_id == null:
			break
		
		exclude.append(chosen_id)
		var entry = upgrade_database.get(chosen_id)
		if entry != null:
			chosen_upgrades.append(entry)
	
	return chosen_upgrades


func _handle_prefix_exclusivity(selected_upgrade_id: String):
	"""处理定向词条的互斥逻辑：选择带 prefix 的升级后，移除同 prefix 的其他升级"""
	var selected_entry = upgrade_database.get(selected_upgrade_id)
	if selected_entry == null:
		return
	
	var selected_prefix = selected_entry.get("prefix", "")
	if selected_prefix == "":
		return
	
	# 遍历数据库，移除同 prefix 但不同 id 的升级
	for upgrade_id in upgrade_database:
		if upgrade_id == selected_upgrade_id:
			continue
		var entry = upgrade_database[upgrade_id]
		var other_prefix = entry.get("prefix", "")
		if other_prefix == selected_prefix:
			_remove_upgrade_from_pools(upgrade_id)

func _remove_upgrade_from_pools(upgrade_id: String):
	"""从所有品质池中移除指定的强化"""
	var entry = upgrade_database.get(upgrade_id)
	if entry == null:
		return
	
	var quality = entry.get("quality", "white")
	active_pools[quality].remove_item(upgrade_id)

func on_upgrade_selected(upgrade: String):
	apply_upgrade(upgrade)
	
func on_level_up(current_level: int):
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	var chosen_upgrades = pick_upgrades()
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades)
	upgrade_screen_instance.set_upgrade_manager(self)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)
