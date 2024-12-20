extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	print("Entered Grappling State")
	player.grappling_hook.shoot_grapple()

func physics_update(delta: float) -> void:
	if player.grappling_hook.is_hook_traveling:
		player.grappling_hook.update_traveling_grapple(delta)
	elif player.grappling_hook.is_hook_attached:
		finished.emit(GRAPPLED)
	else:
		# If grapple is neither traveling nor attached, return to Idle/Falling
		finished.emit(FALLING)