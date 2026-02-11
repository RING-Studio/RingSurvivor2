extends Node
class_name RadioSupportAbilityController

@export var marker_scene: PackedScene

@export var base_cooldown_seconds: float = 60.0
@export var base_radius_m: float = 20.0
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
	if upgrade_id in ["radio_support", "radio_radius", "cooling_device", "damage_bonus", "crit_damage", "crit_rate"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("radio_support", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base = base_cooldown_seconds - 5.0 * float(lvl)  # 60-5lv
	base = max(base, 5.0)
	# cooling_device：仅影响冷却类配件
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus := 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var speed_multiplier := 1.0 + speed_bonus
	if speed_multiplier <= 0.0:
		return INF
	return max(base / speed_multiplier, 0.5)

func _get_radius_pixels() -> float:
	var radius_m := base_radius_m
	var bonus_lvl = GameManager.current_upgrades.get("radio_radius", {}).get("level", 0)
	if bonus_lvl > 0:
		radius_m += UpgradeEffectManager.get_effect("radio_radius", bonus_lvl)
	return radius_m * GlobalFomulaManager.METERS_TO_PIXELS

func _get_base_damage() -> float:
	var lvl = GameManager.current_upgrades.get("radio_support", {}).get("level", 0)
	return 50.0 + 20.0 * float(max(lvl, 1))

func _update_timer():
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

func _on_cooldown():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	
	var radius_px := _get_radius_pixels()
	var base_damage := _get_base_damage()
	
	# 选择随机区域：以玩家为中心随机点
	var target_pos = player.global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(0.0, 400.0)
	
	# 视觉提示
	if marker_scene:
		var marker = marker_scene.instantiate()
		get_tree().get_first_node_in_group("foreground_layer").add_child(marker)
		marker.global_position = target_pos
		if marker.has_method("setup"):
			marker.setup(radius_px, strike_delay_seconds)
	
	# 延迟打击
	var timer = get_tree().create_timer(strike_delay_seconds)
	timer.timeout.connect(func():
		_apply_strike(target_pos, radius_px, base_damage)
	)

func _apply_strike(center: Vector2, radius_px: float, base_damage: float):
	# 视觉占位：alpha=64 红色圆形范围提示（打击瞬间）
	var layer = get_tree().get_first_node_in_group("foreground_layer")
	if layer:
		var fx = AoECircleEffect.new()
		fx.global_position = center
		fx.setup(radius_px, Color(1.0, 0.2, 0.2, 64.0 / 255.0), 0.22)
		layer.add_child(fx)

	# 伤害加成
	var dmg := base_damage
	var damage_bonus_level = GameManager.current_upgrades.get("damage_bonus", {}).get("level", 0)
	if damage_bonus_level > 0:
		dmg *= (1.0 + UpgradeEffectManager.get_effect("damage_bonus", damage_bonus_level))
	
	# 炮击对敌人：可暴击（来源 accessory）
	var base_crit_rate = GameManager.get_global_crit_rate()
	var crit_damage_multiplier = 2.0
	var crit_damage_level = GameManager.current_upgrades.get("crit_damage", {}).get("level", 0)
	if crit_damage_level > 0:
		crit_damage_multiplier += UpgradeEffectManager.get_effect("crit_damage", crit_damage_level)
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy.global_position.distance_squared_to(center) > radius_px * radius_px:
			continue
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
	
	# 不分敌我：玩家也会受伤（按“基础伤害+伤害加成”，不暴击，不走护甲公式）
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("HealthComponent"):
		if player.global_position.distance_squared_to(center) <= radius_px * radius_px:
			var hc = player.get_node("HealthComponent")
			hc.damage(dmg, {"damage_source": "radio_support", "is_pierced": false})
