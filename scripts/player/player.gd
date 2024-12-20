extends CharacterBody2D

@export var SPEED := 300.0
@export var JUMP_VELOCITY := -400.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var grappling_hook = $GrapplingHook
@onready var burrow_state = $BurrowState

var abilites_unlocked = {
	"grappling": true,
	"climbing": true,
	"burrowing": true,
	"thorns": true
}

func _physics_process(delta: float) -> void:
	# Grappling hook handlers
	if Input.is_action_just_pressed("grapple") and abilites_unlocked["grappling"] and !burrow_state.is_burrowed:
		grappling_hook.shoot_grapple(delta)
	if grappling_hook.is_hook_traveling:
		grappling_hook.update_traveling_grapple(delta)
	elif grappling_hook.is_hook_attached:
		grappling_hook.handle_grappled_player_movement(delta)
	else:
		handle_normal_movement(delta)
		
	# Burrow handling
	if Input.is_action_just_pressed("burrow") and abilites_unlocked["burrowing"] and burrow_state.can_burrow and !burrow_state.is_burrowed and !grappling_hook.is_hook_attached and !grappling_hook.is_hook_traveling:
		burrow_state.start_burrow()
		grappling_hook.release_grapple()
	
	move_and_slide()
	update_animations()
	grappling_hook.update_grapple_line()

func handle_normal_movement(delta: float) -> void:
	# Add gravity (no gravity while burrowed)
	if not is_on_floor() and !burrow_state.is_burrowed:
		velocity.y += gravity * delta

	# Handle jump (disable while burrowed)
	if Input.is_action_just_pressed("jump") and !burrow_state.is_burrowed:
		if is_on_floor() or !coyote_timer.is_stopped():
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
	# Burrow animations
	if burrow_state.is_burrowed:
		if sprite.sprite_frames.has_animation("burrow"):
			if sprite.animation != "burrow":
				sprite.play("burrow")
		else:
			sprite.position.y = lerp(sprite.position.y, burrow_state.burrow_slide_depth, burrow_state.burrow_slide_speed * get_physics_process_delta_time())
	else:
		sprite.position.y = lerp(sprite.position.y, 0.0, burrow_state.burrow_slide_speed * get_physics_process_delta_time())
	
	# Grapple animations
	if grappling_hook.is_hook_attached:
		if sprite.sprite_frames.has_animation("grapple"):
			sprite.play("grapple")
		return

	# Jumping and falling animations
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
