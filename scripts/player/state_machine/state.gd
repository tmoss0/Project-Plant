## Base class for all the player states
class_name State extends Node

signal finished(next_state_path: String, data: Dictionary)

## Called by state machine when receiving unhandled input events
func handle_input(_event: InputEvent) -> void:
	pass
	
## Called by state machine on engine's main loop tick
func update(_delta: float) -> void:
	pass
	
## Called by state machine on engine's physics udpate tick
func physics_update(_delta: float) -> void:
	pass
	
## Called by state machine upon changing the active state. 
## Data parameter is a dict with arbitray data the state can 
## use to initialize itself
func enter(previous_state_path: String, data := {}) -> void:
	pass
	
## Called by state machine before changing the active state
func exit() -> void:
	pass
