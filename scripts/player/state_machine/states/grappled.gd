extends PlayerState

func enter(_previous_state_path: String, _data : Dictionary = {}) -> void:
	pass

func physics_update(delta: float) -> void:
	# Apply gravity while grappled
	player.velocity.y += player.gravity * delta
	
	if player.grappling_hook.is_hook_attached():
		player.move_and_slide()
	else:
		finished.emit(FALLING)
