extends CanvasLayer
## DebugConsole — 全局调试控制台（autoload）
## 在任意场景输入 "DEBUG" 激活调试模式
## 调试模式下按 ` 键呼出/隐藏控制台
## 输入命令后按回车执行

# ========== 激活检测 ==========
var _input_buffer: String = ""
const ACTIVATION_SEQUENCE: String = "DEBUG"

# ========== UI ==========
var _panel: PanelContainer = null
var _output_label: RichTextLabel = null
var _input_field: LineEdit = null
var _visible: bool = false

# ========== 命令历史 ==========
var _history: Array[String] = []
var _history_index: int = -1
var _output_lines: Array[String] = []
const MAX_OUTPUT_LINES: int = 50

# ========== 状态标志 ==========
var god_mode: bool = false
## 控制台是否正在接收输入（供玩家脚本跳过移动检测）
var is_consuming_input: bool = false


func _ready() -> void:
	layer = 100  # 最高层
	_build_ui()
	_panel.visible = false


func _build_ui() -> void:
	_panel = PanelContainer.new()
	_panel.name = "ConsolePanel"

	# 样式
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.1, 0.88)
	style.border_color = Color(0.3, 0.8, 0.3, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	_panel.add_theme_stylebox_override("panel", style)

	# 定位（左下角）
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_panel.offset_left = 8.0
	_panel.offset_bottom = -8.0
	_panel.offset_right = 520.0
	_panel.offset_top = -320.0

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_panel.add_child(vbox)

	# 标题
	var title: Label = Label.new()
	title.text = "[Debug Console]"
	title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.3))
	title.add_theme_font_size_override("font_size", 12)
	vbox.add_child(title)

	# 输出区域
	_output_label = RichTextLabel.new()
	_output_label.bbcode_enabled = true
	_output_label.scroll_following = true
	_output_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_output_label.add_theme_font_size_override("normal_font_size", 12)
	_output_label.add_theme_color_override("default_color", Color(0.8, 0.9, 0.8))
	vbox.add_child(_output_label)

	# 输入框
	_input_field = LineEdit.new()
	_input_field.placeholder_text = "输入命令..."
	_input_field.add_theme_font_size_override("font_size", 13)
	_input_field.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	_input_field.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.5))
	var input_style: StyleBoxFlat = StyleBoxFlat.new()
	input_style.bg_color = Color(0.1, 0.1, 0.15, 0.9)
	input_style.border_color = Color(0.4, 0.8, 0.4, 0.5)
	input_style.set_border_width_all(1)
	input_style.set_corner_radius_all(2)
	input_style.set_content_margin_all(4)
	_input_field.add_theme_stylebox_override("normal", input_style)
	_input_field.text_submitted.connect(_on_command_submitted)
	vbox.add_child(_input_field)

	add_child(_panel)

	_print_output("[color=lime]Debug Console 已就绪。输入 help 查看命令。[/color]")


# ========== 输入处理 ==========

func _input(event: InputEvent) -> void:
	"""_input 仅拦截 ` 键（在 GUI 之前处理，防止 ` 字符进入 LineEdit）"""
	if not (event is InputEventKey) or not event.pressed:
		return
	var key_event: InputEventKey = event as InputEventKey
	if GameManager.debug_mode and key_event.keycode == KEY_QUOTELEFT:
		_toggle_console()
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	"""_unhandled_input 处理激活序列、快捷键和控制台特殊键"""
	if not (event is InputEventKey) or not event.pressed:
		return

	var key_event: InputEventKey = event as InputEventKey

	# 控制台打开时拦截 Up/Down/Escape（LineEdit 不消费这些键）
	if _visible:
		if key_event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
			return
		elif key_event.keycode == KEY_DOWN:
			_navigate_history(1)
			get_viewport().set_input_as_handled()
			return
		elif key_event.keycode == KEY_ESCAPE:
			_hide_console()
			get_viewport().set_input_as_handled()
			return

	# 调试模式快捷键（控制台关闭时）
	if GameManager.debug_mode and not _visible:
		# = 键：获取经验
		if key_event.keycode == KEY_EQUAL or key_event.keycode == KEY_KP_ADD:
			var exp_mgr: Node = get_tree().get_first_node_in_group("experience_manager")
			if exp_mgr == null:
				exp_mgr = _find_node_by_class("ExperienceManager")
			if exp_mgr and exp_mgr.has_method("increment_experience"):
				exp_mgr.increment_experience(1.0)
				print("[Debug] +1 经验")
			get_viewport().set_input_as_handled()
			return

	# 激活序列检测（控制台未显示时检测 DEBUG 输入）
	if not _visible:
		_detect_activation(key_event)


