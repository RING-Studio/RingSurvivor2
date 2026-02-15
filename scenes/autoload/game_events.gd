extends Node

signal experience_vial_collected(number: float)
signal ability_upgrade_added(upgrade_id: String, current_upgrades: Dictionary)
signal player_damaged
signal experience_updated(current_experience: float, target_experience: float)
signal level_up(new_level: int)
signal health_changed(current:Transitions.transition_type, max:int)
signal collectible_collected(collectible_type: String)

func emit_experience_vial_collected(number: float):
	experience_vial_collected.emit(number)


func emit_ability_upgrade_added(upgrade_id: String, current_upgrades: Dictionary):
	ability_upgrade_added.emit(upgrade_id, current_upgrades)


func emit_player_damaged():
	player_damaged.emit()


func emit_collectible_collected(collectible_type: String):
	collectible_collected.emit(collectible_type)
