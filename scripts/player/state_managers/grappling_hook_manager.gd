class_name GrapplingHookManager extends Node2D

signal grapple_started
signal grapple_attached
signal grapple_released

# Grappling hook settings
@export var max_grapple_distance: float = 400.0
@export var hook_travel_speed: float = 800.0
@export var pull_speed: float = 1000.0
@export var collision_surface: String = "GRAPPLESURFACE"

# State
enum GrappleState { IDLE, TRAVELING, ATTACHED }
var current_state: GrappleState = GrappleState.IDLE

# Grapple data
var grapple_point: Vector2 = Vector2.ZERO
var hook_position: Vector2 = Vector2.ZERO
var rope_length: float = 0.0

# Collision layers
var collision_layers: Dictionary = {}

# Node references
@onready var raycast: RayCast2D = $GrappleRaycast
@onready var rope_line: Line2D = $GrappleLine
@onready var aim_line: Line2D = $GrappleAimLine
@onready var hook_sprite: Sprite2D = $HookSprite
@onready var player: CharacterBody2D = get_parent()

func _ready() -> void:
	_setup_visuals()
	_setup_collision_layers()

func _setup_visuals() -> void:
	rope_line.width = 2
	rope_line.default_color = Color.WHEAT
	rope_line.visible = false
	
	aim_line.width = 1
	aim_line.default_color = Color(1, 1, 1, 0.5)
	
	hook_sprite.visible = false

func _setup_collision_layers() -> void:
	for layer in range(1, 5):
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(layer))
		if layer_name:
			collision_layers[layer_name.to_upper()] = 1 << (layer - 1)
	
	# Use the scene's collision mask (6 = World + GrappleSurface layers)
	# Don't override the collision_mask set in the scene
	raycast.exclude_parent = true
	raycast.collide_with_areas = true

# Handle input for releasing grapple
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_attached():
		release_grapple()

func _physics_process(delta: float) -> void:
	_update_aim_line()
	_update_current_state(delta)
	_update_rope_visual()

func _update_aim_line() -> void:
	if current_state != GrappleState.IDLE:
		aim_line.visible = false
		return
	
	# Calculate direction to mouse
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Perform raycast
	raycast.global_position = global_position
	raycast.target_position = direction * max_grapple_distance
	raycast.force_raycast_update()
	
	var hit = raycast.is_colliding()
	
	# If raycast hits a valid surface, show green line; otherwise red
	if hit and _is_valid_surface(raycast.get_collider()):
		aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(raycast.get_collision_point())])
		aim_line.default_color = Color(0, 1, 0, 0.5)  # Green
	else:
		# Show red line to max distance
		aim_line.points = PackedVector2Array([Vector2.ZERO, direction * max_grapple_distance])
		aim_line.default_color = Color(1, 0, 0, 0.5)  # Red
	
	aim_line.visible = true

func _update_current_state(delta: float) -> void:
	match current_state:
		GrappleState.TRAVELING:
			_update_traveling_hook(delta)
		GrappleState.ATTACHED:
			_update_attached_grapple(delta)

func _update_traveling_hook(delta: float) -> void:
	var direction = (grapple_point - hook_position).normalized()
	var next_position = hook_position + direction * hook_travel_speed * delta
	
	# Check if hook has reached the grapple point (matching original logic)
	if next_position.distance_to(global_position) >= max_grapple_distance or next_position.distance_to(grapple_point) <= hook_travel_speed * delta:
		_attach_hook()
	else:
		hook_position += direction * hook_travel_speed * delta
		hook_sprite.global_position = hook_position

func _update_attached_grapple(_delta: float) -> void:
	var to_grapple = grapple_point - player.global_position
	var distance = to_grapple.length()
	
	hook_sprite.global_position = grapple_point
	
	print("DEBUG: Grappled - distance: ", distance, " velocity: ", to_grapple.normalized() * pull_speed)
	
	if distance > 20.0:
		player.velocity = to_grapple.normalized() * pull_speed
		# State machine will handle move_and_slide()
	else:
		print("DEBUG: Reached target, releasing grapple")
		player.velocity = Vector2.ZERO
		release_grapple()

func shoot_grapple() -> void:
	print("DEBUG: Attempting to shoot grapple, current_state: ", current_state)
	
	if current_state != GrappleState.IDLE:
		print("DEBUG: Cannot shoot - not in IDLE state")
		return
	
	# Get direction and distance to mouse (with raycast like original)
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Perform raycast to find valid target
	raycast.global_position = global_position
	raycast.target_position = direction * max_grapple_distance
	raycast.force_raycast_update()
	
	var hit = raycast.is_colliding()
	print("DEBUG: Raycast hit: ", hit)
	
	if hit:
		var hit_collider = raycast.get_collider()
		print("DEBUG: Hit collider: ", hit_collider)
		print("DEBUG: Valid surface: ", _is_valid_surface(hit_collider))
		
		if _is_valid_surface(hit_collider):
			var grapple_target = raycast.get_collision_point()
			print("DEBUG: Starting grapple to point: ", grapple_target)
			_start_grapple(grapple_target)
		else:
			print("DEBUG: Invalid surface")
	else:
		print("DEBUG: No collision detected")

func release_grapple() -> void:
	current_state = GrappleState.IDLE
	rope_line.visible = false
	hook_sprite.visible = false
	# Preserve some horizontal momentum but allow vertical fall
	player.velocity.x *= 0.8
	player.velocity.y = 0
	grapple_released.emit()

func _start_grapple(point: Vector2) -> void:
	print("DEBUG: Starting grapple - point: ", point, " hook_position: ", global_position)
	grapple_point = point
	hook_position = global_position
	current_state = GrappleState.TRAVELING
	hook_sprite.visible = true
	rope_line.visible = true
	grapple_started.emit()

func _attach_hook() -> void:
	print("DEBUG: Hook attached at: ", grapple_point)
	hook_position = grapple_point
	current_state = GrappleState.ATTACHED
	rope_length = player.global_position.distance_to(grapple_point)
	grapple_attached.emit()

func _is_valid_surface(collider) -> bool:
	# Check if collider is on World (layer 2) or GrappleSurface (layer 3)
	# collision_mask = 6 means we detect layers 2 and 3
	var world_layer = collision_layers.get("WORLD", 2)  # Layer 2
	var grapple_layer = collision_layers.get("GRAPPLESURFACE", 4)  # Layer 3
	return (collider.collision_layer & world_layer) != 0 or (collider.collision_layer & grapple_layer) != 0

func _update_rope_visual() -> void:
	if current_state in [GrappleState.TRAVELING, GrappleState.ATTACHED]:
		rope_line.points = PackedVector2Array([Vector2.ZERO, to_local(hook_sprite.global_position)])

# Public getters for state machine
func is_traveling() -> bool:
	return current_state == GrappleState.TRAVELING

func is_attached() -> bool:
	return current_state == GrappleState.ATTACHED

# Legacy API compatibility for state machine
func is_hook_traveling() -> bool:
	return is_traveling()

func is_hook_attached() -> bool:
	return is_attached()
