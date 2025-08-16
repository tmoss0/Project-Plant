class_name GrapplingHookManager extends Node2D

signal grapple_started
signal grapple_attached
signal grapple_released

# Configuration
var config: PlayerConfig

# Grappling hook settings
@export var max_grapple_distance := 400.0
@export var hook_travel_speed := 400.0
@export var pull_speed := 1000.0

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
	config = PlayerConfig.new()
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
	
	raycast.collision_mask = collision_layers.get(config.collision_surface, 0)
	raycast.exclude_parent = true

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
	
	var target_data = _get_target_data()
	var raycast_result = _perform_raycast(target_data.direction, target_data.distance)
	
	aim_line.points = PackedVector2Array([Vector2.ZERO, to_local(raycast_result.point)])
	aim_line.default_color = Color.GREEN if raycast_result.hit else Color.RED
	aim_line.default_color.a = 0.5
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
	
	if _has_reached_target(next_position):
		_attach_hook()
	else:
		hook_position += direction * hook_travel_speed * delta
		hook_sprite.global_position = hook_position

func _update_attached_grapple(_delta: float) -> void:
	var to_grapple = grapple_point - player.global_position
	var distance = to_grapple.length()
	
	hook_sprite.global_position = grapple_point
	
	if distance > 20.0:
		player.velocity = to_grapple.normalized() * pull_speed
	else:
		player.velocity = Vector2.ZERO
		release_grapple()

func shoot_grapple() -> void:
	if current_state != GrappleState.IDLE:
		return
	
	var target_data = _get_target_data()
	var raycast_result = _perform_raycast(target_data.direction, target_data.distance)
	
	if raycast_result.hit and _is_valid_surface(raycast.get_collider()):
		_start_grapple(raycast_result.point)

func release_grapple() -> void:
	current_state = GrappleState.IDLE
	rope_line.visible = false
	hook_sprite.visible = false
	# Preserve some horizontal momentum but allow vertical fall
	player.velocity.x *= 0.8
	player.velocity.y = 0
	grapple_released.emit()

func _start_grapple(point: Vector2) -> void:
	grapple_point = point
	hook_position = global_position
	current_state = GrappleState.TRAVELING
	hook_sprite.visible = true
	rope_line.visible = true
	grapple_started.emit()

func _attach_hook() -> void:
	hook_position = grapple_point
	current_state = GrappleState.ATTACHED
	rope_length = player.global_position.distance_to(grapple_point)
	grapple_attached.emit()

func _get_target_data() -> Dictionary:
	var mouse_pos = get_global_mouse_position()
	var direction = (mouse_pos - global_position).normalized()
	var distance = min(global_position.distance_to(mouse_pos), max_grapple_distance)
	
	return { "direction": direction, "distance": distance }

func _perform_raycast(direction: Vector2, distance: float) -> Dictionary:
	raycast.global_position = global_position
	raycast.target_position = direction * distance
	raycast.force_raycast_update()
	
	var hit = raycast.is_colliding()
	var point = raycast.get_collision_point() if hit else global_position + direction * distance
	
	return { "hit": hit, "point": point }

func _is_valid_surface(collider) -> bool:
	return collider.collision_layer & collision_layers[config.collision_surface] != 0

func _has_reached_target(next_position: Vector2) -> bool:
	return (next_position.distance_to(global_position) >= max_grapple_distance or 
			next_position.distance_to(grapple_point) <= hook_travel_speed * 0.016)

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