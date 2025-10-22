extends CharacterBody2D

@export var move_speed: float = 300.0
@export var interaction_hint: Label
@onready var shape: Rect2 = $CollisionShape2D.shape.get_rect()

func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	input_vector.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	input_vector.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	velocity = input_vector * move_speed
	move_and_slide()
