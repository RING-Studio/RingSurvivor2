extends CanvasLayer

signal upgrade_selected(upgrade: String)

@export var upgrade_card_scene: PackedScene

@onready var card_container: HBoxContainer = $%CardContainer


func _ready():
	get_tree().paused = true


func set_ability_upgrades(upgrades: Array[Dictionary]):
	var delay = 0
	for upgrade_data in upgrades:
		var card_instance = upgrade_card_scene.instantiate()
		card_container.add_child(card_instance)
		card_instance.set_upgrade_data(upgrade_data)
		card_instance.play_in(delay)
		card_instance.selected.connect(on_upgrade_selected)
		delay += .2


func on_upgrade_selected(upgrade: String):
	upgrade_selected.emit(upgrade)
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	queue_free()
