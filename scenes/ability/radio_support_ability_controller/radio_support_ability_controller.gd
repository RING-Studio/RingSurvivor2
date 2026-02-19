extends Node
class_name RadioSupportAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var marker_scene: PackedScene

@export var base_cooldown_seconds: float = 60.0
@export var base_radius_m: float = 40.0
@export var strike_delay_seconds: float = 10.0

var _cooldown_timer: Timer

func _ready():
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = false
	_cooldown_timer.autostart = false
	_cooldown_timer.timeout.connect(_on_cooldown)
	add_child(_cooldown_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_update_timer()

func _on_upgrade_added(upgrade_id: String, _current: Dictionary):
	if upgrade_id in ["radio_support", "radio_radius", "radio_barrage_count", "cooling_device", "damage_bonus", "crit_damage", "crit_rate"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("radio_support", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base = base_cooldown_seconds - 5.0 * float(lvl)  # 60-5lv
	base = max(base, 5.0)
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var speed_multiplier: float = 1.0 + speed_bonus
	if speed_multiplier <= 0.0:
		return INF
	return max(base / speed_multiplier, 0.5)

func _get_radius_pixels() -> float:
	var radius_m: float = base_radius_m
	var bonus_lvl = GameManager.current_upgrades.get("radio_radius", {}).get("level", 0)
	if bonus_lvl > 0:
		radius_m += UpgradeEffectManager.get_effect("radio_radius", bonus_lvl)
	return radius_m * GlobalFomulaManager.METERS_TO_PIXELS

func _get_base_damage() -> float:
	var lvl = GameManager.current_upgrades.get("radio_support", {}).get("level", 0)
	return 50.0 + 20.0 * float(max(lvl, 1))

func _get_barrage_count() -> int:
	var extra_level = GameManager.current_upgrades.get("radio_barrage_count", {}).get("level", 0)
	return 1 + int(UpgradeEffectManager.get_effect("radio_barrage_count", extra_level))

func _update_timer():
	var interval: float = _get_cooldown_seconds()
	if _cooldown_timer == null:
		return
	if is_inf(interval):
		if not _cooldown_timer.is_stopped():
			_cooldown_timer.stop()
		return
	_cooldown_timer.wait_time = interval
	if _cooldown_timer.is_stopped():
		_cooldown_timer.start()

func _on_cooldown():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var radius_px: float = _get_radius_pixels()
	var base_damage: float = _get_base_damage()
	
	# 以玩家为中心随机点
	var target_pos = player.global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 400.0)
	
	# 预警圆（淡红 alpha32，闪烁直到轰炸）
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	var warning_fx: Node2D = null
	if layer:
		warning_fx = _create_blinking_circle(target_pos, radius_px, Color(1.0, 0.2, 0.2, 32.0 / 255.0))
		layer.add_child(warning_fx)
	
	var barrage_count = _get_barrage_count()
	
	# 延迟打击
	var timer = get_tree().create_timer(strike_delay_seconds)
	timer.timeout.connect(func():
		if is_instance_valid(warning_fx):
			warning_fx.queue_free()
		for i in range(barrage_count):
			var offset = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, radius_px * 0.3)
			_apply_strike(target_pos + offset, radius_px, base_damage)
	)

func _apply_strike(center: Vector2, radius_px: float, base_damage: float):
	# 轰炸圆（红 alpha64，短暂闪烁）
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = center
		fx.setup(radius_px, Color(1.0, 0.2, 0.2, 64.0 / 255.0), 0.15)
		layer.add_child(fx)

	# 伤害加成
	var dmg: float = base_damage
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	# 动态 Area2D 检测范围内敌人
	var strike_area: Area2D = Area2D.new()
	strike_area.collision_layer = 0
	strike_area.collision_mask = 4
	strike_area.global_position = center
	var shape_node: CollisionShape2D = CollisionShape2D.new()
	var circle: CircleShape2D = CircleShape2D.new()
	circle.radius = radius_px
	shape_node.shape = circle
	strike_area.add_child(shape_node)
	if layer:
		layer.add_child(strike_area)
	else:
		get_tree().current_scene.add_child(strike_area)
	
	# 等一帧让物理引擎检测重叠
	await get_tree().physics_frame
	
	var enemies: Array[Node2D] = []
	for area in strike_area.get_overlapping_areas():
		if area is HurtboxComponent:
			var enemy = area.get_parent()
			if enemy and enemy.is_in_group("enemy") and is_instance_valid(enemy):
				if not enemies.has(enemy):
					enemies.append(enemy)
	
	# 玩家友伤检测（玩家不在 mask=4，保留距离判断）
	var player_in_range: bool = false
	var player = get_tree().get_first_node_in_group("player")
	if player:
		if player.global_position.distance_squared_to(center) <= radius_px * radius_px:
			player_in_range = true
	
	strike_area.queue_free()
	
	for enemy in enemies:
		var is_critical = randf() < base_crit_rate
		var applied = dmg
		if is_critical:
			applied *= crit_damage_multiplier
		
		var armor_coverage: float = 0.0
		if enemy.get("armorCoverage") != null:
			armor_coverage = float(enemy.get("armorCoverage"))
		elif enemy.get("armor_coverage") != null:
			armor_coverage = float(enemy.get("armor_coverage"))
		
		var final_damage = GlobalFomulaManager.calculate_damage(
			applied,
			GameManager.get_player_hard_attack_multiplier_percent(),
			GameManager.get_player_soft_attack_multiplier_percent(),
			GameManager.get_player_hard_attack_depth_mm(),
			enemy.get("armor_thickness") if enemy.get("armor_thickness") else 0,
			armor_coverage,
			enemy.get("hardAttackDamageReductionPercent") if enemy.get("hardAttackDamageReductionPercent") else 0.0
		)
		
		var hurtbox = enemy.get_node_or_null("HurtboxComponent")
		if hurtbox:
			hurtbox.apply_damage(final_damage, "accessory", is_critical)
	
	# 不分敌我：玩家也会受伤
	if player_in_range and player and player.has_node("HealthComponent"):
		var hc = player.get_node("HealthComponent")
		hc.damage(dmg, {"damage_source": "radio_support", "is_pierced": false})

func _create_blinking_circle(pos: Vector2, radius: float, color: Color) -> Node2D:
	"""创建闪烁预警圆（0.3s 亮 / 0.3s 暗循环）"""
	var BlinkCircleScene: PackedScene = load("res://scenes/ability/radio_support_ability/radio_blink_circle.tscn")
	var node: Node2D = BlinkCircleScene.instantiate()
	node.setup(radius, color)
	node.global_position = pos
	return node
