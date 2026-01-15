extends Area2D
class_name HurtboxComponent

signal hit

@export var health_component: Node

var floating_text_scene = preload("res://scenes/ui/floating_text.tscn")
const DamageTextHelper = preload("res://Scripts/DamageTextHelper.gd")


func _ready():
	area_entered.connect(on_area_entered)


func on_area_entered(other_area: Area2D):
	if not other_area is HitboxComponent:
		return
	if health_component == null:
		return
	
	var hitbox_component = other_area as HitboxComponent

	# 默认直接应用一次伤害（以 hitbox 当前 damage/damage_type 为准）
	apply_damage(hitbox_component.damage, hitbox_component.damage_type)
	
	hit.emit()
	
func apply_damage(amount: float, damage_type: String = "weapon"):
	if health_component != null:
		health_component.damage(amount)
	
	var floating_text = floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	floating_text.global_position = global_position + (Vector2.UP * 16)
	
	var format_string = "%0.1f"
	if round(amount) == amount:
		format_string = "%0.0f"
	var color = DamageTextHelper.get_color(damage_type)
	floating_text.start(format_string % amount, color)
