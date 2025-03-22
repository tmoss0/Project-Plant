extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	player.velocity.y = player.jump_velocity
	player.sprite.play("jump")
	player.coyote_timer.stop()

func physics_update(_delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left", "move_right")
	player.velocity.x = player.speed * input_direction_x
	player.velocity.y += player.gravity * _delta
	player.move_and_slide()

	if player.velocity.y >= 0:
		finished.emit(FALLING)
	elif Input.is_action_pressed("grapple"):
		finished.emit(GRAPPLING)
