extends Node2D
class_name LeverPuzzleController

@export var lever_paths: Array[NodePath] = []
@export var trap_paths: Array[NodePath] = []
@export var target_pattern: Array[bool] = [true, false, true]

var _states: Array[bool] = []


func _ready() -> void:
	# Levelek
	for i in range(lever_paths.size()):
		var lever_node = get_node_or_null(lever_paths[i])
		# Nem feltételezzük, hogy tényleg Lever típus – csak legyen rajta is_on + signal
		if lever_node == null:
			push_warning("LeverPuzzleController: missing lever at index %d" % i)
			_states.append(false)
			continue

		_states.append(lever_node.is_on if "is_on" in lever_node else false)

		if lever_node.has_signal("lever_switched"):
			lever_node.lever_switched.connect(_on_lever_switched.bind(i))
		else:
			push_warning("LeverPuzzleController: lever at index %d has no 'lever_switched' signal" % i)

	_update_traps()


func _on_lever_switched(on: bool, index: int) -> void:
	if index < 0 or index >= _states.size():
		return
	_states[index] = on
	_update_traps()


func _update_traps() -> void:
	var correct := true

	if target_pattern.size() != _states.size():
		correct = false
	else:
		for i in range(_states.size()):
			if _states[i] != target_pattern[i]:
				correct = false
				break

	for path in trap_paths:
		var trap_node = get_node_or_null(path)
		if trap_node == null:
			continue

		if trap_node.has_method("set_enabled"):
			if correct:
				print("CORRECT")
				trap_node.set_enabled(false)   # jó kombináció -> kikapcsol (és halványul a saját scriptjétől)
			else:
				trap_node.set_enabled(true)    # rossz kombináció -> bekapcsolva
		else:
			push_warning("LeverPuzzleController: node at %s has no set_enabled()" % path)
