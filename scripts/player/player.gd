extends CharacterBody2D

@export var SPEED = 300.0
@export var JUMP_VELOCITY = -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var grappling_hook = $GrapplingHook

var abilites_unlocked = {
	"grappling": false,
	"climbing": false,
	"burrowing": false,
	"thorns": false
}

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("grapple"):
		grappling_hook.shoot_grapple()

	if grappling_hook.is_hook_traveling:
		grappling_hook.update_traveling_hook(delta)
	elif grappling_hook.is_hook_attached:
		grappling_hook.handle_grapple_movement(delta)
	else:
		handle_normal_movement(delta)
	
	move_and_slide()
	update_animations()
	grappling_hook.update_grapple_line()

func handle_normal_movement(delta: float) -> void:
	# Add gravity
	if not is_on_floor():
		velocity.y += gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and (is_on_floor() or !coyote_timer.is_stopped()):
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
	if !is_on_floor() and was_on_floor():
		coyote_timer.start()

func update_animations() -> void:
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
