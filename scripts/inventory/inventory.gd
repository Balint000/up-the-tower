extends Control

@onready var character_strip = $MainMargin/MainHBox/CharacterSelectorStrip
@onready var stats = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/StatsContainer

@onready var helmet_btn = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/HelmetBtn
@onready var weapon_btn = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/WeaponBtn
@onready var boots_btn  = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/BootsBtn

@onready var char_select  = $MainMargin/MainHBox/CharacterSelectorStrip

@onready var selected_character_name  = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/CharacterName

@onready var grid = $MainMargin/MainHBox/InventoryPanel/InvVBox/InventoryGrid

@onready var back_btn = $MainMargin/MainHBox/BackButton

var selected_char := "knight"

var _dirty := false

var current_slot := "helmet"

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
	
	back_btn.pressed.connect(_on_back_pressed)

	_refresh_all()
	_set_filter("helmet")

# =========================
# CHARACTER
# =========================

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
	var eq = GameManager.runtime_data[GameManager.KEY_EQUIPPED_ITEMS]

	var category = _slot_to_category(current_slot)
	var equipped_items = _get_equipped().values()

	for item_id in inv.get(category, []):
		if item_id in equipped_items:
			continue  # 🔥 ne mutassa az equipped itemet

		var item = DataDb.get_item(item_id)
		if not item:
			continue

		var slot_scene = preload("res://scenes/inventory/Slots.tscn")
		var slot = slot_scene.instantiate()

		# highlight ha equipelt
		slot.set_equipped(eq[current_slot] == item_id)

		slot.slot_clicked.connect(func(id):
			_equip_item(id)
		)

		grid.add_child(slot)
		
				# ✅ csak item + id kell
		slot.setup(item, item_id)
		
# EQUIP LOGIC

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
	_rebuild_inventory() # 🔥 ez hiányzik nálad
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
	_refresh_character_name()
	_refresh_equipment()
	_refresh_stats()

func _refresh_equipment():

	var eq = _get_equipped()

	_set_btn(helmet_btn, "🪖", "Helmet", eq[GameManager.KEY_HELMET])
	_set_btn(weapon_btn, "⚔", "Weapon", eq[GameManager.KEY_WEAPON])
	_set_btn(boots_btn, "👢", "Boots", eq[GameManager.KEY_BOOTS])

func _set_btn(btn, icon, label, id):

	if id == "":
		btn.text = "%s %s — Empty —" % [icon, label]
		return

	var item = DataDb.get_item(id)
	if item:
		btn.text = "%s %s" % [icon, item.name]

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
