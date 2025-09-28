extends Control

@export var level1: Array[StringName]

var selected_vehicle = 0
var max_vehicles = 4

func change_level1():
	pass

func left_button_pressed():
	selected_vehicle = (selected_vehicle - 1 + max_vehicles) % max_vehicles
	_update_vehicle_selection()

func right_button_pressed():
	selected_vehicle = (selected_vehicle + 1) % max_vehicles
	_update_vehicle_selection()

func _update_vehicle_selection():
	var vehicle_name = "Vehicle" + str(selected_vehicle + 1)
	var vehicle_label = get_node("VehicleLabel")
	vehicle_label.text = vehicle_name

func _goto_level(level_name: StringName):
	if level_name.is_empty():
		print("Error: Level name is empty.")
		return

	var level_path = "res://Levels/" + level_name + ".tscn"
	get_tree().change_scene_to_file(level_path)
