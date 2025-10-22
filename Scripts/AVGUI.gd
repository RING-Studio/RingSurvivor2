extends Control

@export var resource: DialogueResource
@export var next_scene: StringName = &""

func _ready() -> void:
	Transitions.transition( 3 , true)
	DialogueManager.show_dialogue_balloon(resource, "start")

func _enter_tree() -> void:
	DialogueManager.dialogue_ended.connect(dialogue_ended)

func _exit_tree() -> void:
	DialogueManager.dialogue_ended.disconnect(dialogue_ended)

# func _process(delta: float) -> void:
# 	if Input.is_action_just_pressed("ui_cancel"):
# 		# DialogueManager.hide_dialogue_balloon()
# 		get_tree().quit()

func dialogue_ended(resource: DialogueResource):
	Transitions.set_next_scene(next_scene)
	Transitions.transition( 3 )
	
