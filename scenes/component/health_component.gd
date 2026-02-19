extends Node
class_name HealthComponent

signal died
signal health_changed
signal health_decreased
signal healed(amount: int)  # 回复耐久时发出，供车载空调等使用

@export var max_health: float = 50
var current_health


func _ready():
	current_health = max_health


func damage(damage_amount: float, context: Dictionary = {}):
	var final_amount: float = damage_amount
	# God Mode: 调试模式下玩家无敌
	if final_amount > 0 and owner != null and owner.is_in_group("player"):
		var console: Node = Engine.get_singleton("DebugConsole") if Engine.has_singleton("DebugConsole") else null
		if console == null:
			console = owner.get_tree().root.get_node_or_null("DebugConsole")
		if console != null and console.has_method("is_god_mode") and console.is_god_mode():
			return
	# 在进入 HealthComponent 前，允许 owner 拦截/修改伤害（用于一次性免死等）
	if final_amount > 0 and owner != null and owner.has_method("before_take_damage"):
		final_amount = owner.before_take_damage(final_amount, self, context)
	
	current_health = clamp(current_health - final_amount, 0, max_health)
	health_changed.emit()
	if final_amount > 0:
		health_decreased.emit()
	Callable(check_death).call_deferred()


func heal(heal_amount: int):
	if heal_amount <= 0:
		return
	damage(-heal_amount)
	healed.emit(heal_amount)


func get_health_percent():
	if max_health <= 0:
		return 0
	return min(current_health / max_health, 1)


func check_death():
	if current_health == 0:
		died.emit()
		owner.queue_free()
