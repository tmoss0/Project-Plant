extends PlayerState

func enter(_add_named_global_constantprevious_state_path: String, _data := {}) -> void:
	# Input animation for movement
	pass

func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left", "move_right")
	if input_direction_x:
		player.velocity.x = input_direction_x * player.speed
		player.sprite.flip_h = input_direction_x < 0
	else:
		player.velocity.x = 0
	player.velocity.y += player.gravity * delta
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_pressed("jump"):
		finished.emit(JUMPING)
	elif Input.is_action_pressed("grapple"):
		finished.emit(GRAPPLING)
	elif Input.is_action_pressed("burrow"):
		finished.emit(BURROWING)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
