extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	print("Entered Grappled State")

func physics_update(delta: float) -> void:
	# The GrapplingHookManager sets velocity, state machine handles movement
	if player.grappling_hook.is_hook_attached():
		# Manager sets the velocity, we handle the movement
		player.move_and_slide()
	else:
		# Grapple has been released, transition to falling
		finished.emit(FALLING)
