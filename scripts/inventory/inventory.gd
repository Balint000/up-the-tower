extends Control

@onready var character_strip = $MainMargin/MainHBox/CharacterSelectorStrip
@onready var stats = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/StatsContainer

@onready var helmet_btn = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/HelmetBtn
@onready var weapon_btn = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/WeaponBtn
@onready var boots_btn  = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/BootsBtn

@onready var apple_slot = $MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/AppleSlot
@onready var beer_slot = $MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/BeerSlot
@onready var key_slot = $MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/KeySlot

@onready var char_select  = $MainMargin/MainHBox/CharacterSelectorStrip

@onready var bag_add  = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/BagADD

@onready var bag_btn = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/BagBtn

@onready var selected_character_name  = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/CharacterName

@onready var grid = $MainMargin/MainHBox/InventoryPanel/InvVBox/InventoryGrid

@onready var back_btn = $MainMargin/MainHBox/BackButton

var bag_overlay: Control = null

var selected_char := "knight"

var _dirty := false

var current_slot := "helmet"

var quickslots := {}

# =========================
# READY
# =========================

func _ready():

	character_strip.character_selected.connect(_on_character_selected)
	
	character_strip.set_icons(DataDb)
	
	selected_char = GameManager.runtime_data[GameManager.KEY_SELECTED_CHARACTER]

	helmet_btn.pressed.connect(func(): _on_equipment_btn_pressed(GameManager.KEY_HELMET))
	weapon_btn.pressed.connect(func(): _on_equipment_btn_pressed(GameManager.KEY_WEAPON))
	boots_btn.pressed.connect(func(): _on_equipment_btn_pressed(GameManager.KEY_BOOTS))
	
	bag_add.pressed.connect(_bag_add)
	back_btn.pressed.connect(_on_back_pressed)
	bag_btn.pressed.connect(_on_bag_open)
	
	quickslots = { 
		"apple": apple_slot, 
		"beer": beer_slot, 
		"key": key_slot 
	}
		
	_refresh_all()
	_set_filter("helmet")
	
	_init_bag_overlay()

# =========================
# CHARACTER
# =========================

func _init_bag_overlay() -> void:
	var bag_scene = preload("res://scenes/inventory/BagOpen.tscn")
	bag_overlay = bag_scene.instantiate()
	add_child(bag_overlay)
	
	bag_overlay.loot_taken.connect(_on_loot_taken)

func _on_bag_open() -> void:
	if not bag_overlay or bag_overlay._is_open: 
		return
	
	var bag_item_id := _find_openable_bag()
	
	if bag_item_id == "": 
		return
		
	var bag_item: ItemResource = DataDb.get_item(bag_item_id)
	
	if not bag_item: 
		return
	_consume_bag(bag_item_id) 
	bag_overlay.open(bag_item_id, bag_item.pool) 
	_refresh_inventory_ui() 
	_mark_dirty()

func _on_loot_taken() -> void:
	_refresh_quickslots()
	_refresh_bag_btn()
	_rebuild_inventory()
	_mark_dirty()

func _find_openable_bag() -> String:
	var cons = GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"] 
	for item_id in cons: 
		if cons[item_id] <= 0:
			continue 
			
		var item: ItemResource = DataDb.get_item(item_id) 
		if item and item.type == ItemResource.ItemType.BAG:
			return item_id
			
	return ""

func _consume_bag(item_id: String) -> void:
	var cons = GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"]
	if not cons.has(item_id):
		return 
	cons[item_id] -= 1
	
	if cons[item_id] <= 0: 
		cons[item_id] = 0

func _refresh_bag_btn() -> void:
	var bag_item_id := _find_openable_bag()
	var bag_count := _get_bag_count()
	
	if bag_item_id == "":
		bag_btn.text = "🎒 Bag — Empty —"
		bag_btn.disabled = true
		bag_btn.modulate.a = 0.5
		return
	
	var item: ItemResource = DataDb.get_item(bag_item_id)
	
	if item:
		bag_btn.text = "🎒 %s x%d" % [item.name, bag_count]
		bag_btn.icon = item.icon
	else:
		bag_btn.text = "🎒 Bag  x%d" % bag_count
	
	bag_btn.disabled = false
	bag_btn.modulate.a = 1.0

func _get_bag_count() -> int:
	var cons := GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"] as Dictionary
	var total := 0
	
	for item_id in cons:
		var item: ItemResource = DataDb.get_item(item_id)

		if item and item.type == ItemResource.ItemType.BAG:
			total += cons[item_id]

	return total
	
func _bag_add() -> void:
	var add_bag = 5
	GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"][GameManager.KEY_BAG] += add_bag 
	_refresh_all()

func _on_character_selected(id: String):
	selected_char = id
	GameManager.runtime_data[GameManager.KEY_SELECTED_CHARACTER] = id
	_refresh_all()
	_mark_dirty()

func _on_back_pressed():
	_save()
	GameManager.go_to_mainmenu()

