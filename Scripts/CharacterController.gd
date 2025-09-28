extends CharacterBody2D

@export var speed: float = 150.0

@export var animated_sprite: AnimatedSprite2D

@export var up:StringName = "w"
@export var down:StringName	= "s"
@export var left:StringName	= "a"
@export var right:StringName = "d"


var last_direction = Vector2(0, 1) # Default to facing down

func _physics_process(_delta: float):
	# Get input using Godot's built-in input actions
	var input_direction = Input.get_vector( left, right, up, down )

	# Set velocity based on input
	if input_direction != Vector2.ZERO:
		velocity = input_direction.normalized() * speed
		last_direction = input_direction
	else:
		# If no input, gradually slow down to a stop
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	# Move the character and handle collisions
	move_and_slide()

	# Update animations based on state
	update_animation()

func update_animation():
	var anim_prefix = "Idle" if velocity == Vector2.ZERO else "Run"

	# Determine animation based on the last direction of movement
	if abs(last_direction.x) > abs(last_direction.y):
		animated_sprite.animation = anim_prefix + "Right"
		animated_sprite.flip_h = last_direction.x < 0
	else:
		animated_sprite.flip_h = false # Reset flip for vertical animations
		animated_sprite.animation = anim_prefix + ("Down" if last_direction.y > 0 else "Up")

	animated_sprite.play()
