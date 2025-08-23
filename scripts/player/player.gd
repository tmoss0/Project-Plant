class_name Player extends CharacterBody2D

@export var speed : float = 300.0
@export var jump_velocity : float = -400.0
@export var jump_cooldown : float = 0.3
@export var debug_mode : bool = false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var grappling_hook = $GrapplingHook
@onready var jump_cooldown_timer = $JumpCooldownTimer
