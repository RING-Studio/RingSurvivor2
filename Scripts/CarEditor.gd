extends Control

@export var vehicle_display: TextureRect
@export var vehicle_name: Label
@export var car_name: RichTextLabel
@export var weapon_name: RichTextLabel
@export var back_scene: StringName = &""
@export var property_list : PropertyList #车辆属性面板
@export var weapon_property_list : PropertyList #主武器属性面板
@export var property_list_button : Button
@export var choice_list : Control
@export var list_display : ListDisplay
@export var vehicle_unlock_button: Button
@export var ui_equipments: UIEquipments

@export var disabled_controls: Array[Control] = []

@export var selected_slot : String = "主武器类型"

var selected_part_id = 0

var vehicle_data: Array = []

var selected_vehicle = 0
var max_vehicles = 4

func _ready() -> void:
	Transitions.transition(Transitions.transition_type.Diamond, true)
	if list_display:
		list_display.accessory_level_changed.connect(_on_accessory_level_changed)
	_update_vehicle_selection()
	switch_to_main_weapon(true)

func _on_accessory_level_changed(_accessory_id: String, _new_level: int) -> void:
	_update_vehicle_selection()

func switch_to_Accessories(_id: int = 0):
	selected_slot = "配件"
	refresh_choice_list(selected_slot)
	# 第一个配件已在 refresh_choice_list 内通过 _on_part_selected(first_accessory_id) 选中

func switch_to_main_weapon(enter_scene: bool = false):
	selected_slot = "主武器类型"
	refresh_choice_list(selected_slot)
	_on_part_selected(0, not enter_scene)

func switch_to_armor():
	selected_slot = "装甲类型"
	refresh_choice_list(selected_slot)
	_on_part_selected(0)

func refresh_choice_list(slot:String) -> void:
	for child in choice_list.get_children():
		choice_list.remove_child(child)

	# 配件槽：从 AbilityUpgradeData 的 accessory 构建，id 为 upgrade_id（String）
	if slot == "配件":
		var first_accessory_id: String = ""
		for entry in AbilityUpgradeData.entries:
			if entry.get("upgrade_type", "") != "accessory":
				continue
			var part_name: String = entry.get("name", "")
			var part_id: String = entry.get("id", "")
			if first_accessory_id.is_empty():
				first_accessory_id = part_id
			var button: Button = property_list_button.duplicate()
			var unlocked: bool = GameManager.is_parts_unlocked(slot, part_id)
			if unlocked:
				button.text = part_name
			else:
				button.text = "🔒 " + part_name
			button.button_up.connect(_bind_part_selected(part_id))
			choice_list.add_child(button)
			button.show()
			button.use_parent_material = !unlocked
			if GameManager.is_vehicle_unlocked(selected_vehicle):
				if unlocked:
					if GameManager.is_equipped(selected_vehicle, slot, part_id):
						button.modulate = Color(0.5, 1, 0, 1)
					else:
						button.modulate = Color(0.5, 1, 1, 1)
				else:
					# 未解锁：灰色显示
					button.modulate = Color(0.4, 0.4, 0.4, 1)
			else:
				button.use_parent_material = true
		# 保持当前选中项（如果仍在列表中），否则选第一个
		var keep_current: bool = false
		if selected_part_id is String and not (selected_part_id as String).is_empty():
			for entry2 in AbilityUpgradeData.entries:
				if entry2.get("upgrade_type", "") == "accessory" and entry2.get("id", "") == selected_part_id:
					keep_current = true
					break
		if keep_current:
			_on_part_selected(selected_part_id)
		elif not first_accessory_id.is_empty():
			_on_part_selected(first_accessory_id)
		return

	var table = JsonManager.get_category(slot)
	for field in table:
		var part_name = field["Name"]
		var id = field["Id"]
		var button = property_list_button.duplicate();
		button.text = part_name

		button.button_up.connect(func():
			_on_part_selected(id)
		)

		choice_list.add_child(button)
		button.show()

		var unlocked = GameManager.is_parts_unlocked(slot, id)
		button.use_parent_material = !unlocked

		if GameManager.is_vehicle_unlocked(selected_vehicle):
			if unlocked:
				if GameManager.is_equipped( selected_vehicle, slot, id ):
					button.modulate = Color(0.5,1,0,1)
				else:
					button.modulate = Color(0.5,1,1,1)
		else:
			button.use_parent_material = true

func _bind_part_selected(part_id: Variant) -> Callable:
	return func() -> void: _on_part_selected(part_id)


