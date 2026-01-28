extends Node
class_name MineAbilityController

@export var mine_scene: PackedScene
@export var base_cooldown: float = 3.0  # 基础冷却时间（秒）
@export var base_explosion_radius: float = 48.0  # 基础爆炸范围（像素，3米 * 16像素/米）
@export var base_damage: float = 5.0  # 基础伤害（每级5点）

var mine_timer: Timer
var deployed_mines: Array[Node2D] = []  # 已部署的地雷列表（FIFO队列）

func _ready():
	mine_timer = Timer.new()
	mine_timer.wait_time = _get_cooldown()
	mine_timer.timeout.connect(_on_timer_timeout)
	mine_timer.autostart = true
	add_child(mine_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)

func _get_cooldown() -> float:
	"""计算当前冷却时间"""
	var cooldown = base_cooldown
	var mine_level = GameManager.current_upgrades.get("mine", {}).get("level", 0)
	
	# 地雷·冷却：-15% per level
	var cooldown_reduction = 0.0
	var cooldown_level = GameManager.current_upgrades.get("mine_cooldown", {}).get("level", 0)
	if cooldown_level > 0:
		cooldown_reduction += UpgradeEffectManager.get_effect("mine_cooldown", cooldown_level)
	
	# 地雷·AT：+5秒
	var anti_tank_level = GameManager.current_upgrades.get("mine_anti_tank", {}).get("level", 0)
	if anti_tank_level > 0:
		cooldown += 5.0
	
	# 全局配件冷却：-15% per level
	var cooling_device_level = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	if cooling_device_level > 0:
		cooldown_reduction += UpgradeEffectManager.get_effect("cooling_device", cooling_device_level)
	
	cooldown *= (1.0 - cooldown_reduction)
	return max(cooldown, 0.1)  # 最小0.1秒

func _get_max_deployed() -> int:
	"""获取最大部署数量"""
	var mine_level = GameManager.current_upgrades.get("mine", {}).get("level", 0)
	# 如果level为0，说明刚选择，应该是1级
	if mine_level == 0:
		mine_level = 1
	return 10 + 5 * mine_level

func _get_explosion_radius() -> float:
	"""获取爆炸范围"""
	var radius = base_explosion_radius
	var range_level = GameManager.current_upgrades.get("mine_range", {}).get("level", 0)
	if range_level > 0:
		radius += UpgradeEffectManager.get_effect("mine_range", range_level) * GlobalFomulaManager.METERS_TO_PIXELS  # 转换为像素（1米=16像素）
	return radius

func _get_base_damage() -> float:
	"""获取基础伤害"""
	var mine_level = GameManager.current_upgrades.get("mine", {}).get("level", 0)
	# 如果level为0，说明刚选择，应该是1级
	if mine_level == 0:
		mine_level = 1
	var damage = base_damage * mine_level
	
	# 地雷·AT：+200% per level
	var anti_tank_level = GameManager.current_upgrades.get("mine_anti_tank", {}).get("level", 0)
	if anti_tank_level > 0:
		var multiplier = UpgradeEffectManager.get_effect("mine_anti_tank", anti_tank_level)
		damage *= (1.0 + multiplier)
	
	return damage

func _on_timer_timeout():
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	
	# 检查部署上限
	var max_deployed = _get_max_deployed()
	if deployed_mines.size() >= max_deployed:
		# 触发最早的地雷爆炸
		var oldest_mine = deployed_mines[0]
		if is_instance_valid(oldest_mine):
			oldest_mine.trigger_explosion()
		deployed_mines.remove_at(0)
	
	# 部署新地雷
	_deploy_mine(player.global_position)
	
	# 更新计时器
	mine_timer.wait_time = _get_cooldown()
	mine_timer.start()

func _deploy_mine(position: Vector2):
	"""部署地雷"""
	var mine_instance = mine_scene.instantiate()
	# 实例化到foreground_layer，与机炮子弹一致
	get_tree().get_first_node_in_group("foreground_layer").add_child(mine_instance)
	mine_instance.global_position = position
	mine_instance.setup(
		_get_explosion_radius(),
		_get_base_damage(),
		GameManager.current_upgrades.get("mine_anti_tank", {}).get("level", 0) > 0
	)
	mine_instance.exploded.connect(_on_mine_exploded)
	deployed_mines.append(mine_instance)

func _on_mine_exploded(mine: Node2D):
	"""地雷爆炸回调"""
	deployed_mines.erase(mine)

func _on_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	"""升级添加时更新"""
	if upgrade_id in ["mine", "mine_cooldown", "mine_anti_tank", "cooling_device"]:
		mine_timer.wait_time = _get_cooldown()
		mine_timer.start()
