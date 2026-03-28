@tool
extends BoxContainer

var data :Array= []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Load()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	pass




func _on_add_pressed() -> void:
	Add_Task()
	pass # Replace with function body.

func Add_Task():
	var task : CheckBox = CheckBox.new()
	var taskName :String = $VBoxContainer2/Task.text
	task.text = taskName
	task.pressed.connect(Clear)
	$VBoxContainer/Panel/Missions_List_Container/Missions_List.add_child(task)
	$VBoxContainer2/Task.clear()
	pass


func Clear() -> void:
	var tween = create_tween()
	var children = $VBoxContainer/Panel/Missions_List_Container/Missions_List.get_children()
	for child in children:
		if child.button_pressed == true:
			tween.tween_property(child,"modulate",Color(1.0, 1.0, 1.0, 0.0),0.3)
			await tween.finished
			child.queue_free()
		else:
			data.append(child.text)
	Save()
	data.clear()
	pass # Replace with function body.







func Save():
	var path = FileAccess.open("user://save.json",FileAccess.WRITE)
	var json = JSON.stringify(data)
	path.store_string(json)
	path.close()
	print(json)
	pass



func Load():
	if FileAccess.file_exists("user://save.json"):
		var path = FileAccess.open("user://save.json",FileAccess.READ)
		var stringfyData = path.get_as_text()
		path.close()
		var Data = JSON.parse_string(stringfyData)
		data = Data
		for CBox in data:
			var Mission = CheckBox.new()
			Mission.text = CBox
			$VBoxContainer/Panel/Missions_List_Container/Missions_List.add_child(Mission)
			Mission.pressed.connect(Clear)
			pass
		pass
func _on_save_pressed() -> void:
	var children = $VBoxContainer/Panel/Missions_List_Container/Missions_List.get_children()
	for child in children:
		data.append(child.text)
	Save()
	data.clear()
	pass # Replace with function body.


func _on_info_pressed() -> void:
	$Window.popup()
	pass # Replace with function body.


func _on_window_close_requested() -> void:
	$Window.hide()
	pass # Replace with function body.


func _on_misson_editing_toggled(toggled_on: bool) -> void:
	if toggled_on:
		if Input.is_action_just_pressed("ui_accept"):
			Add_Task()
			pass
	pass # Replace with function body.
