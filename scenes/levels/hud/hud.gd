extends Control

@onready var health_bar = $CanvasLayer/VBoxContainer/HealthBar
@onready var timer_bar = $CanvasLayer/VBoxContainer/TimerBar
@onready var slot1 = $CanvasLayer/ItemSlots/HBoxContainer/Slot1
@onready var slot2 = $CanvasLayer/ItemSlots/HBoxContainer/Slot2
@onready var key_slot = $CanvasLayer/ItemSlots/HBoxContainer/KeySlot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("hud")
	health_bar.set_max_health(GameManager.player_data[GameManager.KEY_HP])
	health_bar.set_health(GameManager.player_data[GameManager.KEY_HP])
	
	_init_slots()
	
	key_slot.usable = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func _init_slots() -> void:
	var apple = DataDb.get_item("apple")
	var beer = DataDb.get_item("beer")
	var key = DataDb.get_item("key")
	
	slot1.set_item(apple.id, apple.icon, GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"]["apple"])
	slot2.set_item(beer.id, beer.icon, GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"]["beer"])
	key_slot.set_item(key.id, key.icon, GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"]["key"])

func _on_button_2_pressed() -> void:
	health_bar.heal(10)

func _on_button_3_pressed() -> void:
	if timer_bar.running:
		return

	timer_bar.start_cooldown(5.0)

func _on_character_take_damage(amount) -> void:
	health_bar.take_damage(amount)
	
func _on_character_heal(amount, id) -> void:
	health_bar.heal(amount)
	match id:
		"apple":
			slot1.use()
		"beer":
			slot2.use()
		_:
			push_error("Invalid SLot")

func _on_character_ability_used(type, cd) -> void:
	cd = float(cd)

	match type:
		"fireball", "dash", "double_jump":
			if not timer_bar.state == timer_bar.State.CHARGING:
				timer_bar.start_cooldown(cd)

		"block":
			timer_bar.trigger_knight_block(6.0, cd)
			print("block")

		_:
			push_error("invalid player ability: " + str(type))
	
