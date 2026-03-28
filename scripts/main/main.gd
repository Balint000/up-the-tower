extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_btn_pressed() -> void:
	GameManager.go_to_levelmenu()

func _on_invertory_btn_pressed() -> void:
	GameManager.go_to_inventorymenu()

func _on_exit_btn_pressed() -> void:
	GameManager.quit_game()

func _on_demo_save_pressed() -> void:
	GameManager.save_game()

func _on_demo_load_pressed() -> void:
	GameManager.load_game()
	
	$VBoxContainer/Label.text = " Level: %s \n XP: %s \n Inventory: %s \n Kills: %s" % [
		GameManager.runtime_data[GameManager.KEY_LEVEL],
		GameManager.runtime_data[GameManager.KEY_XP],
		GameManager.runtime_data[GameManager.KEY_INVENTORY][0],
		GameManager.runtime_data[GameManager.KEY_STATISTICS][GameManager.KEY_KILLS]
	]
