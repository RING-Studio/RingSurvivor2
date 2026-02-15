extends Node
class_name MissileWeaponAbilityController

const MAX_LOCK_RANGE_PX = 420.0
const FIRE_RATE_MIN = 1.0

@export var missile_scene: PackedScene
@export var fire_rate_per_minute: float = 50.0  # 主武器导弹：偏慢射
@export var missile_speed: float = 520.0
@export var explosion_radius_m: float = 2.5

var _base_damage: float = 0.0
var _exclusive_salvo_bonus: int = 0
var _exclusive_reload_bonus: float = 0.0

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
	_exclusive_salvo_bonus = 0
	_exclusive_reload_bonus = 0.0
	
	var lvl_salvo = current_upgrades.get("missile_salvo", {}).get("level", 0)
	if lvl_salvo > 0:
		_exclusive_salvo_bonus = int(lvl_salvo)  # 每级 +1 枚
	
	var lvl_reload = current_upgrades.get("missile_reload", {}).get("level", 0)
	if lvl_reload > 0:
		_exclusive_reload_bonus = 0.10 * float(lvl_reload)

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
	if player == null or missile_scene == null:
		return
	
	var enemies = get_tree().get_nodes_in_group("enemy")
	if enemies.size() == 0:
		return
	
	# 选择最近目标（锁定）
	var nearest: Node2D = null
	var nearest_dsq: float = INF
	for e in enemies:
		if not is_instance_valid(e):
			continue
		var dsq = e.global_position.distance_squared_to(player.global_position)
		if dsq < nearest_dsq:
			nearest_dsq = dsq
			nearest = e
	if nearest == null or nearest_dsq > MAX_LOCK_RANGE_PX * MAX_LOCK_RANGE_PX:
		return
	
	# 通知 WeaponUpgradeHandler 武器发射（散弹等）
	var extra_shot_count = 0
	if WeaponUpgradeHandler.instance:
		extra_shot_count = WeaponUpgradeHandler.instance.on_weapon_fire()
	
	var salvo_count = 1 + _exclusive_salvo_bonus
	# spread_shot 等也可能增加弹道（这里用“多发导弹齐射”体现）
	if WeaponUpgradeHandler.instance:
		salvo_count = max(WeaponUpgradeHandler.instance.get_spread_modifier(salvo_count), 1)
	
	var damage_ratio: float = 1.0
	if WeaponUpgradeHandler.instance and salvo_count > 1:
		damage_ratio = WeaponUpgradeHandler.instance.get_spread_damage_ratio()
	
	var speed_multiplier = 1.0
	var lifetime_multiplier = 1.0
	if WeaponUpgradeHandler.instance:
		speed_multiplier = WeaponUpgradeHandler.instance.get_bullet_speed_modifier()
		lifetime_multiplier = WeaponUpgradeHandler.instance.get_bullet_lifetime_modifier()
	
	for i in range(salvo_count):
		_spawn_one(player.global_position, nearest, damage_ratio, speed_multiplier, lifetime_multiplier)
	
	for i in range(extra_shot_count):
		_spawn_one(player.global_position, nearest, damage_ratio, speed_multiplier, lifetime_multiplier)

func _spawn_one(origin: Vector2, target: Node2D, ratio: float, speed_multiplier: float, lifetime_multiplier: float):
	var missile = missile_scene.instantiate() as MissileWeaponProjectile
	missile.lifetime_seconds *= lifetime_multiplier
	missile.global_position = origin
	missile.speed_pixels_per_second = missile_speed * speed_multiplier
	get_tree().get_first_node_in_group("foreground_layer").add_child(missile)
	var radius_px = explosion_radius_m * GlobalFomulaManager.METERS_TO_PIXELS
	missile.setup(target, _base_damage, radius_px, ratio)
