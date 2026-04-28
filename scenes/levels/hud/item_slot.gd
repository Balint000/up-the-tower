extends Control

signal used(item_id)

@onready var icon: TextureRect = $TextureRect
@onready var label: Label = $Label

var item_id: String = ""
var amount: int = 0
var usable: bool = true   # KeySlotnál false

func _ready():
	_update_visual()

# --- API --- #

func set_item(id: String, texture: Texture2D, count: int = 1):
	item_id = id
	icon.texture = texture
	amount = count
	visible = true
	_update_visual()

func clear():
	item_id = ""
	icon.texture = null
	amount = 0
	visible = false

func use():
	if not usable:
		return false

	if amount <= 0:
		return false

	amount -= 1
	emit_signal("used", item_id)

	if amount <= 0:
		clear()
	else:
		_update_visual()

	return true

# --- INTERNAL --- #

func _update_visual():
	if amount > 1:
		label.text = str(amount)
	else:
		label.text = "" 

## hasznalat 
#@onready var slot1 = $ItemSlots/HBoxContainer/Slot1
#@onready var slot2 = $ItemSlots/HBoxContainer/Slot2
#@onready var key_slot = $ItemSlots/HBoxContainer/KeySlot

#func _ready():
#	key_slot.usable = false

#func _input(event):
#	if event.is_action_pressed("slot_1"):
#		slot1.use()

#	if event.is_action_pressed("slot_2"):
#		slot2.use()

#slot1.set_item("potion", preload("res://potion.png"), 3)
#slot2.set_item("bomb", preload("res://bomb.png"), 1)
#key_slot.set_item("key", preload("res://key.png"), 1)
