extends Node

@export var experience_manager: Node
@export var upgrade_screen_scene: PackedScene
var upgrade_pool: WeightedTable = WeightedTable.new()

var upgrade_catalog: Dictionary = {}

func _ready():
	for entry in AbilityUpgradeData.entries:
		var upgrade_id = entry["id"]
		upgrade_catalog[upgrade_id] = entry.duplicate()
		upgrade_pool.add_item(upgrade_id, entry.get("weight", 10))
		if not GameManager.current_upgrades.has(upgrade_id):
			GameManager.current_upgrades[upgrade_id] = {"level": 0}

	GameEvents.level_up.connect(on_level_up)

func apply_upgrade(upgrade_id: String):
	if not GameManager.current_upgrades.has(upgrade_id):
		GameManager.current_upgrades[upgrade_id] = {"level": 0}

	GameManager.current_upgrades[upgrade_id]["level"] += 1

	var entry = upgrade_catalog.get(upgrade_id)
	if entry == null:
		push_warning("无法找到强化数据: %s" % upgrade_id)
		return

	var max_level = entry.get("max_level", 0)
	if max_level > 0 and GameManager.current_upgrades[upgrade_id]["level"] >= max_level:
		upgrade_pool.remove_item(upgrade_id)

	GameEvents.emit_ability_upgrade_added(upgrade_id, GameManager.current_upgrades)


# func update_upgrade_pool(chosen_upgrade: AbilityUpgrade):
# 	if chosen_upgrade.id == upgrade_axe.id:
# 		upgrade_pool.add_item(upgrade_axe_damage, 10)
# 	elif chosen_upgrade.id == upgrade_anvil.id:
# 		upgrade_pool.add_item(upgrade_anvil_count, 5)


func pick_upgrades() -> Array[Dictionary]:
	var chosen_upgrades :Array[Dictionary] = []
	var exclude := []
	for i in 3:
		if upgrade_pool.items.size() == exclude.size():
			break
		var chosen_id = upgrade_pool.pick_item(exclude)
		if chosen_id == null:
			break
		exclude.append(chosen_id)
		var entry = upgrade_catalog.get(chosen_id)
		if entry != null:
			chosen_upgrades.append(entry)
	return chosen_upgrades


func on_upgrade_selected(upgrade: String):
	apply_upgrade(upgrade)
	
func on_level_up(current_level: int):
	var upgrade_screen_instance = upgrade_screen_scene.instantiate()
	add_child(upgrade_screen_instance)
	var chosen_upgrades = pick_upgrades()
	upgrade_screen_instance.set_ability_upgrades(chosen_upgrades)
	upgrade_screen_instance.upgrade_selected.connect(on_upgrade_selected)
