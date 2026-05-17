extends Panel

@onready var icon_rect = $SlotLayout/ItemIcon
@onready var name_label = $SlotLayout/Name
@onready var quantity_label = $SlotLayout/Quantity

func setup(item_id: String, amount: int):

	var item = DataDb.get_item(item_id)

	if not item:
		return

	icon_rect.texture = item.icon
	name_label.text = item.name
	quantity_label.text = "x%d" % amount
