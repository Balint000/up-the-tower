@tool
extends EditorPlugin

var dock:EditorDock
func _enter_tree() -> void:
	dock = EditorDock.new()
	dock.name = "ToGoDot"
	dock.default_slot = EditorDock.DOCK_SLOT_BOTTOM
	var dockContent = preload("res://addons/ToGoDot/ToGoDot.tscn").instantiate()
	dock.add_child(dockContent)
	add_dock(dock)
	# Initialization of the plugin goes here.
	pass


func _exit_tree() -> void:
	remove_dock(dock)
	# Clean-up of the plugin goes here.
	pass