func _get_equipped():
	return GameManager.runtime_data[GameManager.KEY_EQUIPPED_ITEMS]

func _mark_dirty():
	_dirty = true

# FILTER INVENTORY

func _set_filter(slot: String) -> void:
	current_slot = slot
	_rebuild_inventory()

func _refresh_character_name():
	selected_character_name.text = selected_char.to_upper()

func _rebuild_inventory():
	for c in grid.get_children():
		c.queue_free()

	var inv = GameManager.runtime_data[GameManager.KEY_INVENTORY]
	var eq = _get_equipped()
	var category = _slot_to_category(current_slot)
	var equipped_items = eq.values()
	
	for item_id in inv.get(category, []):
		if item_id in equipped_items:
			continue
		var item = DataDb.get_item(item_id)
		if not item:
			continue
		var slot = _create_inventory_slot(
			item, 
			item_id, 
			eq[current_slot] == item_id 
		)
		grid.add_child(slot)

func _create_inventory_slot( item, item_id: String, equipped: bool ) -> Control:
	var slot_scene = preload("res://scenes/inventory/Slots.tscn")
	var slot = slot_scene.instantiate()
	
	slot.setup(item, item_id)
	slot.set_equipped(equipped)
	
	slot.slot_clicked.connect(func(id):
		_equip_item(id) 
	)

	
	return slot

func _equip_item(item_id: String) -> void:
	var eq = GameManager.runtime_data[GameManager.KEY_EQUIPPED_ITEMS]

	# toggle logika
	if eq[current_slot] == item_id:
		eq[current_slot] = ""
	else:
		eq[current_slot] = item_id

	GameManager.runtime_data[GameManager.KEY_EQUIPPED_ITEMS] = eq

	_refresh_equipment()
	_refresh_stats()
	_rebuild_inventory() 
	_mark_dirty()

func _on_equipment_btn_pressed(slot: String) -> void:
	var eq = GameManager.runtime_data[GameManager.KEY_EQUIPPED_ITEMS]

	# ha van equipped item → unequip
	if eq[slot] != "":
		eq[slot] = ""
		GameManager.runtime_data[GameManager.KEY_EQUIPPED_ITEMS] = eq

		_refresh_equipment()
		_refresh_stats()
		_rebuild_inventory()
		_mark_dirty()

	# mindig filter váltás
	_set_filter(_slot_to_ui(slot))

# UI REFRESH

func _refresh_all():
	_refresh_character_ui()
	_refresh_inventory_ui()

func _refresh_inventory_ui():
	_refresh_quickslots()
	_refresh_bag_btn()
	_rebuild_inventory()

func _refresh_character_ui():
	_refresh_character_name()
	_refresh_equipment()
	_refresh_stats()

func _refresh_equipment():

	var eq = _get_equipped()

	_set_btn(helmet_btn, "🪖", "Helmet", eq[GameManager.KEY_HELMET])
	_set_btn(weapon_btn, "⚔", "Weapon", eq[GameManager.KEY_WEAPON])
	_set_btn(boots_btn, "👢", "Boots", eq[GameManager.KEY_BOOTS])

func _refresh_quickslots():
	var cons = GameManager.runtime_data[GameManager.KEY_INVENTORY]["cons"]
	for item_id in quickslots:
		quickslots[item_id].setup(
			item_id,
			cons.get(item_id, 0)
		)

func _set_btn( btn: Button, icon: String, label: String, item_id: String ) -> void:
	if item_id == "":
		btn.text = "%s %s — Empty —" % [icon, label]
		btn.icon = null
		return
	var item = DataDb.get_item(item_id)

	if item:
		btn.text = item.name
		btn.icon = item.icon

# =========================
# STATS
# =========================

func _refresh_stats():

	var stats_data = _calc_stats()
	stats.set_stats(stats_data)

func _calc_stats() -> Dictionary:

	var base = DataDb.get_character(selected_char)

	var hp = base.base_hp
	var dmg = base.base_dmg
	var spd = base.base_spd

	var eq = _get_equipped()

	for k in eq:
		var id = eq[k]
		if id == "":
			continue

		var item = DataDb.get_item(id)
		if item:
			hp += item.hp
			dmg += item.dmg
			spd += item.spd

	return {"hp": hp, "dmg": dmg, "spd": spd}

# =========================
# HELPERS
# =========================

func _slot_to_category(slot: String) -> String:
	match slot:
		"helmet": return "helm"
		"weapon": return "weap"
		"boots": return "boots"
	return ""

func _slot_to_ui(key: String) -> String:
	match key:
		GameManager.KEY_HELMET: return "helmet"
		GameManager.KEY_WEAPON: return "weapon"
		GameManager.KEY_BOOTS: return "boots"
	return "helmet"

func _save():
	if not _dirty:
		return
		
	GameManager.runtime_data[GameManager.KEY_SELECTED_CHARACTER] = selected_char
	GameManager.save_game()
	_dirty = false
