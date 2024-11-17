class_name GrapplingHook
extends Node2D

@export var MAX_GRAPPLE_DISTANCE = 400.0
@export var HOOK_TRAVEL_SPEED = 20.0
@export var PULL_SPEED = 1000.0
@export var SWING_SPEED = 500.0
@export var COLLISION_SURFACE = "GRAPPLESURFACE"

var grapple_point: Vector2 = Vector2.ZERO
var is_hook_traveling: bool = false
var is_hook_attached: bool = false
var hook_position: Vector2 = Vector2.ZERO
var grapple_rope_length: float = 0.0

var LAYERS = {}

func _init() -> void:
	# Initialize layers using project settings
	for i in range(1, 5):  # Layers 1-4
		var layer_name = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i))
		if layer_name:
			LAYERS[layer_name.to_upper()] = 1 << (i - 1)

@onready var grapple_raycast: RayCast2D = $GrappleRaycast
@onready var grapple_line: Line2D = $GrappleLine
@onready var grapple_aim_line: Line2D = $GrappleAimLine
@onready var hook_sprite: Sprite2D = $HookSprite
@onready var character: CharacterBody2D = get_parent()

func _ready() -> void:
	# Setup grapple line
	grapple_line.width = 2
	grapple_line.default_color = Color.WHEAT
	grapple_line.visible = false
	
	# Setup grapple aim line
	grapple_aim_line.width = 1
	grapple_aim_line.default_color = Color(1, 1, 1, 0.5)
	
	# Setup grapple hook sprite
	hook_sprite.visible = false
	
	# Setup raycast for grapple surfaces only
	grapple_raycast.collision_mask = LAYERS.get(COLLISION_SURFACE, 0)  # Fallback to 0 if layer not found
	
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("jump") and is_hook_attached:
		release_grapple()

func _physics_process(_delta: float) -> void:
	update_grapple_aim_line()
	
	if is_hook_traveling:
		update_traveling_hook(_delta)
	elif is_hook_attached:
		handle_grapple_movement(_delta)
		
	update_grapple_line()

func update_grapple_aim_line() -> void:
	if is_hook_attached or is_hook_traveling:
		grapple_aim_line.visible = false
		return

	var grapple_data = get_grapple_distance_and_direction()
	var raycast_result = activate_grapple_raycast(grapple_data.direction, grapple_data.distance)
	
	if raycast_result.hit:
		grapple_aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(raycast_result.collision_point)])
		grapple_aim_line.default_color = Color(0, 1, 0, 0.5) # Green line
	else:
		grapple_aim_line.points = PackedVector2Array([Vector2.ZERO, grapple_data.direction * grapple_data.distance])
		grapple_aim_line.default_color = Color(1, 0, 0, 0.5) # Red line
		
	grapple_aim_line.visible = true
	
func activate_grapple_raycast(direction: Vector2, distance: float) -> Dictionary:
	var hit = grapple_raycast.is_colliding()
	var collision_point = grapple_raycast.get_collision_point() if hit else global_position + direction * distance
	
	return { 
		"hit": hit, 
		"collision_point": collision_point
	}

func get_grapple_raycast_position(direction: Vector2):
	grapple_raycast.global_position = global_position
	grapple_raycast.target_position = direction * MAX_GRAPPLE_DISTANCE
	grapple_raycast.force_raycast_update()

# Get the current position of the grappling hook
func update_traveling_hook(delta: float) -> void:
	var direction = (grapple_point - hook_position).normalized()
	hook_position += direction * HOOK_TRAVEL_SPEED * delta
	
	hook_sprite.global_position = hook_position
	
	if hook_position.distance_to(grapple_point) < HOOK_TRAVEL_SPEED * delta:
		is_hook_traveling = false
		is_hook_attached = true
		grapple_rope_length = character.global_position.distance_to(grapple_point)
	elif hook_position.distance_to(global_position) >= MAX_GRAPPLE_DISTANCE:
		release_grapple()

func handle_grapple_movement(delta: float) -> void:
	var to_grapple = grapple_point - character.global_position
	var distance = to_grapple.length()
	
	hook_sprite.global_position = grapple_point
	
	if Input.is_action_pressed("grapple_pull"):
		character.velocity = to_grapple.normalized() * PULL_SPEED
	else:
		var perpendicular = to_grapple.normalized().rotated(PI/2)
		var move_direction = Input.get_axis("move_left", "move_right")
		
		character.velocity += perpendicular * move_direction * SWING_SPEED * delta
		character.velocity += Vector2.DOWN * character.gravity * delta * 0.5
		
		if distance > grapple_rope_length:
			character.global_position = grapple_point - to_grapple.normalized() * grapple_rope_length
			var tangent = to_grapple.rotated(PI / 2).normalized()
			character.velocity = tangent * character.velocity.dot(tangent)

# Get the current grapple distance and direction
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

# Shoot grappling hook towards the grapple direction
func shoot_grapple() -> void:
	if is_hook_attached or is_hook_traveling:
		return
		
	var grapple_result = get_grapple_distance_and_direction()
	var direction = grapple_result.direction
	var distance = grapple_result.distance
	
	hook_position = global_position
	is_hook_traveling = true
	hook_sprite.visible = true
	grapple_line.visible = true
	
	get_grapple_raycast_position(direction)
	
	if grapple_raycast.is_colliding():
		var hit_collider = grapple_raycast.get_collider()
		if hit_collider.collision_layer & LAYERS[COLLISION_SURFACE] != 0:
			grapple_point = grapple_raycast.get_collision_point()
		else:
			release_grapple()
			return
	else:
		# If no valid surface is found, set grapple point to the max distance
		grapple_point = global_position + direction * distance
			
	is_hook_attached = false
	
# Release attached grapple 
func release_grapple() -> void:
	is_hook_attached = false
	is_hook_traveling = false
	grapple_line.visible = false
	hook_sprite.visible = false
	character.velocity *= 0.8

func update_grapple_line() -> void:
	if is_hook_attached or is_hook_traveling:
		grapple_line.points = PackedVector2Array([Vector2.ZERO, to_local(hook_sprite.global_position)])
