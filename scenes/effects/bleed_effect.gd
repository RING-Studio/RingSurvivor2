extends Node

class_name BleedEffect

@export var layers: int = 0
@export var damage_per_layer: float = 1.0
@export var distance_threshold: float = 1.0

var target: Node
var _damage_component: Node
var _previous_position: Vector2
var _accum_distance: float = 0.0
var _floating_text_scene = preload("res://scenes/ui/floating_text.tscn")

func _ready():
	if target == null:
		queue_free()
		return
		
	_previous_position = target.global_position
	_damage_component = target.get_node_or_null("HealthComponent")
	set_process(true)

func _process(delta):
	if target == null:
		queue_free()
		return

	_accum_distance += target.global_position.distance_to(_previous_position)
	_previous_position = target.global_position

	while _accum_distance >= distance_threshold and layers > 0:
		if _damage_component != null:
			_damage_component.damage(damage_per_layer)
			_show_bleed_text(damage_per_layer, target.global_position)
		layers -= 1
		_accum_distance -= distance_threshold

func _show_bleed_text(value: float, position: Vector2):
	var floating_text = _floating_text_scene.instantiate() as Node2D
	get_tree().get_first_node_in_group("foreground_layer").add_child(floating_text)
	floating_text.global_position = position + (Vector2.UP * 16)
	floating_text.start("%0.0f" % value, DamageTextHelper.get_color("bleed"))

	if layers <= 0:
		queue_free()
