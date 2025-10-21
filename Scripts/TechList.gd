extends GridContainer
class_name TechList

@export var button_template: Button

func add_item(item: Dictionary, callback: Callable) -> Button:
	var button: Button = button_template.duplicate()
	var id = int(item["ID"])
	button.name = str(id)
	button.text = item["Name"]
	button.visible = true
	button.pressed.connect(callback.bind(id))
	add_child(button)
	return button
