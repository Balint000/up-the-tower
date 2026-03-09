extends Control

# Level select screen.
# Shows the 3 level buttons and disables any that are still locked.
# Relies on LevelManager (autoload) for unlock state and scene loading.

func _ready() -> void:
	# Disable buttons for levels the player hasn't unlocked yet.
	# LevelManager.is_unlocked(index) returns false until that level is beaten.
	$VBoxContainer/level1_btn.disabled = not LevelManager.is_unlocked(0)
	$VBoxContainer/level2_btn.disabled = not LevelManager.is_unlocked(1)
	$VBoxContainer/level3_btn.disabled = not LevelManager.is_unlocked(2)


func _on_level1_btn_pressed() -> void:
	LevelManager.load_level(0)


func _on_level2_btn_pressed() -> void:
	LevelManager.load_level(1)


func _on_level3_btn_pressed() -> void:
	LevelManager.load_level(2)


func _on_back_btn_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")
