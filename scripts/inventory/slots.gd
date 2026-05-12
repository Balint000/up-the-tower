extends Panel

signal slot_clicked(item_id: String)

var item_id := ""
var is_equipped := false

@onready var icon: TextureRect = $SlotLayout/ItemIcon
@onready var item_name: Label = $SlotLayout/Name
@onready var qty: Label = $SlotLayout/Quantity

func setup(item_data, id: String, count: int = 1) -> void:
	item_id = id

	if item_data == null:
		return

	icon.texture = item_data.icon
	item_name.text = item_data.short_name if item_data.short_name != "" else item_data.name
	qty.text = str(count)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(item_id)

func set_equipped(value: bool) -> void:
	is_equipped = value
	_update_visual()

func _update_visual():
	modulate = Color(0.6, 1.0, 0.6) if is_equipped else Color.WHITE
