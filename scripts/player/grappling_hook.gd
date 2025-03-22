#region Docstring
"""
Grappling_Hook.gd

The player can shoot a grappling hook towards a target, and if the hook collides with a valid surface, 
it pulls the player towards the target. Once the player reaches the target, the grapple is automatically released.

### Functions:
- `_init()`: Initializes collision layers based on project settings.
- `_ready()`: Configures visuals and initializes node references.
- `_process(delta)`: Handles input for releasing the grapple.
- `_physics_process(delta)`: Updates the grappling hook's state and visuals during physics updates.
- `shoot_grapple()`: Shoots the grappling hook towards the mouse pointer and checks for valid surfaces.
- `update_traveling_grapple(delta)`: Updates the hook's position while it is traveling towards the target.
- `handle_grappled_player_movement(delta)`: Pulls the player towards the grapple point and releases the grapple upon arrival.
- `release_grapple()`: Resets the grappling hook's state and hides visuals.
- `update_grapple_aim_line()`: Updates the visual aim line to indicate where the hook will travel.
- `update_grapple_line()`: Updates the visual line connecting the player and the hook.
- `get_grapple_distance_and_direction()`: Calculates the direction and distance to the mouse pointer.
- `activate_grapple_raycast(direction, distance)`: Fires a raycast to check for collisions along the grapple's path.
- `check_grapple_hit_valid_surface(hit_collider)`: Verifies if the grapple collided with a valid surface.

### Variables:
- `MAX_GRAPPLE_DISTANCE`: Maximum distance the grappling hook can travel.
- `HOOK_TRAVEL_SPEED`: Speed at which the hook travels.
- `PULL_SPEED`: Speed at which the player is pulled towards the grapple point.
- `COLLISION_SURFACE`: Name of the collision layer the hook can attach to.
- `LAYERS`: Dictionary mapping collision layer names to bit masks.
- `grapple_point_position`: Position of the grapple point where the hook attaches.
- `is_hook_traveling`: Whether the hook is currently traveling.
- `is_hook_attached`: Whether the hook is attached to a surface.
- `hook_position`: Current position of the hook while traveling.
- `grapple_rope_length`: Distance between the player and the grapple point.

This script is designed to be attached to a `Node2D` and assumes the presence of specific child nodes
(e.g., `RayCast2D`, `Line2D`, `Sprite2D`) for visuals and collision detection.
"""
#endregion

class_name GrapplingHook extends Node2D

# Grapple behavior settings
@export var MAX_GRAPPLE_DISTANCE := 400.0
@export var HOOK_TRAVEL_SPEED := 20.0
@export var PULL_SPEED := 1000.0
@export var COLLISION_SURFACE := "GRAPPLESURFACE"

# Grapple state variables
var grapple_point_position: Vector2 = Vector2.ZERO
var is_hook_traveling: bool = false
var is_hook_attached: bool = false
var hook_position: Vector2 = Vector2.ZERO
var grapple_rope_length: float = 0.0

const enable_debug = true

# Collision layers for 2D Physics
var LAYERS = {}

# Node references
@onready var grapple_raycast: RayCast2D = $GrappleRaycast
@onready var grapple_line: Line2D = $GrappleLine
@onready var grapple_aim_line: Line2D = $GrappleAimLine
@onready var hook_sprite: Sprite2D = $HookSprite
@onready var character: CharacterBody2D = get_parent()

func _init():
	# Initialize collision layers using project settings
	for layer in range(1, 5): # Layers 1-4
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(layer))
		if layer_name:
			LAYERS[layer_name.to_upper()] = 1 << (layer - 1)

func _ready():
	# Setup visuals for grapple line
	grapple_line.width = 2
	grapple_line.default_color = Color.WHEAT
	grapple_line.visible = false

	# Setup visuals for grapple aim line
	grapple_aim_line.width = 1
	grapple_aim_line.default_color = Color(1, 1, 1, 0.5)

	# Setup visuals for grapple hook sprite
	hook_sprite.visible = false

	# Configure raycast to detect specific surfaces
	grapple_raycast.collision_mask = LAYERS.get(COLLISION_SURFACE, 0) # Fallback to 0 if layer not found
	grapple_raycast.exclude_parent = true

# Process input from player
func _process(_delta: float):
	if Input.is_action_just_pressed("jump") and is_hook_attached:
		release_grapple()

# Physics-based updates for grapple mechanics
func _physics_process(_delta: float):
	update_grapple_aim_line()

	if is_hook_traveling:
		update_traveling_grapple(_delta)
	elif is_hook_attached:
		handle_grappled_player_movement(_delta)

	update_grapple_line()

# Update the aim line to follow the mouse position
func update_grapple_aim_line():
	# Don't show line if attached to surface or grapple is moving
	if is_hook_attached or is_hook_traveling:
		grapple_aim_line.visible = false
		return

	var grapple_direction = get_grapple_distance_and_direction().direction
	var grapple_distance = min(get_grapple_distance_and_direction().distance, MAX_GRAPPLE_DISTANCE)
	var raycast_result = activate_grapple_raycast(grapple_direction, grapple_distance)

	# If raycast hits an object, display green line. Else display red line
	if raycast_result.hit:
		# Green line when targeting valid surface
		grapple_aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(raycast_result.collision_point)])
		grapple_aim_line.default_color = Color(0, 1, 0, 0.5) # Green line
	else:
		# Red line when targeting invalid surface
		grapple_aim_line.points = PackedVector2Array([Vector2.ZERO, grapple_direction * grapple_distance])
		grapple_aim_line.default_color = Color(1, 0, 0, 0.5) # Red line

	grapple_aim_line.visible = true

