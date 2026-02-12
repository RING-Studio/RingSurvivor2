extends Node
class_name WeaponUpgradeHandler

# 单例访问
static var instance: WeaponUpgradeHandler

# 强化状态
var chain_fire_stacks: int = 0
var burst_fire_stacks: int = 0
var overload_stacks: int = 0
var scatter_shot_counter: int = 0
var lethal_strike_counter: int = 0
var lethal_strike_active: bool = false
var focus_target: Node2D = null
var focus_stacks: int = 0
var breath_hold_timer: float = 0.0
var last_shot_time: float = 0.0
var sweep_fire_angle: float = 0.0
var sweep_fire_update_timer: float = 0.0
var sweep_fire_angular_velocity: float = 0.0  # 度/秒，带符号
var windmill_angle: float = 0.0

# 阶段八：新增强化状态
var weakpoint_strike_counter: int = 0  # 弱点打击连续命中计数
var weakpoint_strike_target: Node2D = null
var kill_chain_active_until_msec: int = 0  # 击杀链激活截止时间
var _bleed_stacks: Dictionary = {}  # enemy_id -> {stacks: int, timer: Timer}

# 计时器
var chain_fire_timer: Timer
var burst_fire_timer: Timer
var overload_timer: Timer
var focus_timer: Timer

func _ready():
	instance = self
	_setup_timers()
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)

# ========== 射速相关接口 ==========

func get_fire_rate_modifier() -> float:
	"""获取射速修正值（累加所有射速加成）"""
	var modifier = 0.0
	var current_upgrades = GameManager.current_upgrades
	
	# 速射
	var rapid_level = current_upgrades.get("rapid_fire", {}).get("level", 0)
	if rapid_level > 0:
		modifier += 0.05 * rapid_level
	
	# 连射（基础减益 + 层数加成）
	var chain_level = current_upgrades.get("chain_fire", {}).get("level", 0)
	if chain_level > 0:
		modifier -= 0.05 * chain_level  # 基础减益
		modifier += float(chain_fire_stacks) * 0.03  # 层数加成
	
	# 爆射（层数加成）
	modifier += float(burst_fire_stacks) * 0.04
	
	# 扫射
	var sweep_level = current_upgrades.get("sweep_fire", {}).get("level", 0)
	if sweep_level > 0:
		modifier += 0.50 * sweep_level
	
	# 乱射
	var chaos_level = current_upgrades.get("chaos_fire", {}).get("level", 0)
	if chaos_level > 0:
		modifier += 1.0
	
	# 破竹
	var breakthrough_level = current_upgrades.get("breakthrough", {}).get("level", 0)
	if breakthrough_level > 0:
		var enemies = get_tree().get_nodes_in_group("enemy")
		var enemy_count = enemies.size()
		if enemy_count > 0:
			var max_bonus = 0.25 * breakthrough_level
			modifier += max_bonus / float(enemy_count)
		else:
			modifier += 0.25 * breakthrough_level
	
	# 火力压制
	var suppression_level = current_upgrades.get("fire_suppression", {}).get("level", 0)
	if suppression_level > 0:
		var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
		if vehicle_config != null:
			var parts = vehicle_config.get("配件", [])
			var part_count = parts.size() if parts != null else 0
			modifier += 0.05 * suppression_level * float(part_count)
	
	# 风车（减益）
	var windmill_level = current_upgrades.get("windmill", {}).get("level", 0)
	if windmill_level > 0:
		modifier -= 0.5  # 风车主体固定 -50%
		# 风车·转速：射速 +10% 每级
		var windmill_speed_level = current_upgrades.get("windmill_speed", {}).get("level", 0)
		if windmill_speed_level > 0:
			modifier += 0.10 * windmill_speed_level
	
	# 机炮·过载
	var overload_level = current_upgrades.get("mg_overload", {}).get("level", 0)
	if overload_level > 0:
		modifier += 0.5  # 基础+50%
		var penalty_per_stack = [0.05, 0.04, 0.03][min(overload_level - 1, 2)]
		modifier -= float(overload_stacks) * penalty_per_stack
	
	# 过载触发器：满血时射速 +7%*lv
	var overdrive_level = current_upgrades.get("overdrive_trigger", {}).get("level", 0)
	if overdrive_level > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var hc = player.get_node_or_null("HealthComponent")
			if hc and hc.current_health >= hc.max_health:
				modifier += 0.07 * overdrive_level
	
	return modifier

