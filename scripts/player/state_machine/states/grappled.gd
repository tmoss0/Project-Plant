extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	print("Entered Grappled State")

func physics_update(delta: float) -> void:
	# The GrapplingHookManager now handles movement and input internally
	if player.grappling_hook.is_hook_attached():
		# Manager handles pulling the player and auto-release
		pass
	else:
		# Grapple has been released, transition to falling
		finished.emit(FALLING)
