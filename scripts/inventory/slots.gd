extends Panel

signal slot_clicked(item_id: String)

var item_id := ""
var is_equipped := false

@onready var icon = $SlotLayout/ItemIcon
@onready var item_name = $SlotLayout/Name
@onready var qty  = $SlotLayout/Quantity

func setup(item_data, id: String, count: int = 1) -> void:
	item_id = id

	if icon == null:
		push_error("Slot icon missing in scene!")
		return

	if item_data:
		if item_data.icon:
			icon.texture = item_data.icon

		if item_name:
			item_name.text = item_data.short_name if item_data.short_name != "" else item_data.name

	if qty:
		qty.text = str(count)

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(item_id)

func set_equipped(value: bool) -> void:
	is_equipped = value
	_update_visual()

func _update_visual():
	if is_equipped:
		modulate = Color(0.6, 1.0, 0.6)  # zöldes highlight
	else:
		modulate = Color(1, 1, 1)
