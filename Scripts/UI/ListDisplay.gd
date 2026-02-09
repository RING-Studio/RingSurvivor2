extends VBoxContainer
class_name ListDisplay

@export var title: Label
@export var icon: TextureRect
@export var label : RichTextLabel
@export var parts_unlock_button: Button
@export var load_button: Button
@export var unload_button: Button

func set_title(text:String) -> void:
	title.text = text

func set_icon(texture:Texture2D) -> void:
	icon.texture = texture

func set_label(text:String) -> void:
	label.text = text

func update_info(id: Variant, table_name: String, vehicle_id: int) -> Dictionary:
	var field: Dictionary = {}
	# 配件槽：统一从 AbilityUpgradeData 读，id 为 upgrade_id（String）
	if table_name == "配件":
		if id is String and not id.is_empty():
			var entry = AbilityUpgradeData.get_entry(id)
			if entry != null:
				field = {"Name": entry.get("name", ""), "Remarks": entry.get("description", "")}
	else:
		var table = JsonManager.get_category(table_name)
		if table != null and table.size() > 0:
			if id is int and id >= 0 and id < table.size():
				var row = table[id]
				if row is Dictionary:
					field = row
			else:
				for row in table:
					if row is Dictionary and (row.get("Id") == id or row.get("ID") == id):
						field = row
						break
	if field.is_empty():
		return {}

	set_title(field.get("Name", ""))

	var image_path = "res://Assets/UIAssets/Accessories/{0}.jpg".format([field.get("Name", "")])
	if ResourceLoader.exists(image_path):
		set_icon(load(image_path))
	else:
		set_icon(load("res://Assets/UIAssets/Unavailable.png"))

	set_label(field.get("Remarks", ""))

	var unlocked = GameManager.is_parts_unlocked(table_name, id)
	parts_unlock_button.visible = !unlocked

	var equipped = GameManager.is_equipped(vehicle_id, table_name, id)
	load_button.visible = unlocked and !equipped
	unload_button.visible = unlocked and equipped

	icon.use_parent_material = !unlocked
	label.use_parent_material = !unlocked

	return field
