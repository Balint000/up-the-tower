extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_back_btn_pressed() -> void:
	GameManager.go_to_mainmenu()


func _on_level_1_btn_pressed() -> void:
	LevelManager.load_level(0)
	print("Pressed")
