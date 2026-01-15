extends Control

@onready var level_label: Label = %LevelLabel
@onready var health_bar: TextureProgressBar = %HealthBar
@onready var xp_bar: TextureProgressBar = %XPBar
@onready var health_label: Label = %HealthLabel

func _enter_tree() -> void:
	GameEvents.experience_updated.connect(experience_updated)
	GameEvents.level_up.connect(level_up)
	GameEvents.health_changed.connect(health_changed)

func _exit_tree() -> void:
	GameEvents.experience_updated.disconnect(experience_updated)
	GameEvents.level_up.disconnect(level_up)
	GameEvents.health_changed.disconnect(health_changed)

# func _unhandled_input(event: InputEvent) -> void:
	# if event.is_action_pressed("open_menu"):
	# 	if inventory.visible:
	# 		close_menu()
	# 	else:
	# 		open_menu()

func level_up(current_level):
	level_label.text = str(current_level)

func update_stats_display() -> void:
	# level_label.text = str(player.stats.level)
	# xp_bar.max_value = player.stats.percentage_level_up_boundary()
	# xp_bar.value = player.stats.xp
	pass

func health_changed(current:int, max_health:int):
	health_bar.max_value = max_health
	health_bar.value = current
	health_label.text = str(current) + " / " + str(max_health)
	
# func open_menu() -> void:
# 	inventory.visible = true
# 	get_tree().paused = true
# 	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	
# func close_menu() -> void:
# 	inventory.visible = false
# 	get_tree().paused = false
# 	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func experience_updated(current_experience: float, target_experience: float):
	xp_bar.max_value = target_experience
	xp_bar.value = current_experience

func ability_upgrade_added(upgrade: AbilityUpgrade, current_upgrades: Dictionary):
	pass

func player_damaged():
	pass
