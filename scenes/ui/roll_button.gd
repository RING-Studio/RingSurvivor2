extends Button
class_name RollButton

func play_in(delay: float = 0):
	modulate = Color.TRANSPARENT
	scale = Vector2.ZERO
	await get_tree().create_timer(delay).timeout
	$AnimationPlayer.play("in")

func play_discard():
	$AnimationPlayer.play("discard")
