extends Node2D

@export var player: CharacterBody2D
@export var next_scene: StringName = &""
@export var npc_scene: StringName = &""
@export var car_editor_scene: StringName = &""
@export var tech_scene: StringName = &""
@export var save_scene: StringName = &""


func _ready() -> void:
	Transitions.transition( Transitions.transition_type.Diamond , true)
	
func depart():
	#TODO:检查是否满足条件
	Transitions.set_next_scene(next_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func npc():
	Transitions.set_next_scene(npc_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func car_editor():
	Transitions.set_next_scene(car_editor_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func tech_base():
	Transitions.set_next_scene(tech_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func save():
	Transitions.set_next_scene(save_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		var building := can_interact()
		if building != null:
			if building.name == "TechBase":
				tech_base()
			elif  building.name == "Depart":
				depart()
			elif building.name == "npc":
				npc()
			elif building.name == "Save":
				save()
			elif building.name == "CarEditor":
				car_editor()

func can_interact() -> Building:
	for building: Building in $Buildings.get_children():
		if building.can_interact(player):
			return building
	return null

func _process(delta: float) -> void:
	if can_interact() != null:
		player.interaction_hint.visible = true
	else:
		player.interaction_hint.visible = false
