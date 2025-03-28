#region Docstring
"""
Burrowing.gd

The player can burrow into the ground, move while burrowed, and emerge after a set duration or upon player input. 
While burrowed, the player has reduced speed and cannot interact with certain objects.

### Functions:
- `_ready()`: Initializes references to the player's sprite and stores its initial position.
- `enter(previous_state_path, data)`: Called when entering the burrowing state; starts the burrow animation.
- `handle_input(event)`: Handles player input to cancel burrowing and start emerging.
- `physics_update(delta)`: Updates the player's movement and handles the burrowing timer and sliding effect.
- `handle_movement(delta)`: Handles horizontal movement and applies speed modifiers based on the burrowing state.
- `handle_animation(delta)`: Updates the burrowing/emerging animation based on the animation timer.
- `complete_animation()`: Completes the current animation and transitions the player to the appropriate state.
- `start_burrow()`: Starts the burrowing animation and emits the `burrow_started` signal.
- `complete_burrow()`: Marks the player as fully burrowed and disables collision layers.
- `start_emerge()`: Starts the emerging animation and transitions the player out of the burrowing state.
- `complete_emerge()`: Completes the emerging process, restores collision layers, and resets the player's state.
- `exit()`: Cleans up the burrowing state when transitioning to another state.
- `get_speed_modifier()`: Returns the speed multiplier based on whether the player is burrowed.

### Signals:
- `burrow_started`: Emitted when the burrowing animation starts.
- `burrow_ended`: Emitted when the burrowing process ends.

This script is designed to be used as part of a state machine for the player and assumes the presence
of an `AnimatedSprite2D` node for handling the player's sprite and animations.
"""
#endregion

extends PlayerState

signal burrow_started
signal burrow_ended

# Movement and duration parameters
@export var duration: float = 2.0
@export var speed_multiplier: float = 0.5
@export var burrow_speed: float = 200.0
@export var burrow_slide_depth: float = 10.0
@export var burrow_slide_speed: float = 5.0

# Animation parameters
@export var animation_duration: float = 0.5  # Time for both entering and exiting
@export var sprite_offset: float = 32.0  # Maximum distance sprite will move

# Velocity damping factors
@export var horizontal_damping: float = 0.2
@export var burrow_start_damping: float = 0.5

# Cooldown settings
@export var burrow_cooldown: float = 0.5

# Collision layer constants
const PLAYER_COLLISION_LAYER: int = 1

# State variables
var is_burrowed := false
var can_burrow := true
var burrow_timer := 0.0
var animation_timer := 0.0
var is_animating := false
var initial_sprite_position: Vector2

# Animation direction enum
enum AnimationDirection { IN, OUT }
var current_animation: AnimationDirection

# Node references
var sprite: AnimatedSprite2D

func _ready() -> void:
	await super._ready()
	sprite = player.get_node("AnimatedSprite2D") as AnimatedSprite2D
	assert(sprite != null, "AnimatedSprite2D node not found in Player")
	initial_sprite_position = sprite.position

func enter(_previous_state_path: String, _data := {}) -> void:
	start_burrow()

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("cancel_burrow") and is_burrowed:
		start_emerge()

func physics_update(delta: float) -> void:
	# Handle horizontal movement regardless of state
	handle_movement(delta)
	
	if is_animating:
		handle_animation(delta)
		return
			
	if not is_burrowed:
		finished.emit("Idle", {})
		return
			
	burrow_timer += delta
	
	# Apply burrow sliding effect if movingd d 
	if abs(player.velocity.x) > 0:
		var slide_amount = sin(burrow_timer * burrow_slide_speed) * burrow_slide_depth
		player.position.x += slide_amount * delta
	
	if burrow_timer >= duration:
		start_emerge()

func handle_movement(_delta: float) -> void:
	var direction := Input.get_axis("move_left", "move_right")
	
	# Calculate speed based on state
	var current_speed = player.speed * speed_multiplier if (is_burrowed or is_animating) else player.speed
	
	if direction:
		player.velocity.x = direction * current_speed
		
		# Flip the sprite based on movement direction
		sprite.flip_h = direction < 0
	else:
		# Smoother deceleration when stopping
		player.velocity.x = move_toward(player.velocity.x, 0, current_speed * horizontal_damping)
	
	# Apply vertical burrow speed when fully burrowed
	if is_burrowed:
		player.velocity.y = burrow_speed
	elif is_animating:
		# Gradual vertical speed transition during animation
		var progress = animation_timer / animation_duration
		var speed_factor = ease(progress if current_animation == AnimationDirection.IN else 1.0 - progress, 2.0)
		player.velocity.y = burrow_speed * speed_factor
	
	# Move the player
	player.move_and_slide()

func handle_animation(delta: float) -> void:
	animation_timer += delta
	var progress = animation_timer / animation_duration
	
	if progress >= 1.0:
		animation_timer = 0.0
		is_animating = false
		complete_animation()
		return
	
	# Calculate animation progress based on direction
	var t = ease(
		progress if current_animation == AnimationDirection.IN else 1.0 - progress, 
		2.0
	)
	sprite.position.y = initial_sprite_position.y + (sprite_offset * t)

func complete_animation() -> void:
	match current_animation:
		AnimationDirection.IN:
			complete_burrow()
		AnimationDirection.OUT:
			complete_emerge()

func start_burrow() -> void:
	if not can_burrow:
		return
				
	animation_timer = 0.0
	is_animating = true
	current_animation = AnimationDirection.IN
	burrow_started.emit()

func complete_burrow() -> void:
	is_burrowed = true
	burrow_timer = 0.0
	
	player.set_collision_layer_value(PLAYER_COLLISION_LAYER, false)
	player.set_collision_mask_value(PLAYER_COLLISION_LAYER, false)

func start_emerge() -> void:
	is_burrowed = false
	is_animating = true
	current_animation = AnimationDirection.OUT
	animation_timer = 0.0

func complete_emerge() -> void:
	burrow_timer = 0.0
	
	player.set_collision_layer_value(PLAYER_COLLISION_LAYER, true)
	player.set_collision_mask_value(PLAYER_COLLISION_LAYER, true)
	
	sprite.position = initial_sprite_position
	
	# Ensure the sprite retains the correct direction after burrowing ends
	sprite.flip_h = player.velocity.x < 0
	
	can_burrow = false
	get_tree().create_timer(burrow_cooldown).timeout.connect(func(): can_burrow = true)
	
	burrow_ended.emit()
	finished.emit("Idle", {})

func exit() -> void:
	if is_burrowed or is_animating:
		sprite.position = initial_sprite_position
		is_burrowed = false
		is_animating = false
		player.set_collision_layer_value(PLAYER_COLLISION_LAYER, true)
		player.set_collision_mask_value(PLAYER_COLLISION_LAYER, true)
		burrow_ended.emit()

func get_speed_modifier() -> float:
	return speed_multiplier if is_burrowed else 1.0