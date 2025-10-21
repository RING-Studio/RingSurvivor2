extends Control

@export var back_scene: StringName = &""
@export var tech_list: TechList
@export var preview_icon: Button
@export var preview_tech_name: Label
@export var preview_tech_info: Label
@export var upgrade_button: Button

var techs: Dictionary[int, Dictionary]
var previewed_tech_id: int

func _ready() -> void:
	Transitions.transition(3, true)
	load_techs()

func _back_to_menu():
	Transitions.set_next_scene(back_scene)
	Transitions.transition( 3 )

func load_techs():
	for tech in JsonManager.get_category("科研"):
		techs[int(tech["ID"])] = tech
		tech_list.add_item(tech, change_previewed_item)

func change_previewed_item(id: int) -> void:
	assert(techs.has(id) and int(techs[id]["ID"]) == id)
	# 切换预览项目
	previewed_tech_id = id
	var tech = techs[id]
	# 图标
	preview_icon.visible = true
	preview_icon.text = tech["Name"]
	# 科技名称/等级
	preview_tech_name.visible = true
	var level = 0
	if GameManager.tech_upgrades.has(id):
		level = GameManager.tech_upgrades[id]
	preview_tech_name.text = tech["Name"] + " " + "等级" + str(level)
	# 科技描述
	if tech.has("Remarks"):
		preview_tech_info.visible = true
		preview_tech_info.text = tech["Remarks"]
	else:
		preview_tech_info.visible = false
	# 检查等级范围
	var current_level = GameManager.tech_upgrades.get(id, 0)
	if current_level == int(tech["MaxLevel"]):
		upgrade_button.visible = false
	else:
		upgrade_button.visible = true

func upgrade_current_tech() -> void:
	#TODO: 扣钱
	if not GameManager.tech_upgrades.has(previewed_tech_id):
		GameManager.tech_upgrades[previewed_tech_id] = 0
	GameManager.tech_upgrades[previewed_tech_id] += 1
	change_previewed_item(previewed_tech_id)

func reset_all_tech() -> void:
	#TODO: 还钱
	GameManager.tech_upgrades = {}
	change_previewed_item(previewed_tech_id)
