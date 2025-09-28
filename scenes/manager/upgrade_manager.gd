extends Node

@export var experience_manager: Node
@export var upgrade_screen_scene: PackedScene
var upgrade_pool: WeightedTable = WeightedTable.new()
@export var upgrade_skills : Array[int]


func _ready():
	for upgrade_id in upgrade_skills:
		upgrade_pool.add_item(upgrade_id, 10)
	
		if GameManager.is_equipped(GameManager.current_vehicle, "配件", upgrade_id):
			GameManager.current_upgrades[upgrade_id] = {"level": 1	}
		else:
			GameManager.current_upgrades[upgrade_id] = {"level": 0	}

	
	GameEvents.level_up.connect(on_level_up)

func apply_upgrade(upgrade_id: int):
	var has_upgrade = GameManager.current_upgrades.has(upgrade_id)
	if !has_upgrade:
		GameManager.current_upgrades[upgrade_id] = {
			"level": 1
		}
	else:
		GameManager.current_upgrades[upgrade_id]["level"] += 1
	
	var data = JsonManager.get_category_by_id("配件", upgrade_id)
	if data == null:
		push_warning("无法找到配件数据: %s" % upgrade_id)
		return

	var max_level = data.get("MaxLevel") 
	if max_level > 0:
		var current_quantity = GameManager.current_upgrades[upgrade_id]["level"]
		if current_quantity == max_level:
			upgrade_pool.remove_item(upgrade_id)
	
	# update_upgrade_pool(upgrade)
	GameEvents.emit_ability_upgrade_added(upgrade_id, GameManager.current_upgrades)


# func update_upgrade_pool(chosen_upgrade: AbilityUpgrade):
# 	if chosen_upgrade.id == upgrade_axe.id:
# 		upgrade_pool.add_item(upgrade_axe_damage, 10)
# 	elif chosen_upgrade.id == upgrade_anvil.id:
# 		upgrade_pool.add_item(upgrade_anvil_count, 5)


func pick_upgrades():
	var chosen_upgrades: Array[int] = []
	for i in 3:
		# if upgrade_pool.items.size() == chosen_upgrades.size():
		# 	break
		var chosen_upgrade = upgrade_pool.pick_item(chosen_upgrades)
		chosen_upgrades.append(chosen_upgrade)
	
	return chosen_upgrades


func on_upgrade_selected(upgrade: int):
	apply_upgrade(upgrade)
	
func on_level_up(current_level: int):
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	var chosen_upgrades = pick_upgrades()
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades as Array[int])
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)