# Update hook position while it's traveling
func update_traveling_grapple(delta: float):
	var direction = (grapple_point_position - hook_position).normalized()
	var next_position = hook_position + direction * HOOK_TRAVEL_SPEED * delta

	# Check if hook has reached the grapple point
	if next_position.distance_to(global_position) >= MAX_GRAPPLE_DISTANCE or next_position.distance_to(grapple_point_position) <= HOOK_TRAVEL_SPEED * delta:
		# Stop traveling and attach the hook
		hook_position = grapple_point_position
		is_hook_traveling = false
		is_hook_attached = true
		grapple_rope_length = character.global_position.distance_to(grapple_point_position)
		return

	hook_position += direction * HOOK_TRAVEL_SPEED * delta
	hook_sprite.global_position = hook_position

	if enable_debug:
		print("Direction: ", direction)
		print("Position: ", hook_position)

## Moves the grapple line towards the target
func handle_grappled_player_movement(_delta: float):
	# Distance between character and grapple
	var to_grapple = grapple_point_position - character.global_position
	var grapple_distance = to_grapple.length()

	# Update hook visual position
	hook_sprite.global_position = grapple_point_position

	if enable_debug:
		print("Grapple distance: ", grapple_distance)

	# Pull the player directly toward the grapple point
	if grapple_distance > 20.0: # Small threshold to stop jittering
		character.velocity = to_grapple.normalized() * PULL_SPEED
	else:
		# Stop pulling and release the grapple when the player reaches the grapple point
		character.velocity = Vector2.ZERO
		release_grapple()

	# Apply the velocity to the character
	character.move_and_slide()

# Shoot the grappling hook
func shoot_grapple():
	if is_hook_attached or is_hook_traveling:
		return

	# Set initial hook position
	hook_position = global_position

	# Get direction and distance to the mouse position
	var grapple_direction = get_grapple_distance_and_direction().direction
	var grapple_distance = min(get_grapple_distance_and_direction().distance, MAX_GRAPPLE_DISTANCE)

	# Activate raycast to check for a valid surface
	var raycast_result = activate_grapple_raycast(grapple_direction, grapple_distance)
	if raycast_result.hit and check_grapple_hit_valid_surface(grapple_raycast.get_collider()):
		# Set the grapple point position to the collision point
		grapple_point_position = raycast_result.collision_point

		# Begin hook travel
		is_hook_traveling = true
		hook_sprite.visible = true
		grapple_line.visible = true
	else:
		# Do nothing if no valid surface is detected
		return

# Get initial values for traveling grapple
func initiate_traveling_grapple():
	# Get direction and distance to the mouse position
	var grapple_direction = get_grapple_distance_and_direction().direction
	var grapple_distance = min(get_grapple_distance_and_direction().distance, MAX_GRAPPLE_DISTANCE)

	if enable_debug:
		print("Grapple direction: ", grapple_direction)
		print("Grapple distance: ", grapple_distance)

	# Default to traveling towards the max distance
	grapple_point_position = global_position + grapple_direction * grapple_distance

# Reset grapple state
func release_grapple():
	is_hook_attached = false
	is_hook_traveling = false
	grapple_line.visible = false
	hook_sprite.visible = false
	character.velocity *= 0.8

# Calculate the distance and direction for the grapple
func get_grapple_distance_and_direction() -> Dictionary:
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).normalized()

	grapple_raycast.global_position = global_position
	grapple_raycast.target_position = direction * MAX_GRAPPLE_DISTANCE
	grapple_raycast.force_raycast_update()

	var hit = grapple_raycast.is_colliding()
	var distance = MAX_GRAPPLE_DISTANCE

	if hit:
		var hit_collider = grapple_raycast.get_collider()
		if check_grapple_hit_valid_surface(hit_collider):
			distance = min(global_position.distance_to(grapple_raycast.get_collision_point()), MAX_GRAPPLE_DISTANCE)

	if enable_debug:
		print("Hit: ", hit)
		print("Distance: ", distance)
		print("")

	return {
		"direction": direction,
		"distance": distance,
	}

# Fire a raycast in the direction
func activate_grapple_raycast(direction: Vector2, distance: float) -> Dictionary:
	var hit = grapple_raycast.is_colliding()
	var collision_point = grapple_raycast.get_collision_point() if hit else global_position + direction * distance

	if enable_debug:
		print("Raycast Hit: ", hit)
		print("Collision object: ", collision_point)
		print("")

	return {
		"hit": hit,
		"collision_point": collision_point
	}

# Check if grapple contacts a valid surface to attach
func check_grapple_hit_valid_surface(hit_collider) -> bool:
	return hit_collider.collision_layer & LAYERS[COLLISION_SURFACE] != 0

# Update visuals of the grapple line
func update_grapple_line():
	if is_hook_attached or is_hook_traveling:
		grapple_line.points = PackedVector2Array([Vector2.ZERO, to_local(hook_sprite.global_position)])
