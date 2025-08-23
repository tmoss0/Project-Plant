extends PlayerState

func enter(_add_named_global_constantprevious_state_path: String, _data : Dictionary = {}) -> void:
	# Input animation for movement
	pass

func physics_update(delta: float) -> void:
	var input_direction_x : float = Input.get_axis("move_left", "move_right")
	if input_direction_x:
		player.velocity.x = input_direction_x * player.speed
		player.sprite.flip_h = input_direction_x < 0
	else:
		player.velocity.x = 0
	player.velocity.y += player.gravity * delta
	player.move_and_slide()

	if not player.is_on_floor():
		if player.debug_mode:
			print("Transitioning to falling state")
		finished.emit(FALLING)
	elif Input.is_action_pressed("jump"):
		if player.debug_mode:
			print("Transitioning to jumping state")
		finished.emit(JUMPING)
	elif Input.is_action_pressed("grapple"):
		if player.debug_mode:
			print("Transitioning to grappling state")
		finished.emit(GRAPPLING)
	elif Input.is_action_pressed("burrow"):
		if player.debug_mode:
			print("Transitioning to burrowing state")
		finished.emit(BURROWING)
	elif is_equal_approx(input_direction_x, 0.0):
		if player.debug_mode:
			print("Transitioning to idle state")
		finished.emit(IDLE)