func get_fire_direction_modifier(base_direction: Vector2, player_position: Vector2) -> Vector2:
	"""获取射击方向修正（处理扫射、乱射、风车）"""
	var current_upgrades = GameManager.current_upgrades
	
	# 扫射（顺时针旋转）
	var sweep_level = current_upgrades.get("sweep_fire", {}).get("level", 0)
	if sweep_level > 0:
		return Vector2.RIGHT.rotated(sweep_fire_angle)
	
	# 风车（顺时针旋转）
	var windmill_level = current_upgrades.get("windmill", {}).get("level", 0)
	if windmill_level > 0:
		return Vector2.RIGHT.rotated(windmill_angle)
	
	# 乱射（随机方向）
	var chaos_level = current_upgrades.get("chaos_fire", {}).get("level", 0)
	if chaos_level > 0:
		return Vector2.RIGHT.rotated(randf_range(0, TAU))
	
	return base_direction  # 无修正

# ========== 伤害相关接口 ==========

func get_damage_modifier(base_damage: float, target: Node2D = null) -> float:
	"""获取伤害修正（在计算护甲之前）。target 为命中目标（可选）。"""
	var damage = base_damage
	var current_upgrades = GameManager.current_upgrades
	
	# 伤害强化
	var damage_level = current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_level > 0:
		damage *= (1.0 + 0.05 * damage_level)
	
	# 穿透（减益）
	var penetration_level = current_upgrades.get("penetration", {}).get("level", 0)
	if penetration_level > 0:
		damage *= (1.0 - 0.10 * penetration_level)
	
	# 风车（减益）
	var windmill_level = current_upgrades.get("windmill", {}).get("level", 0)
	if windmill_level > 0:
		var reduction = 0.20  # 风车主体固定 -20%
		# 风车·弹道：伤害额外 -10% 每级
		var windmill_spread_level = current_upgrades.get("windmill_spread", {}).get("level", 0)
		if windmill_spread_level > 0:
			reduction += 0.10 * windmill_spread_level
		damage *= (1.0 - reduction)
	
	# 过载触发器：低血（<50%）时伤害 +7%*lv
	var overdrive_level = current_upgrades.get("overdrive_trigger", {}).get("level", 0)
	if overdrive_level > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var hc = player.get_node_or_null("HealthComponent")
			if hc and hc.current_health < hc.max_health * 0.5:
				damage *= (1.0 + 0.07 * overdrive_level)
	
	# 终结协议：目标耐久低于 20% 时额外 +6%*lv 伤害
	var exec_level = current_upgrades.get("execution_protocol", {}).get("level", 0)
	if exec_level > 0 and target != null:
		var t_hc = target.get_node_or_null("HealthComponent")
		if t_hc and t_hc.current_health < t_hc.max_health * 0.20:
			damage *= (1.0 + 0.06 * exec_level)
	
	# 击杀链：连续 5 秒有击杀时全伤害 +6%*lv
	var kill_chain_level = current_upgrades.get("kill_chain", {}).get("level", 0)
	if kill_chain_level > 0 and Time.get_ticks_msec() < kill_chain_active_until_msec:
		damage *= (1.0 + 0.06 * kill_chain_level)
	
	# 穿甲弹芯：对"重甲"（armor_thickness > 50）额外 +8%*lv
	var armor_breaker_level = current_upgrades.get("armor_breaker", {}).get("level", 0)
	if armor_breaker_level > 0 and target != null:
		var armor = target.get("armor_thickness")
		if armor != null and int(armor) > 50:
			damage *= (1.0 + 0.08 * armor_breaker_level)
	
	# 弱点打击：对同一目标连续命中，第 N 发伤害 +3%*N*lv（上限 30%）
	var wp_level = current_upgrades.get("weakpoint_strike", {}).get("level", 0)
	if wp_level > 0 and target != null and target == weakpoint_strike_target:
		var bonus = 0.03 * float(weakpoint_strike_counter) * float(wp_level)
		damage *= (1.0 + min(bonus, 0.30))
	
	return damage

func get_spread_damage_ratio() -> float:
	"""获取扩散强化的伤害比例"""
	var spread_level = GameManager.current_upgrades.get("spread_shot", {}).get("level", 0)
	if spread_level > 0:
		return [0.50, 0.40, 0.30][min(spread_level - 1, 2)]
	return 1.0

# ========== 暴击相关接口 ==========

