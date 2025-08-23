extends PlayerState

func enter(_previous_state_path: String, _data : Dictionary = {}) -> void:
	player.grappling_hook.shoot_grapple()

func physics_update(delta: float) -> void:
	# Apply gravity while grappling
	player.velocity.y += player.gravity * delta
	
	if player.grappling_hook.is_traveling():
		player.move_and_slide()
	elif player.grappling_hook.is_attached():
		finished.emit(GRAPPLED)
	else:
		finished.emit(FALLING)
