extends Node

@export var experience_manager: Node
@export var upgrade_screen_scene: PackedScene

# 按品质分池存储升级
var quality_pools: Dictionary = {
	"white": WeightedTable.new(),
	"blue": WeightedTable.new(),
	"purple": WeightedTable.new(),
	"red": WeightedTable.new()
}

var upgrade_catalog: Dictionary = {}

func _ready():
	# 按品质分类初始化升级池
	for entry in AbilityUpgradeData.entries:
		var upgrade_id = entry["id"]
		var quality = entry.get("quality", "white")
		upgrade_catalog[upgrade_id] = entry.duplicate()
		# 同品质内等概率抽取，权重统一为1
		quality_pools[quality].add_item(upgrade_id, 1)
		if not GameManager.current_upgrades.has(upgrade_id):
			GameManager.current_upgrades[upgrade_id] = {"level": 0}

	GameEvents.level_up.connect(on_level_up)

func apply_upgrade(upgrade_id: String):
	if not GameManager.current_upgrades.has(upgrade_id):
		GameManager.current_upgrades[upgrade_id] = {"level": 0}

	GameManager.current_upgrades[upgrade_id]["level"] += 1

	var entry = upgrade_catalog.get(upgrade_id)
	if entry == null:
		push_warning("无法找到强化数据: %s" % upgrade_id)
		return

	var max_level = entry.get("max_level", 0)
	# max_level 为 -1 时表示无限升级，不移除
	if max_level != -1 and GameManager.current_upgrades[upgrade_id]["level"] >= max_level:
		var quality = entry.get("quality", "white")
		quality_pools[quality].remove_item(upgrade_id)

	# 处理射击方向变更的互斥逻辑
	_handle_fire_direction_exclusivity(upgrade_id)

	# 每次升级增加1个roll点
	GameManager.roll_points += 1

	GameEvents.emit_ability_upgrade_added(upgrade_id, GameManager.current_upgrades)

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
		if quality_pools[quality].items.size() > 0:
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
		var pool = quality_pools[quality]
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
		var pool = quality_pools[quality]
		for item in pool.items:
			if item["item"] not in exclude:
				return quality
	
	push_error("无法找到可用的升级！")
	return ""

func pick_upgrades() -> Array[Dictionary]:
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
		
		# 从对应品质池中抽取
		var chosen_id = quality_pools[quality].pick_item(exclude)
		if chosen_id == null:
			break
		
		exclude.append(chosen_id)
		var entry = upgrade_catalog.get(chosen_id)
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
	var entry = upgrade_catalog.get(upgrade_id)
	if entry == null:
		return
	
	var quality = entry.get("quality", "white")
	quality_pools[quality].remove_item(upgrade_id)

func on_upgrade_selected(upgrade: String):
	apply_upgrade(upgrade)
	
func on_level_up(current_level: int):
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	var chosen_upgrades = pick_upgrades()
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades)
	upgrade_screen_instance.set_upgrade_manager(self)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)
