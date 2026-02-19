class_name SaveData
extends Node

func save_game(file_path := "user://autosave.json") -> void:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	# {year:2024, month:12, day:22, hour:19, minute:10, second:33, ...}

	var formatted_time: String = "%04d/%02d/%02d %02d:%02d:%02d" % [
		now.year, now.month, now.day,
		now.hour, now.minute, now.second
	]

	var save_data = {
		"game_state": {
			"day": GameManager.day,
			"time_phase": GameManager.time_phase,
			"pollution": GameManager.pollution,
			"mission_progress": GameManager.mission_progress,
			"chapter_progress": GameManager.chapter_progress,
			"npc_dialogues": GameManager.npc_dialogues,
			"objectives": GameManager.objectives,
			"chapter": GameManager.chapter
		},
		"selection": {
			"current_vehicle": GameManager.current_vehicle,
			"current_skill": GameManager.current_skill
		},
		"vehicles_config": GameManager.vehicles_config,
		"unlocked_vehicles": GameManager.unlocked_vehicles,
		"unlocked_parts": GameManager.unlocked_parts,
		"materials": GameManager.materials,
		"money": GameManager.money,
		"save_time": formatted_time,
	}

	var file = FileAccess.open(file_path, FileAccess.WRITE)
	
	var json_string = JSON.stringify(save_data)

	file.store_string(json_string)
	file.close()

func _normalize_vehicles_config(config) -> Dictionary:
	var out: Dictionary = {}
	for key in config.keys():
		var vehicle = config[key]
		if typeof(vehicle) != TYPE_DICTIONARY:
			out[key] = vehicle
			continue
		vehicle = vehicle.duplicate()
		var parts = vehicle.get("配件")
		if parts != null and typeof(parts) == TYPE_ARRAY:
			var valid: Array = []
			for p in parts:
				if p is String:
					valid.append(p)
			vehicle["配件"] = valid
		# 保留配件等级：只保留 String 键的等级
		var levels = vehicle.get("配件等级")
		if levels != null and typeof(levels) == TYPE_DICTIONARY:
			var valid_levels: Dictionary = {}
			for k in levels.keys():
				if k is String:
					valid_levels[k] = int(levels[k]) if typeof(levels[k]) != TYPE_INT else levels[k]
			vehicle["配件等级"] = valid_levels
		elif vehicle.get("配件等级") == null:
			vehicle["配件等级"] = {}
		out[key] = vehicle
	return out

func _normalize_unlocked_parts(parts) -> Dictionary:
	"""配件只保留 String id，历史 int 直接丢弃。"""
	var out: Dictionary
	if typeof(parts) == TYPE_DICTIONARY:
		out = parts.duplicate()
	else:
		out = {}
	if out.has("配件") and typeof(out["配件"]) == TYPE_ARRAY:
		var valid: Array = []
		for p in out["配件"]:
			if p is String:
				valid.append(p)
		out["配件"] = valid
	return out

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

	var gs: Dictionary = save_data.get("game_state", {})
	GameManager.day = int(gs.get("day", 1))
	GameManager.time_phase = int(gs.get("time_phase", 1))
	GameManager.pollution = int(gs.get("pollution", 7000))
	GameManager.mission_progress = gs.get("mission_progress", {})
	GameManager.chapter_progress = gs.get("chapter_progress", {})
	GameManager.npc_dialogues = gs.get("npc_dialogues", {})
	GameManager.objectives = gs.get("objectives", {})
	GameManager.chapter = int(gs.get("chapter", 1))
	var sel: Dictionary = save_data.get("selection", {})
	GameManager.current_vehicle = int(sel.get("current_vehicle", 0))
	GameManager.current_skill = str(sel.get("current_skill", ""))
	GameManager.vehicles_config = _normalize_vehicles_config(save_data.get("vehicles_config", {}))
	GameManager.unlocked_vehicles = save_data.get("unlocked_vehicles", [0])
	GameManager.unlocked_parts = _normalize_unlocked_parts(save_data.get("unlocked_parts", {}))
	GameManager.materials = save_data.get("materials", {})
	GameManager.money = int(save_data.get("money", 100000))

func HasSave(save_slot_name: String):
	var file_path = "user://" + save_slot_name + ".json"
	
	if not FileAccess.file_exists(file_path):
		print("Save file not found.")
		return
	
	return FileAccess.file_exists(file_path)


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
