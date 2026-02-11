extends Node2D

@export var player: CharacterBody2D
@export var next_scene: StringName = &""
@export var npc_scene: StringName = &""
@export var car_editor_scene: StringName = &""
@export var tech_scene: StringName = &""
@export var save_scene: StringName = &""


func _ready() -> void:
	Transitions.transition( Transitions.transition_type.Diamond , true)
	
func depart():
	# TODO: 任务/MAP界面完成后替换为真实出击条件
	if not can_depart():
		return

	# 初始化新游戏数据（如果还没有存档）
	if not GlobalSaveData.HasSave("autosave"):
		GameManager.init_game()

	# 检查主武器是否为空，如果为空则设置为机炮
	ensure_main_weapon()

	Transitions.set_next_scene(next_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func can_depart() -> bool:
	"""出击条件占位：目前仅要求污染值非负。"""
	return GameManager.pollution >= 0

func ensure_main_weapon():
	"""确保当前车辆有主武器，如果没有则设置为机炮"""
	var vehicle_config = GameManager.get_vehicle_config(GameManager.current_vehicle)
	if vehicle_config == null:
		# 如果没有车辆配置，创建默认配置
		GameManager.equip_part(GameManager.current_vehicle, "主武器类型", "machine_gun")
		return

	var main_weapon = vehicle_config.get("主武器类型")
	if main_weapon == null:
		GameManager.equip_part(GameManager.current_vehicle, "主武器类型", "machine_gun")
		print("主武器为空，已自动设置为机炮")

func npc():
	Transitions.set_next_scene(npc_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func car_editor():
	Transitions.set_next_scene(car_editor_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func tech_base():
	Transitions.set_next_scene(tech_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func save():
	Transitions.set_next_scene(save_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		var building := can_interact()
		if building != null:
			if building.name == "TechBase":
				tech_base()
			elif  building.name == "Depart":
				depart()
			elif building.name == "npc":
				npc()
			elif building.name == "Save":
				save()
			elif building.name == "CarEditor":
				car_editor()

func can_interact() -> Building:
	for building: Building in $Buildings.get_children():
		if building.can_interact(player):
			return building
	return null

func _process(delta: float) -> void:
	if can_interact() != null:
		player.interaction_hint.visible = true
	else:
		player.interaction_hint.visible = false
