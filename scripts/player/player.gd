extends CharacterBody2D

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var grappling_hook = $GrapplingHook
@onready var burrow_state = $BurrowState

var abilites_unlocked = {
	"grappling": false,
	"climbing": false,
	"burrowing": false,
	"thorns": false
}

func _ready() -> void:
	burrow_state.burrow_started.connect(_on_burrow_started)
	burrow_state.burrow_ended.connect(_on_burrow_ended)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("grapple"):
		grappling_hook.shoot_grapple(delta)

	if grappling_hook.is_hook_traveling:
		grappling_hook.update_traveling_grapple(delta)
	elif grappling_hook.is_hook_attached:
		grappling_hook.handle_grappled_player_movement(delta)
	else:
		handle_normal_movement(delta)
	
	move_and_slide()
	update_animations()
	grappling_hook.update_grapple_line()

func handle_normal_movement(delta: float) -> void:
	# Add gravity (no gravity while burrowed)
	if not is_on_floor() and !burrow_state.is_burrowed:
		velocity.y += gravity * delta

	# Handle jump (disable while burrowed)
	if Input.is_action_just_pressed("jump") and !burrow_state.is_burrowed and (is_on_floor() or !coyote_timer.is_stopped()):
		velocity.y = JUMP_VELOCITY
		sprite.play("jump")
		coyote_timer.stop()
	
	# Handle horizontal movement
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = 0

	# Start coyote timer when leaving the ground
	if !burrow_state.is_burrowed and !is_on_floor() and was_on_floor():
		coyote_timer.start()

func update_animations() -> void:
	if burrow_state.is_burrowed:
		if sprite.sprite_frames.has_animation("burrow"):
			sprite.play("burrow")
		return
	
	if grappling_hook.is_hook_attached:
		if sprite.sprite_frames.has_animation("grapple"):
			sprite.play("grapple")
		return

	if !is_on_floor():
		if velocity.y < 0:
			if sprite.animation != "jump":
				sprite.play("jump")
		elif velocity.y > 0:
			if sprite.animation != "fall":
				sprite.play("fall")
	else:
		if velocity.x != 0:
			if sprite.animation != "idle":
				sprite.play("idle")
		else:
			if sprite.animation != "idle":
				sprite.play("idle")

func was_on_floor() -> bool:
	return get_last_slide_collision() != null and get_last_slide_collision().get_normal().y < -0.5

func _on_burrow_started() -> void:
	sprite.modulate.a = 0.5
	
func _on_burrow_ended() -> void:
	sprite.modulate.a = 1.0