func _detect_activation(event: InputEventKey) -> void:
	var keycode: int = event.keycode
	if keycode >= KEY_A and keycode <= KEY_Z:
		_input_buffer += char(keycode - KEY_A + 65)
		if _input_buffer.length() > ACTIVATION_SEQUENCE.length():
			_input_buffer = _input_buffer.substr(_input_buffer.length() - ACTIVATION_SEQUENCE.length())
		if _input_buffer == ACTIVATION_SEQUENCE:
			GameManager.debug_mode = not GameManager.debug_mode
			_input_buffer = ""
			if GameManager.debug_mode:
				_print_output("[color=yellow]调试模式已开启。按 ` 呼出控制台。[/color]")
				_show_console()
			else:
				_print_output("[color=yellow]调试模式已关闭。[/color]")
				_hide_console()
				god_mode = false
			print("[DebugConsole] 调试模式: %s" % ("开启" if GameManager.debug_mode else "关闭"))
			get_viewport().set_input_as_handled()
	else:
		_input_buffer = ""


func _toggle_console() -> void:
	if _visible:
		_hide_console()
	else:
		_show_console()


func _show_console() -> void:
	_visible = true
	is_consuming_input = true
	_panel.visible = true
	_input_field.grab_focus()
	_input_field.text = ""


func _hide_console() -> void:
	_visible = false
	is_consuming_input = false
	_panel.visible = false
	_input_field.release_focus()


# ========== 命令提交 ==========

func _on_command_submitted(text: String) -> void:
	var cmd: String = text.strip_edges()
	if cmd.is_empty():
		_hide_console()
		return

	# 记录历史
	_history.append(cmd)
	_history_index = _history.size()

	_print_output("[color=gray]> %s[/color]" % cmd)
	_execute_command(cmd)
	_input_field.text = ""
	_hide_console()


func _navigate_history(direction: int) -> void:
	if _history.is_empty():
		return
	_history_index = clamp(_history_index + direction, 0, _history.size() - 1)
	_input_field.text = _history[_history_index]
	_input_field.caret_column = _input_field.text.length()


# ========== 命令执行 ==========

func _execute_command(cmd: String) -> void:
	var parts: PackedStringArray = cmd.split(" ", false)
	if parts.is_empty():
		return

	var command: String = parts[0].to_lower()

	match command:
		"help":
			_cmd_help()
		"unlock":
			_cmd_unlock(parts)
		"add":
			_cmd_add(parts)
		"get":
			_cmd_get(parts)
		"god":
			_cmd_god()
		"win":
			_cmd_win()
		"lose":
			_cmd_lose()
		"xp":
			_cmd_xp(parts)
		"pollution":
			_cmd_pollution(parts)
		"money":
			_cmd_money(parts)
		"kill":
			_cmd_kill()
		"list":
			_cmd_list(parts)
		"clear":
			_output_lines.clear()
			_output_label.text = ""
		"time":
			_cmd_time(parts)
		"save":
			GlobalSaveData.save_game()
			_print_output("[color=lime]存档已保存。[/color]")
		"npc":
			_cmd_npc(parts)
		"info":
			_cmd_info()
		"unlock_acc", "ua":
			_cmd_unlock_accessory(parts)
		_:
			_print_output("[color=red]未知命令: %s。输入 help 查看帮助。[/color]" % command)


