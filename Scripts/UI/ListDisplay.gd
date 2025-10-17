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

func update_info(id:int, table_name:String, vehicle_id:int) -> Dictionary:
	var table = JsonManager.get_category(table_name)
	var field = table.get(id)
	if field == null:
		return field

	set_title( field["Name"] )    

	var image_path = "res://Assets/UIAssets/Accessories/{0}.jpg".format([field["Name"]])
	if ResourceLoader.exists(image_path):
		set_icon( load(image_path) )
	else:
		set_icon( load("res://Assets/UIAssets/Unavailable.png") )

	set_label( field["Remarks"] )
	
	var unlocked = GameManager.is_parts_unlocked(table_name, id)
	parts_unlock_button.visible = !unlocked
	
	var equipped = GameManager.is_equipped( vehicle_id, table_name, id )
	load_button.visible = unlocked and !equipped
	unload_button.visible = unlocked and equipped

	icon.use_parent_material = !unlocked
	label.use_parent_material = !unlocked
	
	# 返回当前选项的属性，用于更新属性面板
	return field
