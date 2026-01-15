extends PanelContainer

signal selected(upgrade_id: String)

@onready var name_label: Label = $%NameLabel
@onready var description_label: Label = $%DescriptionLabel
@export var level_label: Label

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
	
	var current_level = GameManager.current_upgrades.get(data["id"], {"level": 0})["level"]
		level_label.text = "lv{0}->lv{1}".format([current_level, current_level + 1])


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
