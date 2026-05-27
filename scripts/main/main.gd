extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_btn_play_pressed() -> void:
	GameManager.go_to_levelmenu()

func _on_btn_inventory_pressed() -> void:
	GameManager.go_to_inventorymenu()

func _on_btn_quit_pressed() -> void:
	GameManager.quit_game()
