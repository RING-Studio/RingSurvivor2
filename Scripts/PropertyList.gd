extends GridContainer
class_name PropertyList

var property: Dictionary[String, Variant]


func _visual_update():
	for child in self.get_children():
		self.remove_child(child)
	
	for key in property.keys():
		if key == "Id" or key == "Name" or key == "Remarks":
			continue

		var label = Label.new()
		var value = str(int(property[key]))
		if key.ends_with("Ratio") or key.ends_with("Percent"):
			value = str(int(property[key] * 100)) + "%"
		label.text = TranslationServer.translate(key) + " : " + value
		self.add_child(label)


func replace_property(data):
	if data:
		property.clear()
		for key in data.keys():
			property[key] = data[key]
	
	_visual_update()