# ========== 命令实现 ==========

func _cmd_help() -> void:
	_print_output("""[color=lime]===== 可用命令 =====[/color]
[color=cyan]unlock level <id>[/color] — 解锁关卡
[color=cyan]unlock all[/color] — 解锁全部关卡
[color=cyan]unlock_acc <id>/all[/color] — 解锁配件(ua为简写)
[color=cyan]add money <n>[/color] — 增加金币
[color=cyan]add <material_id> <n>[/color] — 增加素材
[color=cyan]get <upgrade_id> [n][/color] — 获取升级（关卡内）
[color=cyan]god[/color] — 切换无敌模式
[color=cyan]win[/color] — 立即胜利（关卡内）
[color=cyan]lose[/color] — 立即失败（关卡内）
[color=cyan]xp <n>[/color] — 增加经验（关卡内）
[color=cyan]kill[/color] — 击杀所有敌人（关卡内）
[color=cyan]money[/color] — 查看当前金币
[color=cyan]pollution <n>[/color] — 设置污染值
[color=cyan]time <day> <phase>[/color] — 设置天数/时段
[color=cyan]list missions[/color] — 列出所有关卡
[color=cyan]list upgrades[/color] — 列出当前升级
[color=cyan]list materials[/color] — 列出素材库
[color=cyan]npc[/color] — 查看NPC对话进度
[color=cyan]npc <id> <n>[/color] — 设置NPC对话索引
[color=cyan]info[/color] — 游戏状态总览
[color=cyan]save[/color] — 立即存档
[color=cyan]clear[/color] — 清空输出
[color=cyan]help[/color] — 显示此帮助""")


