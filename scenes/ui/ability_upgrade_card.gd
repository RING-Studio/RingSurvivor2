extends PanelContainer

signal selected

@onready var name_label: Label = $%NameLabel
@onready var description_label: Label = $%DescriptionLabel
@export var level_label: Label

var disabled = false


func _ready():
	gui_input.connect(on_gui_input)
	mouse_entered.connect(on_mouse_entered)


func play_in(delay: float = 0):
	modulate = Color.TRANSPARENT
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("in")
	

func play_discard():
	$AnimationPlayer.play("discard")


func set_ability_upgrade(upgrade_id: int):
	var data = JsonManager.get_category_by_id("配件", upgrade_id)
	if data == null:
		push_warning("无法找到配件数据: %s" % upgrade_id)
		return

	name_label.text = data.get("Name")
	
	var current_level = GameManager.current_upgrades[upgrade_id]["level"]

	if GameManager.is_equipped(GameManager.current_vehicle, "配件", upgrade_id):
		level_label.text = "lv{0}->lv{1}".format([current_level, current_level + 1])
	else:
		level_label.text = "装备"

	# description_label.text = TranslationServer.translate("BaseDamage") + ":" + str(data.get("BaseDamage"))
	# description_label.text += "\n"
	description_label.text = data.get("Remarks")


func select_card():
	disabled = true
	$AnimationPlayer.play("selected")
	
	for other_card in get_tree().get_nodes_in_group("upgrade_card"):
		if other_card == self:
			continue
		other_card.play_discard()
	
	await $AnimationPlayer.animation_finished
	selected.emit()


func on_gui_input(event: InputEvent):
	if disabled:
		return

	if event.is_action_pressed("LeftClick"):
		select_card()


func on_mouse_entered():
	if disabled:
		return

	$HoverAnimationPlayer.play("hover")
