extends Control
class_name ConfirmPanel

@export var title_label: Label
@export var ok: Button
@export var cancel: Button

func _ready() -> void:
	visibility_changed.connect(on_visibility_changed)

func pop_up( title:String):
	title_label.text = title
	show()

func remove_all_signals():
	disconnect_all_from_signal(ok, "button_up")
	disconnect_all_from_signal(cancel, "button_up")


func disconnect_all_from_signal(node: Node, signal_name: String):
	var connections = node.get_signal_connection_list(signal_name)

	for i in connections.size():
		var callable_method = connections.get(i)
		node.disconnect( signal_name, callable_method.get("callable"))

func on_visibility_changed():
	if !visible:
		remove_all_signals()
