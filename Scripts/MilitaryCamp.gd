extends Control

@export var next_scene: StringName = &""
@export var npc_scene: StringName = &""
@export var car_editor_scene: StringName = &""
@export var tech_scene: StringName = &""
@export var save_scene: StringName = &""


func _ready() -> void:
	Transitions.transition( Transitions.transition_type.Diamond , true)
	
func depart():
	Transitions.set_next_scene(next_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func npc():
	Transitions.set_next_scene(npc_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func millitary_camp():
	Transitions.set_next_scene(car_editor_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func tech_base():
	Transitions.set_next_scene(tech_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func save():
	Transitions.set_next_scene(save_scene)
	Transitions.transition( Transitions.transition_type.Diamond )
