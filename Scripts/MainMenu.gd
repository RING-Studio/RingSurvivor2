extends Control

@export var next_scene: StringName = &""
@export var load_scene: StringName = &""

func _ready() -> void:
	Transitions.transition( Transitions.transition_type.Diamond , true)

func goto_next_scene():
	Transitions.transition( Transitions.transition_type.Diamond )
	Transitions.animation_player.animation_finished.connect( animation_finished )

func animation_finished( anim_name: StringName ):
	Transitions.animation_player.animation_finished.disconnect( animation_finished )
	get_tree().change_scene_to_file(next_scene)


func load():
	Transitions.set_next_scene(load_scene)
	Transitions.transition( Transitions.transition_type.Diamond )	

func quit():
	get_tree().quit()
