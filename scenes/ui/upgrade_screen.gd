extends CanvasLayer

signal upgrade_selected(upgrade: String)

@export var upgrade_card_scene: PackedScene

@onready var card_container: HBoxContainer = $%CardContainer
@onready var roll_button: RollButton = $%RollButton

var upgrade_manager: Node = null
var current_upgrades: Array[Dictionary] = []
var is_roll_busy: bool = false
const ROLL_BUSY_TIME := 0.05

func _ready():
	get_tree().paused = true
	# 清除当前卡片
	for child in card_container.get_children():
		child.queue_free()
	# 连接刷新按钮
	if roll_button:
		roll_button.pressed.connect(on_roll_pressed)
	update_roll_display()

func set_upgrade_manager(manager: Node):
	upgrade_manager = manager

func set_ability_upgrades(upgrades: Array[Dictionary]):
	current_upgrades = upgrades
	var delay = 0
	for upgrade_data in upgrades:
		var card_instance = upgrade_card_scene.instantiate()
		card_container.add_child(card_instance)
		card_instance.set_upgrade_data(upgrade_data)
		card_instance.play_in(delay)
		card_instance.selected.connect(on_upgrade_selected)
		delay += .2
	
	# 播放Roll按钮的进入动画（延迟到最后一个卡片之后）
	play_roll_button_in(delay)

func play_roll_button_in(delay: float = 0):
	"""播放Roll按钮的进入动画"""
	if roll_button and roll_button.has_method("play_in"):
		roll_button.play_in(delay)

func update_roll_display():
	if roll_button:
		var roll_points = GameManager.roll_points
		if GameManager.debug_mode:
			roll_points = 9999
		roll_button.disabled = roll_points <= 0
		# 替换占位符 {r} 为实际的剩余次数
		roll_button.text = "刷新 (剩余%d次)" % roll_points

func on_roll_pressed():
	if is_roll_busy:
		return
	is_roll_busy = true
	get_tree().create_timer(ROLL_BUSY_TIME).timeout.connect(_clear_roll_busy)

	# 中断按钮当前动画，立即缩放为0
	if roll_button:
		var anim_player = roll_button.get_node_or_null("AnimationPlayer")
		if anim_player:
			anim_player.stop()
		roll_button.scale = Vector2.ZERO
		roll_button.modulate = Color.TRANSPARENT

	var roll_points = GameManager.roll_points
	if GameManager.debug_mode:
		roll_points = 9999
	
	if roll_points <= 0:
		return
	
	# 消耗1个roll点
	if not GameManager.debug_mode:
		GameManager.roll_points -= 1
	
	# 清除当前卡片
	for child in card_container.get_children():
		child.queue_free()
	
	# 重新抽取升级
	if upgrade_manager:
		var new_upgrades = upgrade_manager.pick_upgrades()
		set_ability_upgrades(new_upgrades)
		update_roll_display()

func _clear_roll_busy():
	is_roll_busy = false

func on_upgrade_selected(upgrade: String):
	upgrade_selected.emit(upgrade)
	$AnimationPlayer.play("out")
	await $AnimationPlayer.animation_finished
	get_tree().paused = false
	queue_free()
