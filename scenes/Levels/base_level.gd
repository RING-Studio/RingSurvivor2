extends Node
class_name BaseLevel
## 所有战斗关卡的基类。提供：
## - 任务生命周期（start_mission → 胜利/失败 → 结算 → 存档）
## - ObjectiveManager 信号连接
## - 收集物系统（掉落配置 + 拾取转发）
## - 敌人击杀通知路由
## - 暂停/调试模式
## - 升级池初始化
##
## 子类覆写以下方法来定义关卡特有行为：
##   _setup_objectives()  — 配置目标
##   _configure_level()   — 关卡特有初始化
##   _on_enemy_killed_objectives(enemy, is_elite, is_boss, enemy_class) — 击杀计数
##   _on_collectible_collected_objectives(type) — 收集物目标推进
##   _on_area_reached(area_id) — 区域到达事件
##   _get_boss_id_for_objective(obj_id) — 目标对应的 Boss ID

@export var end_screen_scene: PackedScene
@export var objective_manager: ObjectiveManager

var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")

# ========== 收集物系统 ==========
## 格式: [{"type": "energy_core", "color": Color(...), "drop_chance": 0.3, "enemy_filter": ""}]
var _collectible_drops: Array[Dictionary] = []

# ========== 防守据点 ==========
var _outpost: DefendOutpost = null


# ========== 生命周期 ==========

func _ready() -> void:
	GameManager.start_mission()
	var player: Node2D = _get_player()
	if player and player.has_node("HealthComponent"):
		var hc: Node = player.get_node("HealthComponent")
		if hc.has_signal("died"):
			hc.died.connect(_on_player_died)
	Transitions.transition(Transitions.transition_type.Diamond, true)

	# 初始化升级池
	_init_upgrade_manager()

	# 关卡目标配置（子类覆写）
	_setup_objectives()

	# 连接 ObjectiveManager 信号
	if objective_manager:
		objective_manager.all_primary_completed.connect(_on_victory)
		objective_manager.primary_failed.connect(_on_defeat)
		objective_manager.objective_state_changed.connect(_on_objective_changed)

	# 监听收集物拾取（全局信号）
	GameEvents.collectible_collected.connect(_on_collectible_collected)

	# 子类特有初始化
	_configure_level()


func _get_player() -> Node2D:
	"""获取玩家节点（优先 unique name，fallback 到 group）"""
	var p: Node = get_node_or_null("%Player")
	if p:
		return p as Node2D
	return get_tree().get_first_node_in_group("player") as Node2D


func _init_upgrade_manager() -> void:
	var upgrade_manager: Node = get_node_or_null("UpgradeManager")
	if not upgrade_manager:
		return
	var vehicle_config: Dictionary = GameManager.get_vehicle_config(GameManager.current_vehicle)
	var main_weapon_id: Variant = vehicle_config.get("主武器类型", null)
	if main_weapon_id != null:
		upgrade_manager._add_exclusive_upgrades_for_weapon(main_weapon_id)
	upgrade_manager.start_session()


# ========== 虚方法（子类覆写） ==========

func _setup_objectives() -> void:
	"""子类覆写：配置关卡目标"""
	pass

func _configure_level() -> void:
	"""子类覆写：关卡特有初始化（region 检测、特殊机制等）"""
	pass

func _on_enemy_killed_objectives(enemy: Node2D, is_elite: bool, is_boss: bool, enemy_class: String) -> void:
	"""子类覆写：处理击杀目标的逻辑（计数、Boss 完成等）"""
	pass

func _on_collectible_collected_objectives(collectible_type: String) -> void:
	"""子类覆写：收集物拾取后推进目标"""
	pass

func _on_area_reached(area_id: String) -> void:
	"""子类覆写：区域到达事件"""
	pass

func _get_boss_id_for_objective(obj_id: String) -> String:
	"""子类覆写：返回目标对应的 Boss ID，空字符串表示无"""
	return ""


# ========== 胜利/失败 ==========

func _on_victory() -> void:
	"""所有主目标达成"""
	var completed_objs: Array[String] = []
	if objective_manager:
		completed_objs = objective_manager.get_completed_secondary_ids()
	if not GameManager.apply_mission_result("victory", completed_objs):
		return
	GlobalSaveData.save_game()
	var end_screen_instance: Node = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_victory()
	end_screen_instance.show_settlement(GameManager.get_last_settlement())
	MetaProgression.save()


func _on_defeat() -> void:
	"""任意主目标失败"""
	if not GameManager.apply_mission_result("defeat"):
		return
	GlobalSaveData.save_game()
	var end_screen_instance: Node = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	end_screen_instance.show_settlement(GameManager.get_last_settlement())
	MetaProgression.save()


