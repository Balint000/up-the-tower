extends Node
class_name LevelManager

## Levels of the game (set in the editor)
@export var levels: Array[PackedScene] = []

## Index of the currently loaded level (0 = first level)
var current_level_index: int = 0

## Reference to the currently loaded level node
var current_level: Node = null


func _ready() -> void:
	# Do NOT auto-load a level here,
	# because the main menu should appear first.
	# Levels will be loaded from main menu / level select.
	pass


## Load a specific level by index
func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("LevelManager: Invalid level index: %d" % index)
		return
	
	# Remove current level if it exists
	if current_level != null:
		current_level.queue_free()
		await current_level.tree_exited
	
	var scene: PackedScene = levels[index]
	var instance: Node = scene.instantiate()
	
	add_child(instance)
	
	current_level = instance
	current_level_index = index
	
	print("LevelManager: Loaded level index =", index)


## Load the next level in sequence
func load_next_level() -> void:
	var next_index := current_level_index + 1
	load_level(next_index)


## Reload the current level (useful for restart)
func reload_current_level() -> void:
	load_level(current_level_index)
