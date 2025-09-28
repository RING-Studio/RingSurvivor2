extends Control

@export var resource: DialogueResource
@export var next_scene: StringName = &""

var blloon : Node

func _ready() -> void:
	get_tree().paused = true
	blloon = DialogueManager.show_dialogue_balloon(resource, "start")
	blloon.process_mode = Node.PROCESS_MODE_ALWAYS
	
func _enter_tree() -> void:
	DialogueManager.dialogue_ended.connect(dialogue_ended)

func _exit_tree() -> void:
	DialogueManager.dialogue_ended.disconnect(dialogue_ended)

func dialogue_ended(_resource: DialogueResource):
	hide()
	get_tree().paused = false
	blloon.process_mode = Node.PROCESS_MODE_INHERIT
