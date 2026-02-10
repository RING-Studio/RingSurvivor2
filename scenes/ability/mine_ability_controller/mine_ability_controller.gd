extends Node
class_name MineAbilityController

@export var mine_scene: PackedScene
@export var base_cooldown: float = 3.0  # 基础装填间隔（秒）
@export var base_explosion_radius: float = 48.0  # 基础爆炸范围（像素，3米 * 16像素/米）
@export var base_damage: float = 5.0  # 基础伤害（每级5点）

var mine_timer: Timer
var deployed_mines: Array[Node2D] = []  # 已部署的地雷列表（FIFO队列）

func _ready():
	mine_timer = Timer.new()
	var interval := _get_load_interval_seconds()
	if not is_inf(interval):
		mine_timer.wait_time = interval
		mine_timer.autostart = true
	mine_timer.timeout.connect(_on_timer_timeout)
	add_child(mine_timer)
	if not is_inf(interval):
		mine_timer.start()
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)

func _get_load_interval_seconds() -> float:
	"""装填间隔（秒）= 基础间隔 / 装填速度倍率；速度倍率 = 1 + 装填速度加成（百分比）。若倍率≤0 则返回 INF（不触发）。"""
	var base_interval_seconds := base_cooldown
	
	# 地雷·AT：装填间隔 +5秒（方案1：加在基础上再除以倍率）
	var anti_tank_level = GameManager.current_upgrades.get("mine_anti_tank", {}).get("level", 0)
	if anti_tank_level > 0:
		base_interval_seconds += 5.0
	
	# 地雷·装填速度：+15% per level（倍率加成，与射速一致）
	var load_speed_bonus := 0.0
	var cooldown_level = GameManager.current_upgrades.get("mine_cooldown", {}).get("level", 0)
	if cooldown_level > 0:
		load_speed_bonus += UpgradeEffectManager.get_effect("mine_cooldown", cooldown_level)
	
	var speed_multiplier := 1.0 + load_speed_bonus
	if speed_multiplier <= 0.0:
		return INF  # 倍率为零或负时不再装填
	var interval := base_interval_seconds / speed_multiplier
	return max(interval, 0.1)  # 最小 0.1 秒，避免除零或过密

func _get_mines_per_deploy() -> int:
	"""每次装填触发时部署的地雷数量"""
	var level = GameManager.current_upgrades.get("mine_multi_deploy", {}).get("level", 0)
	return max(1 + level, 1)

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
	
	# 地雷·布雷：基础伤害 -1 per level（在AT倍率前生效）
	var multi_deploy_level = GameManager.current_upgrades.get("mine_multi_deploy", {}).get("level", 0)
	if multi_deploy_level > 0:
		damage -= float(multi_deploy_level)
		damage = max(damage, 1.0)
	
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
	
	var deploy_count := _get_mines_per_deploy()
	for i in range(deploy_count):
		# 检查部署上限（逐个处理，避免一次性部署超过上限）
		var max_deployed = _get_max_deployed()
		if deployed_mines.size() >= max_deployed:
			# 触发最早的地雷爆炸
			var oldest_mine = deployed_mines[0]
			if is_instance_valid(oldest_mine):
				oldest_mine.trigger_explosion()
			deployed_mines.remove_at(0)
		
		# 部署新地雷（多枚时做轻微散布，避免完全重叠）
		var offset = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 16.0)
		_deploy_mine(player.global_position + offset)
	
	# 更新计时器（若间隔为 INF 则不重启，等效不装填）
	var interval := _get_load_interval_seconds()
	if is_inf(interval):
		return
	mine_timer.wait_time = interval
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
	if upgrade_id in ["mine", "mine_cooldown", "mine_anti_tank"]:
		var interval := _get_load_interval_seconds()
		if is_inf(interval):
			mine_timer.stop()
		else:
			mine_timer.wait_time = interval
			mine_timer.start()
