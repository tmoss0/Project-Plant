extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	print("Entered Grappled State")

func physics_update(delta: float) -> void:
	if player.grappling_hook.is_hook_attached:
		player.grappling_hook.handle_grappled_player_movement(delta)
	elif Input.is_action_pressed("jump"):
		player.grappling_hook.release_grapple()
		finished.emit(FALLING)
