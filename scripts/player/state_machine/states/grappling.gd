extends PlayerState

func enter(_previous_state_path: String, _data : Dictionary = {}) -> void:
	player.grappling_hook.shoot_grapple()

func physics_update(_delta: float) -> void:
	if player.grappling_hook.is_traveling():
		pass
	elif player.grappling_hook.is_attached():
		finished.emit(GRAPPLED)
	else:
		finished.emit(FALLING)
