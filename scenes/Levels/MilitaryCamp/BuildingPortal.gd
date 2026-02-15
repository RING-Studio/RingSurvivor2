extends Area2D

@export var target_scene: StringName = &""
@export var interact_distance: float = 48.0

var _player: Node2D = null
var _in_range: bool = false

func _ready() -> void:
	monitoring = true
	set_process(true)
	if has_node("Label"):
		$Label.visible = false

func _process(delta: float) -> void:
	if _player == null:
		var players: Array = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			_player = players[0] as Node2D
		return

	var dist: float = global_position.distance_to(_player.global_position)
	_in_range = dist <= interact_distance
	if has_node("Label"):
		$Label.visible = _in_range

func try_interact() -> void:
	if _in_range and target_scene != &"":
		Transitions.set_next_scene(target_scene)
		Transitions.transition(Transitions.transition_type.Diamond)
