#region Code Explanation
"""
The player will be able to fall (downward if on a higher platform), jump up and
horizontally
"""
#endregion

extends PlayerState

func enter(_previous_state_path: String, _data := {}) -> void:
	player.velocity.x = 0.0

func physics_update(_delta: float) -> void:
	player.velocity.y += player.gravity * _delta
	player.move_and_slide()

	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		finished.emit(MOVING)
	elif Input.is_action_pressed("jump"):
		finished.emit(JUMPING)
	elif Input.is_action_pressed("grapple"):
		finished.emit(GRAPPLING)
	elif Input.is_action_pressed("burrow"):
		finished.emit(BURROWING)