func get_crit_rate_modifier(base_crit_rate: float, target: Node2D = null) -> float:
	"""获取暴击率修正"""
	var modifier = base_crit_rate
	var current_upgrades = GameManager.current_upgrades
	
	# 暴击强化
	var crit_level = current_upgrades.get("crit_rate", {}).get("level", 0)
	if crit_level > 0:
		modifier += 0.03 * crit_level  # 每级 +3%
	
	# 专注（对同一目标）
	var focus_level = current_upgrades.get("focus", {}).get("level", 0)
	if focus_level > 0 and target == focus_target:
		modifier += 0.01 * focus_level * float(focus_stacks)
	
	# 致命一击：+100% 暴击率
	if lethal_strike_active:
		modifier += 1.0
	
	# 战场感知：周围 200px 内每 5 个敌人 +1%*lv 暴击率，上限 +2%*lv
	var awareness_level = current_upgrades.get("battle_awareness", {}).get("level", 0)
	if awareness_level > 0:
		var player = get_tree().get_first_node_in_group("player") as Node2D
		if player:
			var count := 0
			for e in get_tree().get_nodes_in_group("enemy"):
				if is_instance_valid(e) and e.global_position.distance_squared_to(player.global_position) < 40000.0:
					count += 1
			var bonus := 0.01 * float(awareness_level) * float(count / 5)
			modifier += min(bonus, 0.02 * float(awareness_level))
	
	return modifier

func get_crit_damage_modifier(base_crit_damage: float, crit_rate_bonus: float = 0.0) -> float:
	"""获取暴击伤害修正"""
	var modifier = base_crit_damage
	var current_upgrades = GameManager.current_upgrades
	
	# 暴伤强化
	var crit_damage_level = current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		modifier += 0.06 * crit_damage_level
	
	# 屏息
	var breath_level = current_upgrades.get("breath_hold", {}).get("level", 0)
	if breath_level > 0:
		modifier += breath_hold_timer * 0.10 * breath_level
	
	# 暴击转换
	var conversion_level = current_upgrades.get("crit_conversion", {}).get("level", 0)
	if conversion_level > 0:
		modifier += crit_rate_bonus  # 暴击率加成转换为暴击伤害加成
	
	return modifier

func is_lethal_strike_active() -> bool:
	"""致命一击是否激活"""
	return lethal_strike_active

# ========== 穿透/弹道相关接口 ==========

func get_penetration_modifier(base_penetration: int) -> int:
	"""获取穿透修正"""
	var modifier = base_penetration
	var penetration_level = GameManager.current_upgrades.get("penetration", {}).get("level", 0)
	if penetration_level > 0:
		modifier += penetration_level
	return modifier

func get_spread_modifier(base_spread: int) -> int:
	"""获取弹道修正"""
	var modifier = base_spread
	var current_upgrades = GameManager.current_upgrades
	
	# 风车
	var windmill_level = current_upgrades.get("windmill", {}).get("level", 0)
	if windmill_level > 0:
		modifier += 2  # 风车主体固定 +2
		# 风车·弹道：主武器弹道 +1/2/3
		var windmill_spread_level = current_upgrades.get("windmill_spread", {}).get("level", 0)
		if windmill_spread_level > 0:
			modifier += [1, 2, 3][min(windmill_spread_level - 1, 2)]
	
	# 扩散
	var spread_level = current_upgrades.get("spread_shot", {}).get("level", 0)
	if spread_level > 0:
		modifier += [1, 2, 3][min(spread_level - 1, 2)]
	
	return modifier

# ========== 事件处理 ==========

func on_weapon_fire() -> int:
	"""武器发射时调用，返回额外射击次数（散弹）"""
	var current_upgrades = GameManager.current_upgrades
	last_shot_time = Time.get_ticks_msec() / 1000.0
	breath_hold_timer = 0.0  # 屏息重置
	
	var extra_shot_count = 0
	
	# 连射
	var chain_level = current_upgrades.get("chain_fire", {}).get("level", 0)
	if chain_level > 0:
		var max_stacks = 4 * chain_level
		chain_fire_stacks = min(chain_fire_stacks + 1, max_stacks)
	
	# 散弹
	var scatter_level = current_upgrades.get("scatter_shot", {}).get("level", 0)
	if scatter_level > 0:
		scatter_shot_counter += 1
		var trigger_count = [10, 8, 7, 6, 5][min(scatter_level - 1, 4)]
		if scatter_shot_counter >= trigger_count:
			scatter_shot_counter = 0
			# 额外射击次数：1/1/2/2/3次
			var shot_counts = [1, 1, 2, 2, 3]
			var index = min(scatter_level - 1, shot_counts.size() - 1)
			extra_shot_count = shot_counts[index]
	
	# 致命一击
	var lethal_level = current_upgrades.get("lethal_strike", {}).get("level", 0)
	if lethal_level > 0:
		var trigger_count = [9, 7, 5, 3][min(lethal_level - 1, 3)]
		lethal_strike_counter += 1
		if lethal_strike_counter >= trigger_count:
			lethal_strike_counter = 0
			lethal_strike_active = true
		else:
			lethal_strike_active = false
	
	# 机炮·过载
	var overload_level = current_upgrades.get("mg_overload", {}).get("level", 0)
	if overload_level > 0:
		var max_stacks = [12, 15, 20][min(overload_level - 1, 2)]
		overload_stacks = min(overload_stacks + 1, max_stacks)
	
	return extra_shot_count

