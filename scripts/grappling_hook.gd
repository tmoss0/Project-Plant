class_name GrapplingHook
extends Node2D

@export var MAX_GRAPPLE_DISTANCE = 400.0
@export var HOOK_TRAVEL_SPEED = 20.0
@export var PULL_SPEED = 1000.0
@export var SWING_SPEED = 500.0

var grapple_point: Vector2 = Vector2.ZERO
var is_grappling: bool = false
var is_hook_traveling: bool = false
var hook_position: Vector2 = Vector2.ZERO
var grapple_rope_length: float = 0.0

@onready var grapple_raycast: RayCast2D = $GrappleRaycast
@onready var grapple_line: Line2D = $GrappleLine
@onready var hook_sprite: Sprite2D = $HookSprite
@onready var aim_line: Line2D = $AimLine
@onready var character: CharacterBody2D = get_parent()

func _ready() -> void:
	# Setup grapple line
	grapple_line.width = 2
	grapple_line.default_color = Color.WHEAT
	grapple_line.visible = false
	
	# Setup aim line
	aim_line.width = 1
	aim_line.default_color = Color(1, 1, 1, 0.5)
	
	# Setup hook sprite
	hook_sprite.visible = false

func _process(_delta: float) -> void:
	update_aim_line()

func update_aim_line() -> void:
	if is_grappling or is_hook_traveling:
		aim_line.visible = false
		return

	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Update raycast for aiming
	grapple_raycast.target_position = direction * MAX_GRAPPLE_DISTANCE
	grapple_raycast.force_raycast_update()
	
	# Update aim line visualization
	if grapple_raycast.is_colliding():
		var hit_point = grapple_raycast.get_collision_point()
		aim_line.visible = true
		aim_line.points = PackedVector2Array([
			Vector2.ZERO,
			to_local(hit_point)
		])
		aim_line.default_color = Color.GREEN
	else:
		aim_line.visible = true
		aim_line.points = PackedVector2Array([
			Vector2.ZERO,
			to_local(global_position + direction * MAX_GRAPPLE_DISTANCE)
		])
		aim_line.default_color = Color.RED

func shoot_grapple() -> void:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	
	# Always start the hook traveling
	is_hook_traveling = true
	hook_position = global_position
	hook_sprite.visible = true
	grapple_line.visible = true
	
	# Raycast check for potential grapple point
	grapple_raycast.target_position = direction * MAX_GRAPPLE_DISTANCE
	grapple_raycast.force_raycast_update()
	
	if grapple_raycast.is_colliding():
		grapple_point = grapple_raycast.get_collision_point()
	else:
		grapple_point = global_position + (direction * MAX_GRAPPLE_DISTANCE)

func update_traveling_hook(delta: float) -> void:
	var direction = (grapple_point - hook_position).normalized()
	hook_position += direction * HOOK_TRAVEL_SPEED
	
	# Update hook sprite position
	hook_sprite.global_position = hook_position
	
	# Update rope while hook is traveling
	grapple_line.points = PackedVector2Array([
		Vector2.ZERO,
		to_local(hook_position)
	])
	
	# Check for collisions while traveling
	grapple_raycast.global_position = hook_position
	grapple_raycast.target_position = direction * HOOK_TRAVEL_SPEED
	grapple_raycast.force_raycast_update()
	
	if grapple_raycast.is_colliding():
		is_hook_traveling = false
		is_grappling = true
		grapple_point = grapple_raycast.get_collision_point()
		grapple_rope_length = character.global_position.distance_to(grapple_point)
	elif hook_position.distance_to(global_position) >= MAX_GRAPPLE_DISTANCE:
		release_grapple()

func handle_grapple_movement(delta: float) -> void:
	var to_grapple = grapple_point - character.global_position
	var distance = to_grapple.length()
	
	# Update hook sprite position
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
			var tangent = (grapple_point - character.global_position).rotated(PI/2).normalized()
			character.velocity = tangent * character.velocity.dot(tangent)

func release_grapple() -> void:
	is_grappling = false
	is_hook_traveling = false
	grapple_line.visible = false
	hook_sprite.visible = false
	character.velocity *= 0.8

func update_grapple_rope() -> void:
	if is_grappling or is_hook_traveling:
		grapple_line.points = PackedVector2Array([
			Vector2.ZERO,
			to_local(hook_sprite.global_position)
		])
