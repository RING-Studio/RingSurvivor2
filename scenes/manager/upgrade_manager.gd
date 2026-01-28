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
	
	# 获取已装备的配件（局内+局外）
	var equipped_accessories = session_equipped_accessories.duplicate()
	# 如果支持局外携带，也需要从vehicle_config读取
	var vehicle_accessories = vehicle_config.get("配件", [])
	# 将局外配件ID转换为字符串ID（如果需要）
	# TODO: 如果局外配件使用数字ID，需要转换为字符串ID
	
	# 遍历数据库，决定哪些加入局内池
	for upgrade_id in upgrade_database:
		var entry = upgrade_database[upgrade_id]
		var exclusive_for = entry.get("exclusive_for", "")
		
		# 检查专属条件
		var should_add = true
		if exclusive_for == "mg":
			should_add = (main_weapon_id == 1)  # 机炮ID=1
		elif exclusive_for == "mine":
			should_add = ("mine" in equipped_accessories)
		
		if should_add:
			var quality = entry.get("quality", "white")
			var current_level = GameManager.current_upgrades.get(upgrade_id, {}).get("level", 0)
			var max_level = entry.get("max_level", -1)
			
			# 未满级才加入
			if max_level == -1 or current_level < max_level:
				active_pools[quality].add_item(upgrade_id, 1)

func start_session():
	"""开始新对局时调用"""
	session_equipped_accessories.clear()
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
			
			# 添加该配件的专属强化到池中
			_add_exclusive_upgrades_for_accessory(upgrade_id)
		else:
			# 已拥有，升级
			GameManager.current_upgrades[upgrade_id]["level"] += 1
	else:
		# 处理强化
		GameManager.current_upgrades[upgrade_id]["level"] += 1
	
	# 检查是否满级，从局内池移除
	var max_level = entry.get("max_level", 0)
	if max_level != -1 and GameManager.current_upgrades[upgrade_id]["level"] >= max_level:
		var quality = entry.get("quality", "white")
		active_pools[quality].remove_item(upgrade_id)
	
	# 处理互斥逻辑
	_handle_fire_direction_exclusivity(upgrade_id)
	
	# 每次升级增加1个roll点
	GameManager.roll_points += 1
	
	GameEvents.emit_ability_upgrade_added(upgrade_id, GameManager.current_upgrades)

func _add_exclusive_upgrades_for_accessory(accessory_id: String):
	"""当玩家选择配件后，将其专属强化加入局内池"""
	if not database_initialized:
		initialize_database()
	
	for upgrade_id in upgrade_database:
		var entry = upgrade_database[upgrade_id]
		if entry.get("exclusive_for", "") == accessory_id:
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

func _add_exclusive_upgrades_for_weapon(weapon_id: int):
	"""当玩家装备主武器后，将其专属强化加入局内池"""
	if not database_initialized:
		initialize_database()
	
	var exclusive_prefix = ""
	match weapon_id:
		1:  # 机炮
			exclusive_prefix = "mg"
		# 其他武器...
	
	if exclusive_prefix == "":
		return
	
	for upgrade_id in upgrade_database:
		var entry = upgrade_database[upgrade_id]
		if entry.get("exclusive_for", "") == exclusive_prefix:
			var quality = entry.get("quality", "white")
			var current_level = GameManager.current_upgrades.get(upgrade_id, {}).get("level", 0)
			var max_level = entry.get("max_level", -1)
			
			var already_in_pool = false
			for item in active_pools[quality].items:
				if item["item"] == upgrade_id:
					already_in_pool = true
					break
			
			if not already_in_pool and (max_level == -1 or current_level < max_level):
				active_pools[quality].add_item(upgrade_id, 1)

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


func _handle_fire_direction_exclusivity(selected_upgrade_id: String):
	"""处理射击方向变更强化的互斥逻辑"""
	# 顺时针类：扫射(sweep_fire)和风车(windmill)
	var clockwise_upgrades = ["sweep_fire", "windmill"]
	# 随机类：乱射(chaos_fire)
	var random_upgrades = ["chaos_fire"]
	
	# 检查选择了哪种类型
	var selected_is_clockwise = selected_upgrade_id in clockwise_upgrades
	var selected_is_random = selected_upgrade_id in random_upgrades
	
	if selected_is_clockwise:
		# 选择了顺时针类，移除随机类
		for random_id in random_upgrades:
			_remove_upgrade_from_pools(random_id)
	elif selected_is_random:
		# 选择了随机类，移除顺时针类
		for clockwise_id in clockwise_upgrades:
			_remove_upgrade_from_pools(clockwise_id)

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
