extends CenterContainer

@export var day: Label
@export var pollution: Label
@export var money: Label
@export var current_mission: Label

func _process(delta: float) -> void:
	day.text = str(GameManager.day)
	pollution.text = str(GameManager.pollution)
	money.text = str(GameManager.money)
	current_mission.text = GameManager.mission_progress

func enable():
	process_mode = Node.PROCESS_MODE_INHERIT
	visible = true

func disable():
	process_mode = Node.PROCESS_MODE_DISABLED
	visible = false
