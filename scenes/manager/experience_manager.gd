extends Node

const TARGET_EXPERIENCE_GROWTH = 1

var current_experience = 0
var current_level = 1
var target_experience = 1


func _ready():
	GameEvents.experience_vial_collected.connect(on_experience_vial_collected)


func increment_experience(number: float):
	current_experience = min(current_experience + number, target_experience)
	GameEvents.experience_updated.emit(current_experience, target_experience)
	if current_experience == target_experience:
		current_level += 1
		target_experience += TARGET_EXPERIENCE_GROWTH
		current_experience = 0
		GameEvents.experience_updated.emit(current_experience, target_experience)
		GameEvents.level_up.emit(current_level)


func on_experience_vial_collected(number: float):
	increment_experience(number)
