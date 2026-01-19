extends Area2D
class_name HurtboxComponent

signal hit

@export var health_component: Node

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")

func _ready():
	# 不再自动连接 area_entered，由外部自己处理伤害
	pass

func apply_damage(amount: float, damage_type: String = "weapon"):
	var floating_text = floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	floating_text.global_position = global_position + (Vector2.UP * 16)
	
	if health_component != null:
		health_component.damage(amount)
	
	var format_string = "%0.1f"
	if round(amount) == amount:
		format_string = "%0.0f"
	var color = DamageTextHelper.get_color(damage_type)
	floating_text.call_deferred("start", format_string % amount, color)
	
	# 只有 weapon 类型伤害才触发 hit 信号（用于播放音效）
	if damage_type == "weapon":
		hit.emit()