extends CharacterBody2D

@export var SPEED: float = 300.0
@export var JUMP_VELOCITY: float = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
@onready var sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer

func _ready() -> void:
	# Ensure animations are set up
	if sprite and !sprite.is_playing():
		sprite.play("idle")

func _physics_process(delta: float) -> void:
	# Add the gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and (is_on_floor() or !coyote_timer.is_stopped()):
		velocity.y = JUMP_VELOCITY
		sprite.play("jump")
		coyote_timer.stop()
	
	# Get the input direction and handle the movement
	var direction := Input.get_axis("move_left", "move_right")
	
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = 0  # Immediately stop when no input

	move_and_slide()
	
	# Update animations based on state
	update_animations(direction)
	
	# Start coyote timer when leaving the ground
	if !is_on_floor() and was_on_floor():
		coyote_timer.start()

func update_animations(direction: float) -> void:
	if !is_on_floor():
		# If moving upward, play jump animation
		if velocity.y < 0:
			if sprite.animation != "jump":
				sprite.play("jump")
		# If moving downward, play fall animation
		elif velocity.y > 0:
			if sprite.animation != "fall":
				sprite.play("fall")
	else:
		# On ground animations
		if direction != 0:  # If there's any horizontal input
			if sprite.animation != "idle":
				sprite.play("idle")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")

func was_on_floor() -> bool:
	return get_last_slide_collision() != null and get_last_slide_collision().get_normal().y < -0.5
