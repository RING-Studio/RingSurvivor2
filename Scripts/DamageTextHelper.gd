extends Node

var COLORS := {
	"weapon": Color(1, 1, 1, 1),
	"critical": Color(1, 0.93, 0.2, 1),
	"bleed": Color(0.9, 0.2, 0.4, 1)
}

func get_color(damage_type: String) -> Color:
	return COLORS.get(damage_type, COLORS["weapon"])
