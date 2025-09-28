extends Control

@export var button_template: Button
@export var button_root: Control
@export var confirm_panel : ConfirmPanel

func _ready() -> void:
	Transitions.transition( Transitions.transition_type.Diamond , true)
	button_template.hide()
	
	refresh()	

func refresh():
	for child in button_root.get_children():
		button_root.remove_child(child)

	for i in range(20):
		var file_path = "save" + str(i)

		if i == 0:
			file_path = "autosave"

		var info = str(i) + " 空"

		if i == 0:
			info = "自动存档"

		if GlobalSaveData.HasSave(file_path):
			var save_data = GlobalSaveData.get_save_time(file_path)
			var save_time =  save_data["save_time"]
			var day = save_data["game_state"]["day"]
			var chapter = save_data["game_state"]["chapter"]
			var mission_progress = save_data["game_state"]["mission_progress"]

			info = "{0} {1}  第{2}天 章节:{3} 进度:{4}".format([i, save_time, day as int , chapter as int, mission_progress] )

		var button = create_button(info)

		button.button_up.connect(func():

			if GlobalSaveData.HasSave(file_path):
				confirm_panel.pop_up("是否覆盖存档？")
				confirm_panel.canel.button_up.connect(func():
					confirm_panel.hide()
				)

				confirm_panel.ok.button_up.connect(func():
					confirm_panel.hide()
					GlobalSaveData.save_game("user://" +file_path + ".json")
					refresh()
				)
			else:
				GlobalSaveData.save_game("user://" +file_path + ".json")
				refresh()
		)

		button.get_child(0).button_up.connect(func():
			if GlobalSaveData.HasSave(file_path):
				var path = "user://" + file_path + ".json"
				DirAccess.remove_absolute(path)
				refresh()
		)

func create_button(text: String):
	var button: Button = button_template.duplicate()
	button.text = text
	button.show()
	button_root.add_child(button)
	return button

func _on_exit_button_up() -> void:
	Transitions.set_next_scene("res://Levels/MilitaryCamp.tscn")
	Transitions.transition(Transitions.transition_type.Diamond)
