extends Control
class_name UIEquipments

@export var textures: Array[TextureRect] = []
@export var main_weapon: TextureButton
@export var armor: TextureButton

func update_equipment(vehicle_id: int) -> void:
	hide_all_textures()

	var vehicle_data = GameManager.get_vehicle_config(vehicle_id)
	
	if vehicle_data == null:
		return

	var i = 0;
	var ids = vehicle_data.get("配件")
	if ids != null:
		for id in ids:
			var field = JsonManager.get_category_by_id("配件", id)
			textures[i].texture = get_equipment_texture(field.get("Name"))
			textures[i].self_modulate.a = 1
			i += 1

	var id = vehicle_data.get("主武器类型")
	var equipment = JsonManager.get_category_by_id("主武器类型", id)
	if equipment:
		var equipment_name = equipment.get("Name")
		main_weapon.texture_normal = get_equipment_texture(equipment_name)
	else:
		main_weapon.texture_normal = null



	id = vehicle_data.get("装甲类型")
	equipment = JsonManager.get_category_by_id("装甲类型", id)
	if equipment:
		var equipment_name = equipment.get("Name")
		armor.texture_normal = get_equipment_texture(equipment_name)
	else:
		armor.texture_normal = null

	print(GameManager.vehicles_config)
	
func get_equipment_texture(_name: String):
	var image_path = "res://Assets/UIAssets/Accessories/{0}.jpg".format([_name])
	if ResourceLoader.exists(image_path):
		return load(image_path)
	else:
		return load("res://Assets/UIAssets/Unavailable.png")

func hide_all_textures() -> void:
	for texture in textures:
		texture.self_modulate.a = 0
