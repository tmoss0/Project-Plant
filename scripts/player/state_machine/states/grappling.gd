extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	print("Entered Grappling State")
	player.grappling_hook.shoot_grapple()

func physics_update(delta: float) -> void:
	# The GrapplingHookManager now handles all updates internally
	if player.grappling_hook.is_hook_traveling():
		# Hook is traveling - manager handles the movement
		pass
	elif player.grappling_hook.is_hook_attached():
		finished.emit(GRAPPLED)
	else:
		finished.emit(FALLING)
