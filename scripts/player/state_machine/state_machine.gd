class_name StateMachine extends Node

## Initial state of the state machine. If not set, use first child node
@export var initial_state: State = null

## Current state of the state machine
@onready var state: State = (func get_initial_state() -> State:
	return initial_state if initial_state != null else get_child(0)
).call()
	
func _ready() -> void:
	# Give every state a reference to the state machine
	for state_node: State in find_children("*", "State"):
		state_node.finished.connect(_transition_to_next_state)
		
	# State machines usually access data form the root node of the scene they're part of: the owner
	# We wait for the owner to be ready to guarantee all the data and nodes the states may need are available.
	await owner.ready
	state.enter("")

func _transition_to_next_state(target_state_path: String, data: Dictionary = {}) -> void:
	print("Current state: " + target_state_path)
	if not has_node(target_state_path):
		printerr(owner.name + ": Trying to transition to state " + target_state_path + " but it doest not exist.")
		return
	
	var previous_state_path: String = state.name
	state.exit()
	state = get_node(target_state_path)
	state.enter(previous_state_path, data)
	
func _unhandled_input(event: InputEvent) -> void:
	state.handle_input(event)
	
func _process(delta: float) -> void:
	state.update(delta)
	
func _physics_process(delta: float) -> void:
	state.physics_update(delta)
