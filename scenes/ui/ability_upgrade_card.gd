extends PanelContainer

signal selected(upgrade_id: String)

@onready var name_label: Label = $%NameLabel
@onready var description_label: RichTextLabel = $%DescriptionLabel
@onready var level_label: RichTextLabel = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/LevelLabel
@onready var neworup_label: Label = $%NEWorUP
@onready var icon_texture_rect: TextureRect = $%Icon

var disabled = false
var upgrade_data: Dictionary


func _ready():
	gui_input.connect(on_gui_input)
	mouse_entered.connect(on_mouse_entered)


func play_in(delay: float = 0):
	modulate = Color.TRANSPARENT
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("in")
	

func play_discard():
	$AnimationPlayer.play("discard")


func set_upgrade_data(data: Dictionary):
	if data == null:
		return
	upgrade_data = data

	name_label.text = data.get("name", "未知强化")
	description_label.text = data.get("description", "")
	
	# 获取当前等级和最大等级
	var current_level = GameManager.current_upgrades.get(data["id"], {"level": 0})["level"]
	var max_level = data.get("max_level", -1)
	var next_level = current_level + 1
	
	# 设置 NEWorUP Label
	if current_level == 0:
		# 未拥有：显示亮黄色"NEW！"
		neworup_label.text = "NEW！"
		neworup_label.modulate = Color(1.0, 0.93, 0.2, 1.0)  # 亮黄色
	else:
		# 已拥有：显示亮橙色"UPGRADE"
		neworup_label.text = "UPGRADE"
		neworup_label.modulate = Color(1.0, 0.5, 0.2, 1.0)  # 亮橙色
	
	# 设置 LevelLabel
	if current_level == 0:
		# 未拥有
		if max_level == 1:
			level_label.text = "唯一"
		else:
			level_label.text = "LV.0 → LV.1"
	else:
		# 已拥有
		if max_level != -1 and next_level >= max_level:
			level_label.text = "LV.%d → LV.MAX" % current_level
		else:
			level_label.text = "LV.%d → LV.%d" % [current_level, next_level]
	
	# 设置图标：从 AbilityUpgradeData 中获取
	var icon = AbilityUpgradeData.get_icon(data["id"])
	if icon != null:
		icon_texture_rect.texture = icon
	else:
		icon_texture_rect.texture = null


func select_card():
	disabled = true
	$AnimationPlayer.play("selected")
	
	for other_card in get_tree().get_nodes_in_group("upgrade_card"):
		if other_card == self:
			continue
		other_card.play_discard()
	
	await $AnimationPlayer.animation_finished
	selected.emit(upgrade_data["id"])


func on_gui_input(event: InputEvent):
	if disabled:
		return

	if event.is_action_pressed("LeftClick"):
		select_card()


func on_mouse_entered():
	if disabled:
		return

	$HoverAnimationPlayer.play("hover")