func on_weapon_hit(target: Node2D):
	"""武器命中时调用"""
	var current_upgrades = GameManager.current_upgrades
	
	# 专注
	var focus_level = current_upgrades.get("focus", {}).get("level", 0)
	if focus_level > 0:
		if target == focus_target:
			focus_stacks = min(focus_stacks + 1, 5)
		else:
			focus_target = target
			focus_stacks = 1
		focus_timer.start()
	
	# 弱点打击：连续命中同一目标计数递增
	var wp_level = current_upgrades.get("weakpoint_strike", {}).get("level", 0)
	if wp_level > 0:
		if target == weakpoint_strike_target:
			weakpoint_strike_counter = min(weakpoint_strike_counter + 1, 10)
		else:
			weakpoint_strike_target = target
			weakpoint_strike_counter = 1
	
	# 电击核心：命中时对目标减速 0.4*lv 秒
	var shock_level = current_upgrades.get("shock_core", {}).get("level", 0)
	if shock_level > 0 and is_instance_valid(target):
		var slow_duration := 0.4 * float(shock_level)
		if target.has_method("apply_slow"):
			target.apply_slow(0.5, slow_duration)  # 50% 减速

func on_weapon_critical(target: Node2D):
	"""武器暴击时调用"""
	var current_upgrades = GameManager.current_upgrades
	
	# 爆射
	var burst_level = current_upgrades.get("burst_fire", {}).get("level", 0)
	if burst_level > 0:
		var max_stacks = 4 * burst_level
		burst_fire_stacks = min(burst_fire_stacks + 1, max_stacks)
	
	# 破片嵌入：暴击时附加破片层数（流血/DoT）
	var sharpened_level = current_upgrades.get("sharpened", {}).get("level", 0)
	if sharpened_level > 0 and is_instance_valid(target):
		_apply_bleed_stacks(target, sharpened_level)

func on_enemy_killed_by_critical(target: Node2D):
	"""敌人被暴击击杀时调用（在伤害应用后调用）"""
	var current_upgrades = GameManager.current_upgrades
	
	# 收割
	var harvest_level = current_upgrades.get("harvest", {}).get("level", 0)
	if harvest_level > 0:
		var player = get_tree().get_first_node_in_group("player")
		if player:
			var player_health = player.get_node_or_null("HealthComponent")
			if player_health:
				player_health.heal(harvest_level)

func on_enemy_killed(_target: Node2D):
	"""任意敌人被击杀时调用（供外部调用）"""
	var current_upgrades = GameManager.current_upgrades
	
	# 击杀链：击杀后 5 秒内全伤害加成，再次击杀刷新
	var kill_chain_level = current_upgrades.get("kill_chain", {}).get("level", 0)
	if kill_chain_level > 0:
		kill_chain_active_until_msec = Time.get_ticks_msec() + 5000

