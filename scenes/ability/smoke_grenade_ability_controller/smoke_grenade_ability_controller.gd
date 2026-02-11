extends Node
class_name SmokeGrenadeAbilityController

@export var smoke_cloud_scene: PackedScene
@export var base_load_interval: float = 10.0  # 装填：10秒
@export var base_radius_m: float = 1.0        # 基础半径：1米
@export var base_duration_s: float = 3.0      # 基础持续：3秒

var _timer: Timer

func _ready():
	_timer = Timer.new()
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)
	
	GameEvents.ability_upgrade_added.connect(_on_upgrade_added)
	
	_update_timer()

func _on_upgrade_added(upgrade_id: String, _current_upgrades: Dictionary):
	if upgrade_id in ["smoke_grenade", "smoke_range", "smoke_duration"]:
		_update_timer()

func _update_timer():
	var lvl = GameManager.current_upgrades.get("smoke_grenade", {}).get("level", 0)
	if lvl <= 0:
		if _timer and not _timer.is_stopped():
			_timer.stop()
		return
	_timer.wait_time = max(base_load_interval, 0.2)
	if _timer.is_stopped():
		_timer.start()

func _get_radius_pixels() -> float:
	var radius_m := base_radius_m
	var range_lvl = GameManager.current_upgrades.get("smoke_range", {}).get("level", 0)
	if range_lvl > 0:
		# 烟雾弹·范围：+2m per level
		radius_m += UpgradeEffectManager.get_effect("smoke_range", range_lvl)
	return radius_m * GlobalFomulaManager.METERS_TO_PIXELS

func _get_duration_seconds() -> float:
	var d := base_duration_s
	var duration_lvl = GameManager.current_upgrades.get("smoke_duration", {}).get("level", 0)
	if duration_lvl > 0:
		# 烟雾弹·持续：+1s per level
		d += UpgradeEffectManager.get_effect("smoke_duration", duration_lvl)
	return d

func _get_slow_ratio() -> float:
	# 1米范围内敌人移速 -20lv%，持续3秒
	var lvl = GameManager.current_upgrades.get("smoke_grenade", {}).get("level", 0)
	return clamp(0.20 * float(max(lvl, 1)), 0.0, 0.90)

func _on_timeout():
	var player = get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	if smoke_cloud_scene == null:
		return
	var cloud = smoke_cloud_scene.instantiate()
	get_tree().get_first_node_in_group("foreground_layer").add_child(cloud)
	cloud.global_position = player.global_position
	if cloud.has_method("setup"):
		cloud.setup(_get_radius_pixels(), _get_slow_ratio(), _get_duration_seconds())
