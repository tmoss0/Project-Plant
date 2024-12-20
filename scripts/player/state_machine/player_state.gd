#region Code Explanation
"""
Creates the player states are children to the parent of this file player_state.gd 
"""
#endregion

class_name PlayerState extends State

const IDLE = "Idle"
const JUMPING = "Jumping"
const MOVING = "Moving"
const GRAPPLING = "Grappling"
const BURROWING = "Burrowing"
const FALLING = "Falling"
const GRAPPLED = "Grappled"

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the 
	player scene It needs the owner to be a Player node")
