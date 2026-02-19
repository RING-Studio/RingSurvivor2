extends CanvasLayer
## DialogueRunner — 统一 AVG 对话系统（autoload）
##
## 支持两种模式：
##   overlay  — 对话气泡覆盖在当前场景上方，不遮挡后方画面
##   fullscreen — 全屏遮盖后方场景（可选背景图、角色立绘）
##
## 用法:
##   DialogueRunner.start(resource, "start", { ... })
##   DialogueRunner.start(resource, "start")  # 默认 overlay + 暂停
##
## 配置项（Dictionary）:
##   mode          : String  = "overlay" | "fullscreen"
##   pause_scene   : bool    = true      — 是否暂停后方场景
##   free_scene    : bool    = false     — 对话结束后是否释放当前场景
##   next_scene    : String  = ""        — 释放后跳转的场景路径
##   npc_id        : String  = ""       — NPC 标识，对话结束后自动推进对话进度
##   transition_in : bool    = false     — 开始时播放过渡动画
##   transition_out: bool    = false     — 结束时播放过渡动画
##   bg_color      : Color   = Color(0,0,0,0.85)  — 全屏模式背景色
##   bg_texture    : Texture2D = null    — 全屏模式背景图
##   char_left     : Texture2D = null    — 左侧角色立绘
##   char_right    : Texture2D = null    — 右侧角色立绘

## 对话开始时发出
signal dialogue_started
## 对话结束时发出（参数为对话资源）
signal dialogue_ended(resource: DialogueResource)

# ========== 状态 ==========
var _active: bool = false
var _config: Dictionary = {}
var _balloon: Node = null
var _overlay: Control = null
var _paused_scene: bool = false

# ========== 默认配置 ==========
const DEFAULT_CONFIG: Dictionary = {
	"mode": "overlay",
	"pause_scene": true,
	"free_scene": false,
	"next_scene": "",
	"npc_id": "",  # NPC 标识，用于对话结束后自动推进进度（14.2）
	"transition_in": false,
	"transition_out": false,
	"bg_color": null,  # 初始化时设置，因为 Color 不能作为 const
	"bg_texture": null,
	"char_left": null,
	"char_right": null,
}


func _ready() -> void:
	layer = 99  # 高于普通 UI，低于 DebugConsole (100)
	process_mode = Node.PROCESS_MODE_ALWAYS  # 暂停时仍需处理


# ========== 主接口 ==========

func start(resource: DialogueResource, title: String = "start", config: Dictionary = {}) -> void:
	"""启动对话。resource: .dialogue 资源, title: 对话起始标签, config: 配置字典"""
	if _active:
		push_warning("[DialogueRunner] 对话已在进行中，忽略重复调用")
		return

	# 合并配置
	_config = DEFAULT_CONFIG.duplicate()
	if _config["bg_color"] == null:
		_config["bg_color"] = Color(0.0, 0.0, 0.0, 0.85)
	for key in config:
		_config[key] = config[key]

	_active = true
	dialogue_started.emit()

	# 过渡动画
	if _config["transition_in"]:
		Transitions.transition(Transitions.transition_type.Diamond, true)

	# 暂停
	if _config["pause_scene"]:
		get_tree().paused = true
		_paused_scene = true

	# 全屏模式：创建遮罩
	if _config["mode"] == "fullscreen":
		_create_fullscreen_overlay()

	# 显示对话气泡
	_balloon = DialogueManager.show_dialogue_balloon(resource, title)
	if _balloon:
		_balloon.process_mode = Node.PROCESS_MODE_ALWAYS

	# 连接结束信号
	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func is_active() -> bool:
	return _active


# ========== 全屏遮罩 ==========

func _create_fullscreen_overlay() -> void:
	_overlay = Control.new()
	_overlay.name = "FullscreenOverlay"
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# 背景色
	var bg_rect: ColorRect = ColorRect.new()
	bg_rect.name = "BgColor"
	bg_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg_rect.color = _config["bg_color"] as Color
	bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(bg_rect)

	# 背景图
	var bg_tex: Texture2D = _config.get("bg_texture") as Texture2D
	if bg_tex:
		var tex_rect: TextureRect = TextureRect.new()
		tex_rect.name = "BgTexture"
		tex_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		tex_rect.texture = bg_tex
		tex_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tex_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		tex_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_overlay.add_child(tex_rect)

	# 左侧角色立绘
	var char_left: Texture2D = _config.get("char_left") as Texture2D
	if char_left:
		var left_rect: TextureRect = _create_character_rect(char_left, "CharLeft", 0.0, 0.05)
		_overlay.add_child(left_rect)

	# 右侧角色立绘
	var char_right: Texture2D = _config.get("char_right") as Texture2D
	if char_right:
		var right_rect: TextureRect = _create_character_rect(char_right, "CharRight", 0.55, 0.05)
		_overlay.add_child(right_rect)

	add_child(_overlay)


func _create_character_rect(tex: Texture2D, node_name: String, anchor_left: float, anchor_top: float) -> TextureRect:
	var rect: TextureRect = TextureRect.new()
	rect.name = node_name
	rect.texture = tex
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# 立绘占屏幕约 45% 宽度，从 anchor_top 到底部
	rect.anchor_left = anchor_left
	rect.anchor_top = anchor_top
	rect.anchor_right = anchor_left + 0.45
	rect.anchor_bottom = 1.0
	rect.offset_left = 0.0
	rect.offset_top = 0.0
	rect.offset_right = 0.0
	rect.offset_bottom = 0.0
	return rect


# ========== 对话结束回调 ==========

func _on_dialogue_ended(_resource: DialogueResource) -> void:
	if not _active:
		return

	_active = false

	# 断开信号
	if DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.disconnect(_on_dialogue_ended)

	# 清理气泡引用
	_balloon = null

	# 清理全屏遮罩
	if _overlay:
		_overlay.queue_free()
		_overlay = null

	# 恢复暂停
	if _paused_scene:
		get_tree().paused = false
		_paused_scene = false

	# NPC 对话进度推进（14.2）
	var npc_id: String = _config.get("npc_id", "") as String
	if not npc_id.is_empty():
		GameManager.advance_npc_dialogue(npc_id)

	# 场景切换
	var should_switch: bool = _config.get("free_scene", false) and not (_config.get("next_scene", "") as String).is_empty()
	if should_switch:
		var next: String = _config["next_scene"] as String
		if _config.get("transition_out", false):
			Transitions.set_next_scene(next)
			Transitions.transition(Transitions.transition_type.Diamond)
		else:
			get_tree().change_scene_to_file(next)
	elif _config.get("transition_out", false):
		Transitions.transition(Transitions.transition_type.Diamond, true)

	dialogue_ended.emit(_resource)
