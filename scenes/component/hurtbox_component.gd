extends Area2D
class_name HurtboxComponent

signal hit

@export var health_component: Node

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")

func _ready():
	# 不再自动连接 area_entered，由外部自己处理伤害
	pass

func apply_damage(amount: float, damage_source: String = "weapon", is_critical: bool = false):
	"""
	应用伤害
	damage_source: "weapon" | "accessory" | "bleed"
	is_critical: 是否暴击
	"""
	var floating_text = floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	floating_text.global_position = global_position + (Vector2.UP * 16)
	
	var final_amount: float = amount
	var owner = get_parent()
	if owner and owner.has_meta("sonar_marked_until_msec"):
		var until = int(owner.get_meta("sonar_marked_until_msec"))
		if Time.get_ticks_msec() < until:
			var bonus = float(owner.get_meta("sonar_marked_bonus", 0.0))
			if bonus > 0.0:
				final_amount *= (1.0 + bonus)
	if health_component != null:
		health_component.damage(final_amount)
	
	var format_string = "%0.1f"
	if round(final_amount) == final_amount:
		format_string = "%0.0f"
	
	# 根据伤害来源和是否暴击确定颜色
	var color = DamageTextHelper.get_color(damage_source, is_critical)
	floating_text.call_deferred("start", format_string % final_amount, color)
	
	# hit 信号仅对武器伤害触发，用于播放受击音效等；配件/流血不触发
	if damage_source == "weapon":
		hit.emit()