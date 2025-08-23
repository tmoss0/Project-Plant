extends PlayerState

func enter(_previous_state_path: String, _data : Dictionary = {}) -> void:
	pass

func physics_update(_delta: float) -> void:
	# The GrapplingHookManager now handles movement and input internally
	if player.grappling_hook.is_hook_attached():
		# Manager sets the velocity, we handle the movement
		player.move_and_slide()
	else:
		# Grapple has been released, transition to falling
		finished.emit(FALLING)
