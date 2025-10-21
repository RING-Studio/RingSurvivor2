class_name SaveData
extends Node

func save_game(file_path := "user://autosave.json") -> void:
	var now := Time.get_datetime_dict_from_system()
	# {year:2024, month:12, day:22, hour:19, minute:10, second:33, ...}

	var formatted_time := "%04d/%02d/%02d %02d:%02d:%02d" % [
		now.year, now.month, now.day,
		now.hour, now.minute, now.second
	]

	var save_data = {
		"game_state": {
			"day": GameManager.day,
			"time_phase": GameManager.time_phase,
			"pollution": GameManager.pollution,
			"mission_progress": GameManager.mission_progress,
			"npc_dialogues": GameManager.npc_dialogues,
			"chapter": GameManager.chapter
		},
		"selection": {
			"current_vehicle": GameManager.current_vehicle,
			"current_skill": GameManager.current_skill
		},
		"vehicles_config": GameManager.vehicles_config,
		"unlocked_vehicles": GameManager.unlocked_vehicles,
		"unlocked_parts": GameManager.unlocked_parts,
		"tech_upgrades": GameManager.tech_upgrades,
		"money": GameManager.money,
		"save_time": formatted_time,
	}

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save_data)

	file.store_string(json_string)
	file.close()

func load_game(file_path := "user://autosave.json") -> void:
	if not FileAccess.file_exists(file_path):
		print("Save file not found.")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var save_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(save_data) != TYPE_DICTIONARY:
		print("Invalid save data.")
		return

	GameManager.day = save_data["game_state"]["day"]
	GameManager.time_phase = save_data["game_state"]["time_phase"]
	GameManager.pollution = save_data["game_state"]["pollution"]
	GameManager.mission_progress = save_data["game_state"]["mission_progress"]
	GameManager.chapter = save_data["game_state"]["chapter"]
	GameManager.npc_dialogues = save_data["game_state"]["npc_dialogues"]
	GameManager.current_vehicle = save_data["selection"]["current_vehicle"]
	GameManager.current_skill = save_data["selection"]["current_skill"]
	GameManager.vehicles_config = save_data["vehicles_config"]
	print(GameManager.vehicles_config)
	GameManager.unlocked_vehicles = save_data["unlocked_vehicles"]
	GameManager.unlocked_parts = save_data["unlocked_parts"]
	GameManager.tech_upgrades = save_data["tech_upgrades"]
	GameManager.money = save_data["money"]

func HasSave(save_slot_name: String):
	var file_path = "user://" + save_slot_name + ".json"
	return FileAccess.file_exists(file_path)

	if not FileAccess.file_exists(file_path):
		print("Save file not found.")
		return

func get_save_time(save_slot_name: String):
	var file_path = "user://" + save_slot_name + ".json"

	if not FileAccess.file_exists(file_path):
		print("Save file not found.")
		return

	var file = FileAccess.open(file_path, FileAccess.READ)
	var save_data = JSON.parse_string(file.get_as_text())
	file.close()

	if typeof(save_data) != TYPE_DICTIONARY:
		print("Invalid save data.")
		return ""

	return save_data
