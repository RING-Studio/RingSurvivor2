extends Node
class_name FuelInjectorModuleAbilityController

@export var base_cooldown_seconds: float = 18.0

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
	if upgrade_id in ["fuel_injector_module", "cooling_device", "fuel_boost", "fuel_efficiency"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("fuel_injector_module", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	var eff_lvl = GameManager.current_upgrades.get("fuel_efficiency", {}).get("level", 0)
	if eff_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("fuel_efficiency", eff_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

func _get_duration_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("fuel_injector_module", {}).get("level", 0)
	return 2.5 + 0.5 * float(max(lvl, 1))

func _get_speed_bonus() -> float:
	var lvl = GameManager.current_upgrades.get("fuel_injector_module", {}).get("level", 0)
	var bonus = 0.30 + 0.05 * float(max(lvl, 1))
	var boost_lvl = GameManager.current_upgrades.get("fuel_boost", {}).get("level", 0)
	if boost_lvl > 0:
		bonus += UpgradeEffectManager.get_effect("fuel_boost", boost_lvl)
	return bonus

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
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	if not player.has_method("apply_temporary_speed_bonus"):
		return
	
	var duration = _get_duration_seconds()
	var bonus = _get_speed_bonus()
	player.apply_temporary_speed_bonus(1.0 + bonus, duration)
