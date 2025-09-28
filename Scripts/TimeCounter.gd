extends Panel

@export var timer:Timer
@export var time_label:Label
@export var countdown_time:int = 60  # Default countdown time in seconds

func _ready():
	timer.timeout.connect(_on_timer_timeout)
	timer.start()

func _on_timer_timeout():
	
	countdown_time -= 1

	if countdown_time <= 0:
		countdown_time = 0
		
		timer.stop()
		# Optionally, you can emit a signal or call a function to notify that the countdown has finished.

		set_process(false)

	_update_time_label()


func _update_time_label():
	var time_left = countdown_time
	var minutes = floori(time_left / 60)
	var seconds = floori(time_left) % 60
	time_label.text = "%d:%02d" % [minutes, seconds]

func _process(_delta):
	# This function runs on every frame.
	_update_time_label()
