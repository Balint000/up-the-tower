extends Panel

var icon: TextureRect
var item_name: Label

signal slot_clicked(item_id: String)

var item_id := ""
var is_equipped := false

func _ready():
	icon = get_node_or_null("SlotLayout/ItemIcon")
	item_name = get_node_or_null("SlotLayout/Name")

func setup(item_data, id: String) -> void:
	item_id = id
	
	if icon == null:
		icon = get_node_or_null("SlotLayout/ItemIcon")
	
	if item_name == null:
		item_name = get_node_or_null("SlotLayout/Name")
	
	if item_data == null:
		return

	icon.texture = item_data.icon
	item_name.text = item_data.short_name if item_data.short_name != "" else item_data.name

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed:
		slot_clicked.emit(item_id)

func set_equipped(value: bool) -> void:
	is_equipped = value
	_update_visual()

func _update_visual():
	modulate = Color(0.6, 1.0, 0.6) if is_equipped else Color.WHITE