func _cmd_unlock(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_print_output("[color=red]用法: unlock level <id> 或 unlock all[/color]")
		return

	if parts[1].to_lower() == "all":
		var count: int = 0
		for mission in MissionData.get_all_missions():
			var mid: String = str(mission.get("id", ""))
			if not mid.is_empty():
				GameManager.unlock_mission(mid)
				count += 1
		_print_output("[color=lime]已解锁全部 %d 个关卡。[/color]" % count)
		return

	if parts.size() < 3 or parts[1].to_lower() != "level":
		_print_output("[color=red]用法: unlock level <id> 或 unlock all[/color]")
		return

	var level_id: String = parts[2]
	var mission: Dictionary = MissionData.get_mission(level_id)
	if mission.is_empty():
		_print_output("[color=red]未找到关卡: %s[/color]" % level_id)
		return

	GameManager.unlock_mission(level_id)
	_print_output("[color=lime]已解锁关卡: %s (%s)[/color]" % [level_id, str(mission.get("name", ""))])


func _cmd_add(parts: PackedStringArray) -> void:
	if parts.size() < 3:
		_print_output("[color=red]用法: add money <n> 或 add <material_id> <n>[/color]")
		return

	var target: String = parts[1].to_lower()
	var amount: int = int(parts[2])

	if target == "money":
		GameManager.money += amount
		_print_output("[color=lime]金币 +%d → %d[/color]" % [amount, GameManager.money])
	else:
		# 怪物素材
		var mat_id: String = parts[1]  # 保留原始大小写
		if not GameManager.materials.has(mat_id):
			GameManager.materials[mat_id] = 0
		GameManager.materials[mat_id] = int(GameManager.materials[mat_id]) + amount
		_print_output("[color=lime]素材 %s +%d → %d[/color]" % [mat_id, amount, int(GameManager.materials[mat_id])])


func _cmd_get(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_print_output("[color=red]用法: get <upgrade_id> [n][/color]")
		return

	var upgrade_id: String = parts[1]
	var count: int = 1
	if parts.size() >= 3:
		count = max(1, int(parts[2]))

	# 检查升级数据是否存在
	var entry: Variant = AbilityUpgradeData.get_entry(upgrade_id)
	if entry == null:
		_print_output("[color=red]未找到升级: %s[/color]" % upgrade_id)
		return

	var max_level: int = int(entry.get("max_level", -1))
	var upgrade_manager: Node = get_tree().get_first_node_in_group("upgrade_manager")
	if upgrade_manager == null:
		# 没有 UpgradeManager，直接操作 current_upgrades
		pass

	for i in count:
		# 检查当前等级
		var current_level: int = GameManager.current_upgrades.get(upgrade_id, {}).get("level", 0)
		if max_level > 0 and current_level >= max_level:
			_print_output("[color=yellow]%s 已达最大等级 %d[/color]" % [upgrade_id, max_level])
			break

		if upgrade_manager and upgrade_manager.has_method("apply_upgrade"):
			upgrade_manager.apply_upgrade(upgrade_id)
		else:
			# 手动写入
			if not GameManager.current_upgrades.has(upgrade_id):
				GameManager.current_upgrades[upgrade_id] = {"level": 0}
			GameManager.current_upgrades[upgrade_id]["level"] += 1
			if max_level > 0 and GameManager.current_upgrades[upgrade_id]["level"] > max_level:
				GameManager.current_upgrades[upgrade_id]["level"] = max_level

	var final_level: int = GameManager.current_upgrades.get(upgrade_id, {}).get("level", 0)
	var name_text: String = str(entry.get("name", upgrade_id))
	_print_output("[color=lime]获取 %s ×%d → Lv.%d[/color]" % [name_text, count, final_level])


func _cmd_god() -> void:
	god_mode = not god_mode
	if god_mode:
		_print_output("[color=yellow]无敌模式已开启。[/color]")
	else:
		_print_output("[color=yellow]无敌模式已关闭。[/color]")


func _cmd_win() -> void:
	# 收集已完成目标
	var completed: Array[String] = []
	var obj_mgr: Node = _find_node_by_class("ObjectiveManager")
	if obj_mgr and obj_mgr.has_method("get_completed_secondary_ids"):
		completed = obj_mgr.get_completed_secondary_ids()
	# 触发胜利结算
	if GameManager.apply_mission_result("victory", completed):
		GlobalSaveData.save_game()
		_print_output("[color=lime]已触发胜利结算（已完成目标: %s）。[/color]" % str(completed))
	else:
		_print_output("[color=yellow]无法触发胜利（已结算或不在关卡中）。[/color]")


func _cmd_lose() -> void:
	if GameManager.apply_mission_result("defeat"):
		GlobalSaveData.save_game()
		_print_output("[color=lime]已触发失败结算。[/color]")
	else:
		_print_output("[color=yellow]无法触发失败（已结算或不在关卡中）。[/color]")


func _cmd_xp(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_print_output("[color=red]用法: xp <n>[/color]")
		return
	var amount: float = float(parts[1])
	var exp_mgr: Node = get_tree().get_first_node_in_group("experience_manager")
	if exp_mgr == null:
		# 尝试直接查找
		exp_mgr = _find_node_by_class("ExperienceManager")
	if exp_mgr and exp_mgr.has_method("increment_experience"):
		exp_mgr.increment_experience(amount)
		_print_output("[color=lime]经验 +%.1f[/color]" % amount)
	else:
		_print_output("[color=red]当前场景无 ExperienceManager。[/color]")


func _cmd_pollution(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_print_output("当前污染值: %d" % GameManager.pollution)
		return
	var value: int = int(parts[1])
	GameManager.pollution = value
	_print_output("[color=lime]污染值已设为 %d[/color]" % value)


func _cmd_money(parts: PackedStringArray) -> void:
	_print_output("当前金币: %d" % GameManager.money)


func _cmd_kill() -> void:
	var enemies: Array[Node] = get_tree().get_nodes_in_group("enemy")
	var count: int = 0
	for enemy_node in enemies:
		if not is_instance_valid(enemy_node):
			continue
		if enemy_node.has_node("HealthComponent"):
			var hc: Node = enemy_node.get_node("HealthComponent")
			if hc.has_method("damage"):
				hc.damage(99999.0)
				count += 1
	_print_output("[color=lime]已击杀 %d 个敌人。[/color]" % count)


func _cmd_time(parts: PackedStringArray) -> void:
	if parts.size() < 3:
		_print_output("当前: 第 %d 天 时段 %d" % [GameManager.day, GameManager.time_phase])
		_print_output("[color=gray]用法: time <day> <phase>[/color]")
		return
	GameManager.day = int(parts[1])
	GameManager.time_phase = int(parts[2])
	_print_output("[color=lime]已设为第 %d 天 时段 %d[/color]" % [GameManager.day, GameManager.time_phase])


func _cmd_list(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_print_output("[color=red]用法: list missions 或 list upgrades[/color]")
		return

	var target: String = parts[1].to_lower()

	if target == "missions":
		var missions: Array[Dictionary] = MissionData.get_all_missions()
		_print_output("[color=cyan]===== 关卡列表 (%d) =====[/color]" % missions.size())
		for m in missions:
			var mid: String = str(m.get("id", ""))
			var name_text: String = str(m.get("name", ""))
			var diff: int = int(m.get("difficulty", 1))
			var unlocked: bool = GameManager.is_mission_unlocked(mid)
			var cleared: int = GameManager.get_mission_clear_count(mid)
			var status: String = "[color=green]✓[/color]" if cleared > 0 else ("[color=yellow]○[/color]" if unlocked else "[color=red]✗[/color]")
			_print_output("  %s %s (%s) ★%d  通关%d次" % [status, mid, name_text, diff, cleared])

	elif target == "upgrades":
		_print_output("[color=cyan]===== 当前升级 (%d) =====[/color]" % GameManager.current_upgrades.size())
		if GameManager.current_upgrades.is_empty():
			_print_output("  (无)")
		else:
			for uid in GameManager.current_upgrades:
				var lv: int = int(GameManager.current_upgrades[uid].get("level", 0))
				var entry: Variant = AbilityUpgradeData.get_entry(uid)
				var name_text: String = str(entry.get("name", uid)) if entry != null else uid
				_print_output("  %s — %s Lv.%d" % [uid, name_text, lv])

	elif target == "materials":
		_print_output("[color=cyan]===== 素材库 =====[/color]")
		if GameManager.materials.is_empty():
			_print_output("  (无)")
		else:
			for mat_id in GameManager.materials:
				_print_output("  %s: %d" % [str(mat_id), int(GameManager.materials[mat_id])])

	else:
		_print_output("[color=red]用法: list missions / upgrades / materials[/color]")


func _cmd_npc(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		# 显示所有 NPC 对话进度
		_print_output("[color=cyan]===== NPC 对话进度 =====[/color]")
		if GameManager.npc_dialogues.is_empty():
			_print_output("  (无记录)")
		else:
			for npc_id in GameManager.npc_dialogues:
				_print_output("  %s: 索引 %d" % [str(npc_id), int(GameManager.npc_dialogues[npc_id])])
		return

	if parts.size() >= 3:
		# 设置 NPC 对话索引
		var npc_id: String = parts[1]
		var idx: int = int(parts[2])
		GameManager.npc_dialogues[npc_id] = idx
		_print_output("[color=lime]NPC %s 对话索引设为 %d[/color]" % [npc_id, idx])
	else:
		# 查看特定 NPC
		var npc_id: String = parts[1]
		var idx: int = GameManager.get_npc_dialogue_index(npc_id)
		_print_output("NPC %s: 索引 %d" % [npc_id, idx])


func _cmd_info() -> void:
	_print_output("[color=cyan]===== 游戏状态总览 =====[/color]")
	_print_output("天数: %d  时段: %d/%d" % [GameManager.day, GameManager.time_phase, GameManager.PHASES_PER_DAY])
	_print_output("污染值: %d  金币: %d" % [GameManager.pollution, GameManager.money])
	_print_output("当前任务: %s" % GameManager.current_mission_id)
	_print_output("当前章节: %d" % GameManager.chapter)
	_print_output("当前车辆: %d" % GameManager.current_vehicle)
	# 素材统计
	var mat_count: int = 0
	for mat_id in GameManager.materials:
		mat_count += int(GameManager.materials[mat_id])
	_print_output("素材总量: %d 种 %d 个" % [GameManager.materials.size(), mat_count])
	# 配件解锁统计
	var acc_unlocked: int = 0
	var acc_total: int = 0
	for entry in AbilityUpgradeData.entries:
		if entry.get("upgrade_type", "") == "accessory":
			acc_total += 1
			if GameManager.is_parts_unlocked("配件", entry.get("id", "")):
				acc_unlocked += 1
	_print_output("配件解锁: %d / %d" % [acc_unlocked, acc_total])
	# NPC 对话
	_print_output("NPC 对话记录: %d 个" % GameManager.npc_dialogues.size())
	# 关卡通关
	var cleared_count: int = 0
	for m in MissionData.get_all_missions():
		if GameManager.get_mission_clear_count(str(m.get("id", ""))) > 0:
			cleared_count += 1
	_print_output("关卡通关: %d / %d" % [cleared_count, MissionData.get_all_missions().size()])


func _cmd_unlock_accessory(parts: PackedStringArray) -> void:
	if parts.size() < 2:
		_print_output("[color=red]用法: unlock_acc <id> 或 unlock_acc all[/color]")
		return

	var target: String = parts[1].to_lower()

	if target == "all":
		var count: int = 0
		if not GameManager.unlocked_parts.has("配件"):
			GameManager.unlocked_parts["配件"] = []
		for entry in AbilityUpgradeData.entries:
			if entry.get("upgrade_type", "") != "accessory":
				continue
			var acc_id: String = entry.get("id", "")
			if not GameManager.is_parts_unlocked("配件", acc_id):
				GameManager.unlocked_parts["配件"].append(acc_id)
				count += 1
		_print_output("[color=lime]已解锁全部配件 +%d 个。[/color]" % count)
		return

	# 解锁单个配件
	var acc_id: String = parts[1]
	var entry: Variant = AbilityUpgradeData.get_entry(acc_id)
	if entry == null:
		_print_output("[color=red]未找到配件: %s[/color]" % acc_id)
		return

	if GameManager.is_parts_unlocked("配件", acc_id):
		_print_output("[color=yellow]配件 %s 已解锁。[/color]" % acc_id)
		return

	if not GameManager.unlocked_parts.has("配件"):
		GameManager.unlocked_parts["配件"] = []
	GameManager.unlocked_parts["配件"].append(acc_id)
	_print_output("[color=lime]已解锁配件: %s (%s)[/color]" % [acc_id, str(entry.get("name", acc_id))])


# ========== God Mode 钩子 ==========

func is_god_mode() -> bool:
	"""供 HealthComponent 等检查无敌状态"""
	return GameManager.debug_mode and god_mode


# ========== 辅助 ==========

func _print_output(text: String) -> void:
	_output_lines.append(text)
	if _output_lines.size() > MAX_OUTPUT_LINES:
		_output_lines = _output_lines.slice(_output_lines.size() - MAX_OUTPUT_LINES)
	_output_label.text = "\n".join(_output_lines)


func _find_node_by_class(class_name_str: String) -> Node:
	"""在当前场景树中查找指定类名的节点"""
	var root: Node = get_tree().current_scene
	if root == null:
		return null
	return _recursive_find(root, class_name_str)


func _recursive_find(node: Node, class_name_str: String) -> Node:
	if node.get_class() == class_name_str or node.name == class_name_str:
		return node
	for child in node.get_children():
		var found: Node = _recursive_find(child, class_name_str)
		if found:
			return found
	return null
