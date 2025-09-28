extends Control

@export var back_scene: StringName = &""

func _ready() -> void:
	Transitions.transition(3, true)

func _back_to_menu():
	Transitions.set_next_scene(back_scene)
	Transitions.transition( 3 )
