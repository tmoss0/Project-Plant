#region Code Explanation
"""
Move the player based on the user's input
"""
#endregion

extends PlayerState

func enter(previous_state_path: String, data := {}) -> void:
	# Input animation for movement
	pass
	
func physics_update(delta: float) -> void:
	var input_direction_x := Input.get_axis("move_left", "move_right")
	player.velocity.x = player.speed * input_direction_x
	player.sprite.flip_h = input_direction_x < 0
	player.velocity.y += player.gravity * delta
	player.move_and_slide()
	
	if not player.is_on_floor():
		finished.emit(FALLING)
	elif Input.is_action_pressed("jump"):
		finished.emit(JUMPING)
	elif is_equal_approx(input_direction_x, 0.0):
		finished.emit(IDLE)