func _on_part_selected( id, update_property_list: bool = true ) -> void:
	var part_property = list_display.update_info( id, selected_slot, selected_vehicle)
	
	if selected_slot == "主武器类型":
		weapon_name.text = part_property.get("Name", "未知车辆")
		weapon_property_list.replace_property(part_property)
	
	selected_part_id = id

func refresh_card_data(id:int) -> void:
	# 车辆类型用英文 id：从当前槽位配置读，无则用默认
	var config = GameManager.get_vehicle_config(id)
	var vehicle_type_id: String = "improved_sedan"
	if config != null and config.get("车辆类型") is String:
		vehicle_type_id = config.get("车辆类型")
	else:
		var defaults = ["improved_sedan", "wheeled_vehicle", "armored_car", "tank"]
		if id >= 0 and id < defaults.size():
			vehicle_type_id = defaults[id]
	car_name.text = JsonManager.get_card_name_by_id(vehicle_type_id)
	var vehicle_type_data = JsonManager.get_category_by_id("车辆类型", vehicle_type_id)
	property_list.replace_property(vehicle_type_data)
	# 车辆立绘
	var image_path = "res://Assets/UIAssets/Tanks/{0}.png".format([vehicle_type_data.get("Name", "")])
	if ResourceLoader.exists(image_path):
		vehicle_display.texture = load(image_path)
	else:
		vehicle_display.texture = load("res://Assets/UIAssets/Unavailable.png")
	ui_equipments.update_equipment(id)

func change_level1():
	pass

func left_button_pressed():
	selected_vehicle = (selected_vehicle - 1 + max_vehicles) % max_vehicles
	_update_vehicle_selection()

func right_button_pressed():
	selected_vehicle = (selected_vehicle + 1) % max_vehicles
	_update_vehicle_selection()

func _update_vehicle_selection():
	vehicle_name.text = str(selected_vehicle)
	refresh_card_data(selected_vehicle)

	if GameManager.is_vehicle_unlocked(selected_vehicle):
		vehicle_unlock_button.hide()
		enable_controls(true)
	else:
		vehicle_unlock_button.show()
		enable_controls(false)

	_on_part_selected(selected_part_id)
	refresh_choice_list( selected_slot )

func _goto_level(level_name: StringName):
	if level_name.is_empty():
		print("Error: Level name is empty.")
		return

	var level_path = "res://scenes/Levels/" + level_name + ".tscn"
	get_tree().change_scene_to_file(level_path)

func _back_to_menu():
	Transitions.set_next_scene(back_scene)
	Transitions.transition(Transitions.transition_type.Diamond)

func enable_controls(enable: bool) -> void:
	for control in disabled_controls:
		resursive_enable_controls(control, enable)

func resursive_enable_controls(node: Node, enable: bool) -> void:
	for child in node.get_children():
		if child is Control:
			if child is Button:
				child.disabled = not enable
				child.modulate = Color(1,1,1,1) if enable else Color(0.5,0.5,0.5,1)
			resursive_enable_controls(child, enable)
		
func unlock_vehicle():
	if not GameManager.is_vehicle_unlocked(selected_vehicle):
		GameManager.unlocked_vehicles.append(selected_vehicle)
		vehicle_unlock_button.hide()
		enable_controls(true)
		_update_vehicle_selection()

func unlock_part():
	if not GameManager.is_parts_unlocked(selected_slot, selected_part_id):
		if not GameManager.unlocked_parts.has(selected_slot):
			GameManager.unlocked_parts[selected_slot] = []
		GameManager.unlocked_parts[selected_slot].append(selected_part_id)
		_update_vehicle_selection()

		
func equip_part():
	GameManager.equip_part( selected_vehicle, selected_slot, selected_part_id )
	_update_vehicle_selection()


func unload_part():
	GameManager.unload_part( selected_vehicle, selected_slot, selected_part_id )
	_update_vehicle_selection()


#test only
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel"):
		print( "基础伤害: " + str(GameManager.get_player_base_damage() ))
		print( "硬攻倍率: " + str(GameManager.get_player_hard_attack_multiplier_percent() ))
		print( "软攻倍率: " + str(GameManager.get_player_soft_attack_multiplier_percent() ))
		print( "硬攻深度: " + str(GameManager.get_player_hard_attack_depth_mm() ))
		print( "装甲厚度: " + str(GameManager.get_player_armor_thickness() ))
		print( "覆甲率: " + str(GameManager.get_player_armor_coverage() ))
		print( "击穿伤害减免: " + str(GameManager.get_player_armor_damage_reduction_percent() ))
		print( "-------------------" )
