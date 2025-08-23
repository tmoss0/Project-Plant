class_name PlayerState extends State

const IDLE : String = "Idle"
const JUMPING : String = "Jumping"
const MOVING : String = "Moving"
const GRAPPLING : String = "Grappling"
const GRAPPLED : String = "Grappled"
const BURROWING : String = "Burrowing"
const FALLING : String = "Falling"

var player: Player

func _ready() -> void:
	await owner.ready
	player = owner as Player
	assert(player != null, "The PlayerState state type must be used only in the 
	player scene. It needs the owner to be a Player node")
