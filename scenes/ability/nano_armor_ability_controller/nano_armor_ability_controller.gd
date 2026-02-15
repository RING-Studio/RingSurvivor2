extends Node
class_name NanoArmorAbilityController

@export var base_cooldown_seconds: float = 12.0

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
	if upgrade_id in ["nano_armor", "cooling_device", "nano_repair_rate", "nano_overcap"]:
		_update_timer()

func _get_cooldown_seconds() -> float:
	var lvl = GameManager.current_upgrades.get("nano_armor", {}).get("level", 0)
	if lvl <= 0:
		return INF
	var base: float = base_cooldown_seconds
	var cd_lvl = GameManager.current_upgrades.get("cooling_device", {}).get("level", 0)
	var speed_bonus: float = 0.0
	if cd_lvl > 0:
		speed_bonus += UpgradeEffectManager.get_effect("cooling_device", cd_lvl)
	return max(base / (1.0 + speed_bonus), 0.5)

func _get_heal_amount() -> int:
	var lvl = GameManager.current_upgrades.get("nano_armor", {}).get("level", 0)
	var base = 2 + int(max(lvl, 1))
	var bonus_lvl = GameManager.current_upgrades.get("nano_repair_rate", {}).get("level", 0)
	base += int(UpgradeEffectManager.get_effect("nano_repair_rate", bonus_lvl))
	return base

func _get_overcap_amount() -> float:
	var bonus_lvl = GameManager.current_upgrades.get("nano_overcap", {}).get("level", 0)
	return UpgradeEffectManager.get_effect("nano_overcap", bonus_lvl)

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
	var hc = player.get_node_or_null("HealthComponent")
	if hc == null:
		return
	
	var heal_amount = _get_heal_amount()
	hc.heal(heal_amount)
	
	var overcap = _get_overcap_amount()
	if overcap > 0.0 and player.has_method("apply_nano_overcap_shield"):
		player.apply_nano_overcap_shield(overcap, 6.0)
