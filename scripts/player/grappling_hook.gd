class_name GrapplingHook
extends Node2D

# Grapple behavior settings
@export var MAX_GRAPPLE_DISTANCE = 400.0
@export var HOOK_TRAVEL_SPEED = 20.0
@export var PULL_SPEED = 1000.0
@export var SWING_SPEED = 500.0
@export var COLLISION_SURFACE = "GRAPPLESURFACE"

# Grapple state variables
var grapple_point_position: Vector2 = Vector2.ZERO
var is_hook_traveling: bool = false
var is_hook_attached: bool = false
var hook_position: Vector2 = Vector2.ZERO
var grapple_rope_length: float = 0.0

# Collision layers for 2D Physics
var LAYERS = {}

# Node references
@onready var grapple_raycast: RayCast2D = $GrappleRaycast
@onready var grapple_line: Line2D = $GrappleLine
@onready var grapple_aim_line: Line2D = $GrappleAimLine
@onready var hook_sprite: Sprite2D = $HookSprite
@onready var character: CharacterBody2D = get_parent()

func _init() -> void:
	# Initialize collision layers using project settings
	for i in range(1, 5):  # Layers 1-4
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i))
		if layer_name:
			LAYERS[layer_name.to_upper()] = 1 << (i - 1)


func _ready() -> void:
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
	grapple_raycast.collision_mask = LAYERS.get(COLLISION_SURFACE, 0)  # Fallback to 0 if layer not found
	grapple_raycast.exclude_parent = true

# Process input from player
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_hook_attached:
		release_grapple()

# Physics-based updates for grapple mechanices
func _physics_process(_delta: float) -> void:
	update_grapple_aim_line()

	if is_hook_traveling:
		update_traveling_hook(_delta)
	elif is_hook_attached:
		handle_grappled_player_movement(_delta)

	update_grapple_line()

# Update the aim line to follow the mouse position
func update_grapple_aim_line() -> void:
	# Don't show line if attached to surface or grapple is moving
	if is_hook_attached or is_hook_traveling:
		grapple_aim_line.visible = false
		return

	var grapple_data = get_grapple_distance_and_direction()
	var raycast_result = activate_grapple_raycast(grapple_data.direction, grapple_data.distance)

	# If raycast hits an object, display green line. Else display red line
	if raycast_result.hit:
		# Green line when targeting valid surface
		grapple_aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(raycast_result.collision_point)])
		grapple_aim_line.default_color = Color(0, 1, 0, 0.5) # Green line
	else:
		# Red line when targeting invalid surface
		grapple_aim_line.points = PackedVector2Array([Vector2.ZERO, grapple_data.direction * grapple_data.distance])
		grapple_aim_line.default_color = Color(1, 0, 0, 0.5) # Red line

	grapple_aim_line.visible = true

# Update hook position while it's traveling
func update_traveling_hook(delta: float) -> void:
	# Direction towards grappling hook
	var direction = (grapple_point_position - hook_position).normalized()
	hook_position += direction * HOOK_TRAVEL_SPEED * delta
	hook_sprite.global_position = hook_position

	grapple_raycast.global_position = hook_position
	grapple_raycast.force_raycast_update()

	if grapple_raycast.is_colliding():
		var hit_collider = grapple_raycast.get_collider()
		if hit_collider.collision_layer * LAYERS[COLLISION_SURFACE] != 0:
			# Gradually reduce the distance over time until hook reaches the point
			if hook_position.distance_to(grapple_point_position) > HOOK_TRAVEL_SPEED * delta:
				hook_position += direction * HOOK_TRAVEL_SPEED * delta
			# The hook has reached the point, therefore we are not moving
			else:
				hook_position = grapple_point_position
				is_hook_traveling = false
				is_hook_attached = true
				grapple_rope_length = character.global_position.distance_to(grapple_point_position)
		else: 
			release_grapple()
	elif hook_position.distance_to(global_position) >= MAX_GRAPPLE_DISTANCE:
		release_grapple()

# Moves the grapple line towards the target
func handle_grappled_player_movement(delta: float) -> void:
	# Distance between character and grapple
	var to_grapple = grapple_point_position - character.global_position
	var grapple_distance = to_grapple.length()
		# Update hook visual position
	hook_sprite.global_position = grapple_point_position

	if Input.is_action_pressed("grapple_pull"):
		character.velocity = to_grapple.normalized() * PULL_SPEED
	else:
		var perpendicular = to_grapple.normalized().rotated(PI/2)
		var move_direction = Input.get_axis("move_left", "move_right")

		character.velocity += perpendicular * move_direction * SWING_SPEED * delta
		character.velocity += Vector2.DOWN * character.gravity * delta * 0.5

		if grapple_distance > grapple_rope_length:
			character.global_position = character.global_position.lerp(grapple_point_position - to_grapple.normalized() * grapple_rope_length, delta * 10)
			var tangent = to_grapple.rotated(PI / 2).normalized()
			character.velocity = tangent * character.velocity.dot(tangent)

# Calculate the distance and direction for the grapple
func get_grapple_distance_and_direction() -> Dictionary:
	var mouse_position = get_global_mouse_position()
	var direction = (mouse_position - global_position).normalized()

	get_grapple_raycast_position(direction)

	var hit = grapple_raycast.is_colliding()
	var distance = MAX_GRAPPLE_DISTANCE
	var should_reset = false

	if hit:
		var hit_collider = grapple_raycast.get_collider()
		if hit_collider.collision_layer & LAYERS[COLLISION_SURFACE] != 0:
			distance = global_position.distance_to(grapple_raycast.get_collision_point())

	return {
		"direction": direction,
		"distance": distance,
	}

# Shoot the grappling hook
func shoot_grapple() -> void:
	if is_hook_attached or is_hook_traveling:
		return

	var grapple_data = get_grapple_distance_and_direction()
	var raycast_result = activate_grapple_raycast(grapple_data.direction, grapple_data.distance)

	# Only start traveling if we hit a valid surface or are within the max distance
	if raycast_result.hit:
		var hit_collider = grapple_raycast.get_collider()
		if hit_collider and hit_collider.collision_layer & LAYERS[COLLISION_SURFACE] != 0:
			hook_position = global_position
			is_hook_traveling = true
			hook_sprite.visible =  true
			grapple_line.visible = true
			grapple_point_position = raycast_result.collision_point
		else:
			return
	else:
		return

# Reset grapple state
func release_grapple() -> void:
	is_hook_attached = false
	is_hook_traveling = false
	grapple_line.visible = false
	hook_sprite.visible = false
	character.velocity *= 0.8

# Update the raycast for detecting targets
func get_grapple_raycast_position(direction: Vector2):
	#print("Raycast Position:", grapple_raycast.global_position)
	#print("Raycast Target Position:", grapple_raycast.target_position)

	grapple_raycast.global_position = global_position
	grapple_raycast.target_position = direction * MAX_GRAPPLE_DISTANCE
	grapple_raycast.force_raycast_update()

# Fire a raycast in the direction
func activate_grapple_raycast(direction: Vector2, distance: float) -> Dictionary:
	var hit = grapple_raycast.is_colliding()
	var collision_point = grapple_raycast.get_collision_point() if hit else global_position + direction * distance

	#print("Hit:", hit)
	#print("Collision object: ", collision_point)

	return {
		"hit": hit,
		"collision_point": collision_point
	}

# Update visuals of teh grapple line
func update_grapple_line() -> void:
	if is_hook_attached or is_hook_traveling:
		grapple_line.points = PackedVector2Array([Vector2.ZERO, to_local(hook_sprite.global_position)])