func _on_player_died() -> void:
	GameManager.session_player_died = true
	if not GameManager.apply_mission_result("defeat"):
		return
	GlobalSaveData.save_game()
	var end_screen_instance: Node = end_screen_scene.instantiate()
	add_child(end_screen_instance)
	end_screen_instance.set_defeat()
	end_screen_instance.show_settlement(GameManager.get_last_settlement())
	MetaProgression.save()


func _on_objective_changed(obj_id: String, new_state: String) -> void:
	"""目标状态变化 — 处理 Boss 条件生成等"""
	if new_state == "active":
		_try_spawn_boss_for_objective(obj_id)


# ========== Boss 生成 ==========

func _try_spawn_boss_for_objective(obj_id: String) -> void:
	"""激活 Boss 目标时尝试生成 Boss"""
	var boss_id: String = _get_boss_id_for_objective(obj_id)
	if boss_id.is_empty():
		return
	var enemy_manager: Node = _get_enemy_manager()
	if not enemy_manager or enemy_manager.boss_spawned:
		return
	# 子类可自行决定 Boss 生成条件（如检查区域）
	_try_spawn_boss(boss_id)

func _try_spawn_boss(boss_id: String) -> void:
	"""尝试生成 Boss（子类可覆写加条件）"""
	var enemy_manager: Node = _get_enemy_manager()
	if enemy_manager and not enemy_manager.boss_spawned:
		enemy_manager.spawn_boss(boss_id)

func _get_enemy_manager() -> Node:
	return get_node_or_null("EnemyManager")


# ========== 敌人击杀通知 ==========

func notify_enemy_killed(enemy: Node2D) -> void:
	"""由 EnemyManager 调用：敌人被击杀"""
	# 收集物掉落
	_try_drop_collectible(enemy)

	if not objective_manager or objective_manager.is_finished():
		return

	# 解析敌人属性
	var is_elite: bool = false
	var is_boss: bool = false
	var enemy_class: String = ""

	if enemy:
		var script: GDScript = enemy.get_script() as GDScript
		if script:
			enemy_class = script.get_global_name()
		if enemy.get("enemy_rank") != null:
			var rank: int = int(enemy.enemy_rank)
			is_elite = rank >= 1
			is_boss = rank >= 2

	# 子类处理击杀目标逻辑
	_on_enemy_killed_objectives(enemy, is_elite, is_boss, enemy_class)


# ========== 收集物系统 ==========

func _try_drop_collectible(enemy: Node2D) -> void:
	"""敌人死亡时尝试掉落收集物"""
	if _collectible_drops.is_empty():
		return
	if not is_instance_valid(enemy) or not (enemy is Node2D):
		return

	var enemy_class: String = ""
	var script: GDScript = enemy.get_script() as GDScript
	if script:
		enemy_class = script.get_global_name()

	for config in _collectible_drops:
		var filter: String = str(config.get("enemy_filter", ""))
		if not filter.is_empty() and enemy_class != filter:
			continue
		if randf() > float(config.get("drop_chance", 0.0)):
			continue
		var type: String = str(config.get("type", ""))
		var color: Color = config.get("color", Color.WHITE)
		var offset: Vector2 = Vector2(randf_range(-15, 15), randf_range(-15, 15))
		Collectible.spawn_at(enemy.global_position + offset, type, color, get_tree())


func _on_collectible_collected(collectible_type: String) -> void:
	"""全局收集物拾取回调"""
	# 记录到会话素材（用于结算带出）
	GameManager.collect_session_material(collectible_type)
	if not objective_manager or objective_manager.is_finished():
		return
	_on_collectible_collected_objectives(collectible_type)


# ========== 防守据点通用方法 ==========

func _spawn_outpost_at(pos: Vector2, max_hp: float = 100.0) -> DefendOutpost:
	"""在指定位置生成防守据点"""
	var outpost_scene: PackedScene = load("res://scenes/game_object/defend_outpost/defend_outpost.tscn")
	_outpost = outpost_scene.instantiate() as DefendOutpost
	_outpost.max_health = max_hp
	_outpost.current_health = max_hp
	var entities_layer: Node = get_tree().get_first_node_in_group("entities_layer")
	if entities_layer:
		entities_layer.add_child(_outpost)
	else:
		add_child(_outpost)
	_outpost.global_position = pos
	return _outpost


# ========== 区域检测通用方法 ==========

func _connect_area_signal(area: Area2D, enter_callback: Callable, exit_callback: Callable) -> void:
	"""连接区域进入/退出信号"""
	if area:
		area.body_entered.connect(enter_callback)
		area.body_exited.connect(exit_callback)


func _is_player(body: Node) -> bool:
	return body.is_in_group("player")


func _has_player_in_area(area: Area2D) -> bool:
	if not area:
		return false
	for body in area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false


# ========== 暂停 ==========

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		add_child(pause_menu_scene.instantiate())
		get_tree().root.set_input_as_handled()
