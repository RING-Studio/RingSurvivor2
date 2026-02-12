extends Node
class_name OrbitalPingAbilityController

const AoECircleEffect = preload("res://scenes/effects/aoe_circle_effect.gd")

@export var base_cooldown_seconds: float = 25.0
@export var strike_delay_seconds: float = 3.0

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
	if upgrade_id in ["orbital_ping", "cooling_device", "damage_bonus", "crit_damage", "crit_rate"]:
		_update_timer()


func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("orbital_ping", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base := base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var cooling_device_bonus := 0.0
	if cd_lvl > 0:
		cooling_device_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + cooling_device_bonus), 0.5)


func _get_base_damage() -> float:
	var lvl = GameManager.current_upgrades.get("orbital_ping", {}).get("level", 0)
	return UpgradeEffectManager.get_effect("orbital_ping", max(lvl, 1))


func _update_timer() -> void:
	var interval := _get_cooldown_seconds()
	if _cooldown_timer == null:
		return
	if is_inf(interval):
		if not _cooldown_timer.is_stopped():
			_cooldown_timer.stop()
		return
	_cooldown_timer.wait_time = interval
	if _cooldown_timer.is_stopped():
		_cooldown_timer.start()


func _on_cooldown() -> void:
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	# 选择最近的敌人作为目标
	var target := _find_nearest_enemy(player.global_position)
	if target == null:
		return
	
	var target_pos := (target as Node2D).global_position
	var marker_radius_px := 0.5 * GlobalFomulaManager.METERS_TO_PIXELS
	
	# 预警标记（白色闪烁圆，表示即将打击的位置）
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	var warning_fx: Node2D = null
	if layer:
		warning_fx = AoECircleEffect.new()
		warning_fx.global_position = target_pos
		warning_fx.setup(marker_radius_px, Color(1.0, 0.9, 0.3, 64.0 / 255.0), strike_delay_seconds)
		layer.add_child(warning_fx)
	
	# 延迟打击
	var timer = get_tree().create_timer(strike_delay_seconds)
	timer.timeout.connect(func():
		_apply_strike(target_pos)
	)


func _apply_strike(center: Vector2) -> void:
	var base_damage := _get_base_damage()
	var dmg: float = base_damage
	
	# 伤害加成
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	# 暴击
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	# 轰炸视觉效果（红色闪烁）
	var strike_radius_px := 0.8 * GlobalFomulaManager.METERS_TO_PIXELS
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = center
		fx.setup(strike_radius_px, Color(1.0, 0.5, 0.1, 80.0 / 255.0), 0.2)
		layer.add_child(fx)
	
	# 使用 Area2D 检测打击范围内的敌人（单点打击，但有小范围）
	var strike_area := Area2D.new()
	strike_area.collision_layer = 0
	strike_area.collision_mask = 4
	strike_area.global_position = center
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = strike_radius_px
	shape_node.shape = circle
	strike_area.add_child(shape_node)
	if layer:
		layer.add_child(strike_area)
	else:
		get_tree().current_scene.add_child(strike_area)
	
	await get_tree().physics_frame
	
	var enemies: Array[Node2D] = []
	for area in strike_area.get_overlapping_areas():
		if area is HurtboxComponent:
			var enemy = area.get_parent()
			if enemy and enemy.is_in_group("enemy") and is_instance_valid(enemy):
				if not enemies.has(enemy):
					enemies.append(enemy)
	
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
			print("[OrbitalPing] Strike hit ", enemy.name, " for ", final_damage)


func _find_nearest_enemy(from: Vector2) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var best: Node2D = null
	var best_dist_sq := INF
	for e in enemies:
		if not is_instance_valid(e) or not (e is Node2D):
			continue
		var d2 = (e as Node2D).global_position.distance_squared_to(from)
		if d2 < best_dist_sq:
			best_dist_sq = d2
			best = e as Node2D
	return best
