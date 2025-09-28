# JSONLoader.gd
# Godot 4 - JSON Loader Singleton
extends Node

var _data: Variant = null
var _source_path: String = ""

func _ready() -> void:
	load_from_path("res://Data/GameData.json")

func load_from_path(path: String) -> bool:
	_source_path = path
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("JSONLoader: cannot open file: %s" % path)
		_data = null
		return false

	var text := f.get_as_text()
	f.close()

	var parsed_data: Variant = JSON.parse_string(text)
	if parsed_data == null:
		_data = null
		return false

	_data = parsed_data
	return true


func set_data(dictionary_or_array: Variant) -> void:
	_data = dictionary_or_array


func get_all() -> Variant:
	return _data


# --- ACCESSORS ---

func get_field(path_or_keys: Variant, default: Variant = null) -> Variant:
	if _data == null:
		return default

	var keys: Array
	if typeof(path_or_keys) == TYPE_STRING:
		var s := str(path_or_keys).strip_edges()
		if s == "":
			return _data
		keys = s.split("/") if s.find("/") != -1 else s.split(".")
	elif typeof(path_or_keys) == TYPE_ARRAY:
		keys = path_or_keys.duplicate()
	else:
		return default

	var cur = _data
	for k in keys:
		if typeof(k) == TYPE_STRING and k.is_valid_integer():
			k = int(k)

		match typeof(cur):
			TYPE_DICTIONARY:
				if cur.has(k):
					cur = cur[k]
				else:
					return default
			TYPE_ARRAY:
				if typeof(k) == TYPE_INT and k >= 0 and k < cur.size():
					cur = cur[k]
				else:
					return default
			_:
				return default
	return cur


# --- HELPERS ---

func get_category_by_id(category_name: String, id_value) -> Dictionary:
	if _data == null or not _data.has(category_name):
		return {}
	for item in _data[category_name]:
		if typeof(item) == TYPE_DICTIONARY and (
			(item.has("ID") and item["ID"] == id_value)
			or (item.has("Id") and item["Id"] == id_value)
		):
			return item
	return {}


func get_category_by_field(category_name: String, field_name: String, field_value) -> Dictionary:
	if _data == null or not _data.has(category_name):
		return {}
	for item in _data[category_name]:
		if typeof(item) == TYPE_DICTIONARY and item.has(field_name) and item[field_name] == field_value:
			return item
	return {}


func get_category(category_name: String) -> Array:
	if _data == null:
		return []
	return _data.get(category_name, []) if typeof(_data.get(category_name, [])) == TYPE_ARRAY else []

func get_card_name_by_id(card_id: int) -> String:
	var card_data = get_category("车辆类型")
	var data = card_data.get(card_id)
	return data.get("Name", "未知车辆")