func _process(delta):
	"""每帧更新"""
	var current_upgrades = GameManager.current_upgrades
	
	# 屏息计时
	var breath_level = current_upgrades.get("breath_hold", {}).get("level", 0)
	if breath_level > 0:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - last_shot_time > 0.01:
			breath_hold_timer += delta
		else:
			breath_hold_timer = 0.0
	
	# 扫射：每 0.16 秒检测最近敌人，计算旋转方向和角速度
	var sweep_level = current_upgrades.get("sweep_fire", {}).get("level", 0)
	if sweep_level > 0:
		sweep_fire_update_timer -= delta
		if sweep_fire_update_timer <= 0:
			sweep_fire_update_timer = 0.16
			_update_sweep_fire_angular_velocity()
		
		sweep_fire_angle += deg_to_rad(sweep_fire_angular_velocity) * delta
		# 保持角度在 [0, TAU) 范围内
		sweep_fire_angle = wrapf(sweep_fire_angle, 0.0, TAU)
	
	# 流血 DoT tick
	if _bleed_stacks.size() > 0:
		_process_bleed_ticks(delta)
	
	# 风车角度旋转
	var windmill_level = current_upgrades.get("windmill", {}).get("level", 0)
	if windmill_level > 0:
		# 基础旋转速度 90 度/秒，风车·转速每级 +30%
		var windmill_speed_level = current_upgrades.get("windmill_speed", {}).get("level", 0)
		var windmill_rotation_speed = 90.0 * (1.0 + 0.30 * windmill_speed_level)
		windmill_angle += deg_to_rad(windmill_rotation_speed) * delta
		if windmill_angle >= TAU:
			windmill_angle -= TAU

# 与机炮控制器一致：扫射目标检测使用相同射程
const SWEEP_TARGET_MAX_RANGE: float = 200.0

