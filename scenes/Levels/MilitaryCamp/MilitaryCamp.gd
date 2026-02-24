extends Node2D

@export var player: CharacterBody2D
@export var next_scene: StringName = &""
@export var npc_scene: StringName = &""
@export var car_editor_scene: StringName = &""
@export var save_scene: StringName = &""
## 机械师对话资源
@export var npc_dialogue_resource: DialogueResource
## 机械师对话背景图
@export var npc_bg_texture: Texture2D
## 机械师左侧角色立绘
@export var npc_char_left: Texture2D
## 机械师右侧角色立绘
@export var npc_char_right: Texture2D
## 军需官对话资源
@export var qm_dialogue_resource: DialogueResource

const MissionMapScene: PackedScene = preload("res://scenes/ui/mission_map.tscn")
const ProgressionHUDScript: GDScript = preload("res://scenes/ui/progression_hud.gd")
var _mission_map: MissionMap = null
var _progression_hud: ProgressionHUD = null

# NPC 对话序列定义（14.2）— 按顺序播放，每次对话推进索引
# 格式: { "npc_id": [Array of dialogue title strings] }
const NPC_DIALOGUE_SEQUENCES: Dictionary = {
	"npc_mechanic": ["intro", "day2", "day3", "idle"],
	"npc_quartermaster": ["intro", "day2", "day3", "day4", "idle"],
}


func _ready() -> void:
	Transitions.transition( Transitions.transition_type.Diamond , true)
	_progression_hud = ProgressionHUDScript.new()
	add_child(_progression_hud)
	
func depart():
	if not can_depart():
		return
	# 初始化新游戏数据（如果还没有存档）
	if not GlobalSaveData.HasSave("autosave"):
		GameManager.init_game()
	_open_mission_map()

func can_depart() -> bool:
	"""出击条件占位：目前仅要求污染值非负。"""
	return GameManager.pollution >= 0

func _open_mission_map() -> void:
	if _mission_map == null:
		_mission_map = MissionMapScene.instantiate() as MissionMap
		add_child(_mission_map)
		_mission_map.mission_confirmed.connect(_on_mission_confirmed)
		_mission_map.canceled.connect(_on_mission_canceled)
	_mission_map.open()
	_set_player_control(false)
	if _progression_hud:
		_progression_hud.visible = false

func _on_mission_confirmed(mission_id: String) -> void:
	_set_player_control(true)
	if _progression_hud:
		_progression_hud.visible = true
		_progression_hud.refresh()
	if GameManager.select_mission(mission_id):
		_start_depart()

func _on_mission_canceled() -> void:
	_set_player_control(true)
	if _progression_hud:
		_progression_hud.visible = true
		_progression_hud.refresh()

func _set_player_control(enabled: bool) -> void:
	"""启用或禁用玩家移动与交互"""
	if player:
		player.set_process_input(enabled)
		player.set_physics_process(enabled)
		player.set_process(enabled)

func _start_depart() -> void:
	ensure_main_weapon()
	# Mark E.2：出击时扣除配装费用
	if not GameManager.deduct_sortie_cost():
		push_warning("[Depart] 资源不足，无法出击")
		return
	var mission: Dictionary = MissionData.get_mission(GameManager.current_mission_id)
	var scene_path: String = mission.get("scene_path", "")
	if scene_path.is_empty():
		scene_path = next_scene
	Transitions.set_next_scene(scene_path)
	Transitions.transition( Transitions.transition_type.Diamond )

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
	_start_npc_dialogue("npc_mechanic", npc_dialogue_resource)

func npc_quartermaster():
	_start_npc_dialogue("npc_quartermaster", qm_dialogue_resource)

func _start_npc_dialogue(npc_id: String, resource: DialogueResource) -> void:
	if not resource:
		push_warning("[MilitaryCamp] 对话资源为空: %s" % npc_id)
		return
	var sequence: Array = NPC_DIALOGUE_SEQUENCES.get(npc_id, ["start"])
	var title: String = GameManager.get_npc_dialogue_title(npc_id, sequence)

	var config: Dictionary = {
		"mode": "fullscreen",
		"pause_scene": true,
		"free_scene": false,
		"npc_id": npc_id,
	}
	if npc_bg_texture:
		config["bg_texture"] = npc_bg_texture
	if npc_char_left:
		config["char_left"] = npc_char_left
	if npc_char_right:
		config["char_right"] = npc_char_right
	_set_player_control(false)
	if _progression_hud:
		_progression_hud.visible = false
	DialogueRunner.dialogue_ended.connect(_on_npc_dialogue_ended, CONNECT_ONE_SHOT)
	DialogueRunner.start(resource, title, config)

func _on_npc_dialogue_ended(_resource: DialogueResource) -> void:
	_set_player_control(true)
	if _progression_hud:
		_progression_hud.visible = true
		_progression_hud.refresh()

func car_editor():
	Transitions.set_next_scene(car_editor_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func save():
	Transitions.set_next_scene(save_scene)
	Transitions.transition( Transitions.transition_type.Diamond )

func _unhandled_input(event: InputEvent) -> void:
	# 对话进行中不处理交互
	if DialogueRunner.is_active():
		return
	# 任务地图打开时不处理交互
	if _mission_map != null and _mission_map.visible:
		return
	if event.is_action_pressed("interact"):
		var building: Building = can_interact()
		if building != null:
			if building.name == "Depart":
				depart()
			elif building.name == "npc":
				npc()
			elif building.name == "npc_quartermaster":
				npc_quartermaster()
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
	# 面板打开时隐藏交互提示
	if _mission_map != null and _mission_map.visible:
		player.interaction_hint.visible = false
		return
	if can_interact() != null:
		player.interaction_hint.visible = true
	else:
		player.interaction_hint.visible = false
