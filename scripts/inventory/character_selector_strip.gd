extends PanelContainer

signal character_selected(char_id: String)

@onready var _buttons := {
	"knight": $StripVBox/CharBtn_Knight,
	"mage": $StripVBox/CharBtn_Mage,
	"archer": $StripVBox/CharBtn_Archer,
	"thief": $StripVBox/CharBtn_Thief,
}

func _ready() -> void:
	for char_id in _buttons:
		_buttons[char_id].pressed.connect(func():
			character_selected.emit(char_id)
		)

func set_icons(data_db) -> void:
	for id in _buttons:
		var data = data_db.get_character(id)
		if data and data.portrait:
			_buttons[id].get_node("CharIcon_" + id.capitalize()).texture = data.portrait