func _update_sweep_fire_angular_velocity():
	"""扫射：每 0.16 秒更新角速度和旋转方向。目标寻找与正常射击一致（同射程、最近敌人）。"""
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		sweep_fire_angular_velocity = 60.0
		return
	
	# 与正常射击相同：同射程内敌人，找最近
	var all_enemies = get_tree().get_nodes_in_group("enemy")
	var enemies: Array = []
	for enemy in all_enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_squared_to(player.global_position) < pow(SWEEP_TARGET_MAX_RANGE, 2):
			enemies.append(enemy)
	
	if enemies.size() == 0:
		# 无敌人时，以基础速度缓慢旋转（此时机炮也不会开火）
		sweep_fire_angular_velocity = 60.0
		return
	
	# 最近敌人（与 _resolve_fire_direction 逻辑一致）
	var nearest_enemy: Node2D = null
	var nearest_dist_sq: float = INF
	for enemy in enemies:
		var dist_sq = enemy.global_position.distance_squared_to(player.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest_enemy = enemy
	
	if nearest_enemy == null:
		sweep_fire_angular_velocity = 60.0
		return
	
	# 目标角度、最短路径角度差
	var to_enemy = nearest_enemy.global_position - player.global_position
	var target_angle = to_enemy.angle()
	var angle_diff = wrapf(target_angle - sweep_fire_angle, -PI, PI)
	
	# 角速度(deg/s) = 60 + 0.5 × |夹角(rad)|
	var speed = 60.0 + 0.5 * abs(angle_diff)
	if angle_diff >= 0:
		sweep_fire_angular_velocity = speed
	else:
		sweep_fire_angular_velocity = -speed

func _setup_timers():
	"""设置计时器"""
	# 连射计时器
	chain_fire_timer = Timer.new()
	chain_fire_timer.wait_time = 1.0
	chain_fire_timer.timeout.connect(_on_chain_fire_timeout)
	add_child(chain_fire_timer)
	chain_fire_timer.start()
	
	# 爆射计时器
	burst_fire_timer = Timer.new()
	burst_fire_timer.wait_time = 1.0
	burst_fire_timer.timeout.connect(_on_burst_fire_timeout)
	add_child(burst_fire_timer)
	burst_fire_timer.start()
	
	# 专注计时器
	focus_timer = Timer.new()
	focus_timer.wait_time = 0.5
	focus_timer.one_shot = true
	focus_timer.timeout.connect(_on_focus_timeout)
	add_child(focus_timer)
	
	# 机炮·过载计时器
	overload_timer = Timer.new()
	overload_timer.wait_time = 1.0
	overload_timer.timeout.connect(_on_overload_timeout)
	add_child(overload_timer)
	overload_timer.start()

func _on_chain_fire_timeout():
	if chain_fire_stacks > 0:
		chain_fire_stacks -= 1

func _on_burst_fire_timeout():
	if burst_fire_stacks > 0:
		burst_fire_stacks -= 1

func _on_focus_timeout():
	focus_target = null
	focus_stacks = 0

func _on_overload_timeout():
	var overload_level = GameManager.current_upgrades.get("mg_overload", {}).get("level", 0)
	if overload_level > 0:
		var reduction_per_second = [1, 2, 3][min(overload_level - 1, 2)]
		overload_stacks = max(0, overload_stacks - reduction_per_second)
	else:
		overload_stacks = 0

func _on_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	"""升级添加时的处理"""
	# 机炮·过载的层数管理
	var overload_level = current_upgrades.get("mg_overload", {}).get("level", 0)
	if overload_level > 0:
		var max_stacks = [12, 15, 20][min(overload_level - 1, 2)]
		overload_stacks = min(overload_stacks, max_stacks)

# ========== 阶段八：新增接口 ==========

func get_bullet_speed_modifier() -> float:
	"""弹速修正倍率（热装药：+10%*lv）"""
	var hot_load_level = GameManager.current_upgrades.get("hot_load", {}).get("level", 0)
	if hot_load_level > 0:
		return 1.0 + 0.10 * hot_load_level
	return 1.0

func get_bullet_lifetime_modifier() -> float:
	"""弹丸寿命修正倍率（曳光校正：+10%*lv）"""
	var tracer_level = GameManager.current_upgrades.get("tracer_rounds", {}).get("level", 0)
	if tracer_level > 0:
		return 1.0 + 0.10 * tracer_level
	return 1.0

func get_spread_angle_modifier() -> float:
	"""弹道扩散角修正倍率（尾翼稳定：-20%*lv）"""
	var fin_level = GameManager.current_upgrades.get("fin_stabilized", {}).get("level", 0)
	if fin_level > 0:
		return max(1.0 - 0.20 * fin_level, 0.1)
	return 1.0

func get_recoil_cap_modifier() -> float:
	"""散布上限修正倍率（后坐补偿器：-20%*lv）"""
	var recoil_level = GameManager.current_upgrades.get("recoil_compensator", {}).get("level", 0)
	if recoil_level > 0:
		return max(1.0 - 0.20 * recoil_level, 0.1)
	return 1.0

func get_target_computer_accuracy_bonus() -> float:
	"""火控计算机瞄准精度修正：+10%*lv"""
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_method("get_target_computer_level"):
		var tc_level = player.get_target_computer_level()
		if tc_level > 0:
			return 0.10 * float(tc_level)
	return 0.0

# ========== 破片/流血 DoT 系统 ==========

func _apply_bleed_stacks(target: Node2D, stacks_to_add: int):
	"""给目标施加破片流血层数"""
	if not is_instance_valid(target):
		return
	var current_upgrades = GameManager.current_upgrades
	
	# 集束破片：层数上限提升（默认 5，集束每级 +3）
	var laceration_level = current_upgrades.get("laceration", {}).get("level", 0)
	var max_stacks: int = 5 + 3 * int(laceration_level)
	
	var target_id = target.get_instance_id()
	if not _bleed_stacks.has(target_id):
		_bleed_stacks[target_id] = {"stacks": 0, "target": target}
	
	_bleed_stacks[target_id]["stacks"] = min(
		_bleed_stacks[target_id]["stacks"] + stacks_to_add, max_stacks
	)

func _get_bleed_damage_per_tick(stacks: int) -> float:
	"""计算每 tick 的流血伤害：每层 base 0.5 + 破片淬火 0.2*lv"""
	var current_upgrades = GameManager.current_upgrades
	var bloodletting_level = current_upgrades.get("bloodletting", {}).get("level", 0)
	var per_stack := 0.5 + 0.2 * float(bloodletting_level)
	return per_stack * float(stacks)

func _process_bleed_ticks(delta: float):
	"""处理所有流血目标的 DoT（每秒 tick 一次）"""
	var to_remove := []
	for target_id in _bleed_stacks:
		var data = _bleed_stacks[target_id]
		var target = data.get("target") as Node2D
		if not is_instance_valid(target):
			to_remove.append(target_id)
			continue
		
		# 简单实现：每帧按比例施加伤害（delta 累积到 1 秒 tick）
		if not data.has("tick_accumulator"):
			data["tick_accumulator"] = 0.0
		data["tick_accumulator"] += delta
		
		if data["tick_accumulator"] >= 1.0:
			data["tick_accumulator"] -= 1.0
			var dmg := _get_bleed_damage_per_tick(data["stacks"])
			var t_hc = target.get_node_or_null("HealthComponent")
			if t_hc and t_hc.has_method("damage"):
				t_hc.damage(dmg, {"damage_source": "bleed"})
			# 每 tick 自然衰减 1 层
			data["stacks"] -= 1
			if data["stacks"] <= 0:
				to_remove.append(target_id)
	
	for tid in to_remove:
		_bleed_stacks.erase(tid)
