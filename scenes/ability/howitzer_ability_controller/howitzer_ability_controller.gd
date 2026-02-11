extends Node
class_name HowitzerAbilityController

const MAX_RANGE_PX = 260.0
const FIRE_RATE_MIN = 1.0

@export var shell_scene: PackedScene
@export var fire_rate_per_minute: float = 40.0  # slow_heavy：约 1.5s/发
@export var shell_speed: float = 520.0
@export var explosion_radius_m: float = 2.0

var _base_damage: float = 0.0
var _exclusive_reload_bonus: float = 0.0  # howitzer 专属：装填/射速
var _exclusive_radius_bonus_m: float = 0.0  # howitzer 专属：爆炸范围

func _ready():
	$Timer.timeout.connect(_on_timeout)
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	_recalculate_all_attributes(GameManager.current_upgrades)
	_update_timer_interval()

func _on_upgrade_added(_upgrade_id: String, current_upgrades: Dictionary):
	_recalculate_all_attributes(current_upgrades)
	_update_timer_interval()

func _recalculate_all_attributes(current_upgrades: Dictionary):
	_base_damage = GameManager.get_player_base_damage()
	_exclusive_reload_bonus = 0.0
	_exclusive_radius_bonus_m = 0.0
	
	var lvl_reload = current_upgrades.get("howitzer_reload", {}).get("level", 0)
	if lvl_reload > 0:
		_exclusive_reload_bonus = 0.10 * float(lvl_reload)
	
	var lvl_radius = current_upgrades.get("howitzer_radius", {}).get("level", 0)
	if lvl_radius > 0:
		_exclusive_radius_bonus_m = 0.5 * float(lvl_radius)

func _update_timer_interval():
	var base_rate = fire_rate_per_minute
	var modifier = 0.0
	if WeaponUpgradeHandler.instance:
		modifier = WeaponUpgradeHandler.instance.get_fire_rate_modifier()
	modifier += _exclusive_reload_bonus
	var effective_rate = max(base_rate * (1.0 + modifier), FIRE_RATE_MIN)
	$Timer.wait_time = 60.0 / effective_rate

func _on_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null or shell_scene == null:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemy").filter(func(enemy: Node2D):
		return enemy.global_position.distance_squared_to(player.global_position) < pow(MAX_RANGE_PX, 2)
	)
	# 无敌人时：仅当拥有扫射/风车/乱射（射击方向变更）时仍射击
	if enemies.size() == 0:
		var current_upgrades = GameManager.current_upgrades
		var has_fire_direction_change = (
			current_upgrades.get("sweep_fire", {}).get("level", 0) > 0 or
			current_upgrades.get("windmill", {}).get("level", 0) > 0 or
			current_upgrades.get("chaos_fire", {}).get("level", 0) > 0
		)
		if not has_fire_direction_change:
			return
	
	var player_pos = player.global_position
	
	# 通知 WeaponUpgradeHandler 武器发射（散弹等）
	var extra_shot_count = 0
	if WeaponUpgradeHandler.instance:
		extra_shot_count = WeaponUpgradeHandler.instance.on_weapon_fire()
	
	var base_dir = _resolve_fire_direction(player_pos, enemies)
	_fire_shells(player_pos, base_dir)
	
	# 散弹额外射击：每次额外射击使用随机方向
	for i in range(extra_shot_count):
		var random_dir = Vector2.RIGHT.rotated(randf_range(0, TAU))
		_fire_shells(player_pos, random_dir)

func _resolve_fire_direction(player_position: Vector2, enemies: Array) -> Vector2:
	var base_direction: Vector2
	if enemies.size() == 0:
		base_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
	else:
		var nearest_enemy: Node2D = null
		var nearest_distance_squared: float = INF
		for enemy in enemies:
			var delta = enemy.global_position - player_position
			var dsq = delta.length_squared()
			if dsq < nearest_distance_squared:
				nearest_distance_squared = dsq
				nearest_enemy = enemy
		if nearest_enemy != null:
			var d = nearest_enemy.global_position - player_position
			base_direction = d.normalized() if d.length_squared() >= 0.0001 else Vector2.RIGHT
		else:
			base_direction = Vector2.RIGHT
	
	if WeaponUpgradeHandler.instance:
		return WeaponUpgradeHandler.instance.get_fire_direction_modifier(base_direction, player_position)
	return base_direction

func _fire_shells(origin: Vector2, base_direction: Vector2):
	# 弹道数（扩散/风车等会改动）
	var shot_count = 1
	if WeaponUpgradeHandler.instance:
		shot_count = max(WeaponUpgradeHandler.instance.get_spread_modifier(shot_count), 1)
	
	var damage_ratio := 1.0
	if WeaponUpgradeHandler.instance and shot_count > 1:
		damage_ratio = WeaponUpgradeHandler.instance.get_spread_damage_ratio()
	
	# howitzer：多弹道按散射角分布（集中散射），避免 360° 风车直接把炮弹全打散到身后
	var spread_angle_deg = 6.0
	for i in range(shot_count):
		var angle_offset = (float(i) - float(shot_count - 1) / 2.0) * deg_to_rad(spread_angle_deg)
		var dir = base_direction.rotated(angle_offset)
		var shell = shell_scene.instantiate() as HowitzerShell
		get_tree().get_first_node_in_group("foreground_layer").add_child(shell)
		shell.global_position = origin
		shell.speed_pixels_per_second = shell_speed
		var radius_px = (explosion_radius_m + _exclusive_radius_bonus_m) * GlobalFomulaManager.METERS_TO_PIXELS
		shell.setup(dir, _base_damage, radius_px, damage_ratio)
