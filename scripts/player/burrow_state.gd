class_name BurrowState
extends Node

signal burrow_started
signal burrow_ended

@export var duration: float = 2.0
@export var speed_multiplier: float = 0.5

var is_burrowed: bool = false
var burrow_timer: float = 0.0
var can_burrow: bool = true

# Reference to parent player node
var player: CharacterBody2D

func _ready() -> void:
	player = get_parent() as CharacterBody2D

func _physics_process(delta: float) -> void:
	if is_burrowed:
		burrow_timer += delta
		if burrow_timer >= duration:
			end_burrow()

	if Input.is_action_just_pressed("burrow") and player.abilites_unlocked["burrowing"] and can_burrow and !is_burrowed:
		start_burrow()

func start_burrow() -> void:
	is_burrowed = true
	burrow_timer = 0.0

	# Modify collision layers for burrowing
	player.set_collision_layer_value(1, false)
	player.set_collision_mask_value(1, false)

	# Stop vertical movement when starting burrow
	player.velocity.y = 0

	burrow_started.emit()

func end_burrow() -> void:
	is_burrowed = false
	burrow_timer = 0.0

	# Reset collision layers
	player.set_collision_layer_value(1, true)
	player.set_collision_mask_value(1, true)

	burrow_ended.emit()

func get_speed_modifier() -> float:
	return speed_multiplier if is_burrowed else 1.0
