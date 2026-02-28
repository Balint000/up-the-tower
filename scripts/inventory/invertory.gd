extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func go_back():
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")


func _on_back_btn_pressed() -> void:
	go_back()
