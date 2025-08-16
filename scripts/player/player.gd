class_name Player extends CharacterBody2D

@export var speed := 300.0
@export var jump_velocity := -400.0
@export var debug_mode := false
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite = $AnimatedSprite2D
@onready var coyote_timer = $CoyoteTimer
@onready var grappling_hook = $GrapplingHook
