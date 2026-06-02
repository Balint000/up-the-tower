extends Control

@onready var health_bar = $CanvasLayer/VBoxContainer/HealthBar
@onready var timer_bar = $CanvasLayer/VBoxContainer/TimerBar
@onready var slot1 = $CanvasLayer/ItemSlots/HBoxContainer/Slot1
@onready var slot2 = $CanvasLayer/ItemSlots/HBoxContainer/Slot2
@onready var key_slot = $CanvasLayer/ItemSlots/HBoxContainer/KeySlot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("hud")
	key_slot.usable = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _on_button_2_pressed() -> void:
	health_bar.heal(10)

func _on_button_3_pressed() -> void:
	if timer_bar.running:
		return

	timer_bar.start_cooldown(5.0)

func _on_character_take_damage(amount) -> void:
	health_bar.take_damage(amount)
