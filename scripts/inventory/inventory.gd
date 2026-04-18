extends Control

# =============================================================================
#  UI REFERENCES
# =============================================================================
@onready var _char_name_lbl : Label = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/CharacterName
@onready var _hp_value      : Label = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/StatsContainer/Stat_HP/HpValue
@onready var _dmg_value     : Label = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/StatsContainer/Stat_Damage/DmgValue
@onready var _spd_value     : Label = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/StatsContainer/Stat_Speed/SpdValue

@onready var _char_sprite   : TextureRect = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/CharacterGraphicPanel/CharacterSprite

@onready var _char_btns := {
	"knight": $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Knight,
	"mage":   $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Mage,
	"archer": $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Archer,
	"thief":  $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Thief,
}

@onready var _char_icons := {
	"knight": $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Knight/CharIcon_Knight,
	"mage":   $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Mage/CharIcon_Mage,
	"archer": $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Archer/CharIcon_Archer,
	"thief":  $MainMargin/MainHBox/CharacterSelectorStrip/StripVBox/CharBtn_Thief/CharIcon_Thief,
}

@onready var _helmet_btn : Button = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/HelmetSlot/HelmetBtn
@onready var _weapon_btn : Button = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/WeaponSlot/WeaponBtn
@onready var _boots_btn  : Button = $MainMargin/MainHBox/CharInfoPanel/InfoVBox/DisplayRow/EquipmentSlots/BootsSlot/BootsBtn

@onready var _inv_grid : GridContainer = $MainMargin/MainHBox/InventoryPanel/InvVBox/InventoryGrid

@onready var _quick_slots := [
	$MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/QuickSlot_1,
	$MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/QuickSlot_2,
	$MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/QuickSlot_3,
]

@onready var _quick_icons := [
	$MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/QuickSlot_1/QSIcon_1,
	$MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/QuickSlot_2/QSIcon_2,
	$MainMargin/MainHBox/InventoryPanel/InvVBox/QuickSlotsArea/QuickSlotsRow/QuickSlot_3/QSIcon_3,
]

# Popup overlay references
@onready var _equip_overlay : Control = $EquipDropdownOverlay
@onready var _equip_panel   : Panel   = $EquipDropdownOverlay/EquipPanel
@onready var _equip_title   : Label   = $EquipDropdownOverlay/EquipPanel/Margin/VBox/Title
@onready var _equip_list    : VBoxContainer = $EquipDropdownOverlay/EquipPanel/Margin/VBox/ItemList

@onready var _picker_overlay = $QuickSlotPickerOverlay
@onready var _picker_grid    = $QuickSlotPickerOverlay/PickerPanel/PickerMargin/PickerVBox/PickerGrid

# =============================================================================
#  CONSTANTS
# =============================================================================
const GRID_SLOT_ITEMS := {
	"Slot_Apple":           "apple",
	"Slot_Beer":            "beer",
	"Slot_Cake":            "cake",
	"Slot_HealingPotion":   "heal_potion",
	"Slot_SwiftnessPotion": "swift_potion",
	"Slot_Key":             "key",
	"Slot_HelmetBag":       "helm_bag",
	"Slot_WeaponBag":       "wpn_bag",
	"Slot_BootsBag":        "boot_bag",
}

const PICKER_ITEM_MAP := {
	"PickerItem_Apple":           "apple",
	"PickerItem_Beer":            "beer",
	"PickerItem_Cake":            "cake",
	"PickerItem_HealingPotion":   "heal_potion",
	"PickerItem_SwiftnessPotion": "swift_potion",
	"PickerItem_Key":             "key",
}

# =============================================================================
#  STATE
# =============================================================================
var _selected_char := "knight"
var _equipped := {"helmet": "", "weapon": "", "boots": ""}
var _quick_data := ["", "", ""]
var _pending_slot := ""  # Which equipment slot we're selecting for
var _pending_qs := -1    # Which quick slot we're assigning

# =============================================================================
#  READY
# =============================================================================
func _ready() -> void:
	_load_from_manager()
	_connect_signals()
	_refresh_ui()
	
	# Debug: print inventory status
	_debug_print_inventory()

func _debug_print_inventory() -> void:
	print("=== INVENTORY DEBUG ===")
	var inv = _get_inventory()
	print("Inventory: ", inv)
	print("Equipped: ", _equipped)
	print("======================")

# =============================================================================
#  INVENTORY HELPERS
# =============================================================================
func _get_inventory() -> Dictionary:
	return GameManager.runtime_data.get(GameManager.KEY_INVENTORY, {})

func _has_item(item_id: String) -> bool:
	var inv = _get_inventory()
	var cat = _get_item_category(item_id)
	if cat == "cons":
		return inv.get("cons", {}).get(item_id, 0) > 0
	return inv.get(cat, []).has(item_id)

func _get_item_count(item_id: String) -> int:
	var inv = _get_inventory()
	var cat = _get_item_category(item_id)
	if cat == "cons":
		return inv.get("cons", {}).get(item_id, 0)
	return 1 if inv.get(cat, []).has(item_id) else 0

func _add_item(item_id: String, amount: int = 1) -> void:
	var inv = _get_inventory()
	var cat = _get_item_category(item_id)
	
	if cat == "cons":
		if not inv.has("cons"):
			inv["cons"] = {}
		inv["cons"][item_id] = inv["cons"].get(item_id, 0) + amount
	else:
		if not inv.has(cat):
			inv[cat] = []
		if not inv[cat].has(item_id):
			inv[cat].append(item_id)
	
	GameManager.runtime_data[GameManager.KEY_INVENTORY] = inv

func _remove_item(item_id: String) -> bool:
	var inv = _get_inventory()
	var cat = _get_item_category(item_id)
	
	if cat == "cons":
		if not inv.get("cons", {}).has(item_id):
			return false
		inv["cons"][item_id] -= 1
		if inv["cons"][item_id] <= 0:
			inv["cons"].erase(item_id)
		GameManager.runtime_data[GameManager.KEY_INVENTORY] = inv
		return true
	else:
		if inv.get(cat, []).has(item_id):
			inv[cat].erase(item_id)
			GameManager.runtime_data[GameManager.KEY_INVENTORY] = inv
			return true
	return false

func _get_item_category(item_id: String) -> String:
	var item = DataDb.get_item(item_id)
	if item == null:
		return "cons"
	match item.slot:
		ItemData.EquipSlot.HELMET: return "helm"
		ItemData.EquipSlot.WEAPON: return "weap"
		ItemData.EquipSlot.BOOTS: return "boots"
		_: return "cons"

# =============================================================================
#  LOAD / SAVE
# =============================================================================
func _load_from_manager() -> void:
	var rd = GameManager.runtime_data
	
	_selected_char = rd.get(GameManager.KEY_SELECTED_CHARACTER, "knight")
	_equipped = rd.get(GameManager.KEY_EQUIPPED_ITEMS, {"helmet": "", "weapon": "", "boots": ""}).duplicate(true)
	_quick_data = rd.get("quick_slots", ["", "", ""]).duplicate(true)
	
	# Ensure equipped has correct keys
	if not _equipped.has("helmet"):
		_equipped["helmet"] = ""
	if not _equipped.has("weapon"):
		_equipped["weapon"] = ""
	if not _equipped.has("boots"):
		_equipped["boots"] = ""

func _save_to_manager() -> void:
	var rd = GameManager.runtime_data
	rd[GameManager.KEY_SELECTED_CHARACTER] = _selected_char
	rd[GameManager.KEY_EQUIPPED_ITEMS] = _equipped.duplicate(true)
	rd["quick_slots"] = _quick_data.duplicate(true)
	
	# Update player stats
	var stats = _calculate_stats()
	GameManager.player_data[GameManager.KEY_HP] = stats.hp
	GameManager.player_data[GameManager.KEY_DMG] = stats.dmg
	GameManager.player_data[GameManager.KEY_SPEED] = stats.spd
	
	# Save to file
	GameManager.save_game()

# =============================================================================
#  SIGNAL CONNECTIONS
# =============================================================================
func _connect_signals() -> void:
	# Character selection buttons
	for char_id in _char_btns:
		_char_btns[char_id].pressed.connect(_on_character_selected.bind(char_id))
	
	# Equipment buttons
	_helmet_btn.pressed.connect(_on_equipment_button_pressed.bind("helmet"))
	_weapon_btn.pressed.connect(_on_equipment_button_pressed.bind("weapon"))
	_boots_btn.pressed.connect(_on_equipment_button_pressed.bind("boots"))
	
	# Inventory grid slots
	for slot_name in GRID_SLOT_ITEMS:
		var slot_node = _inv_grid.get_node_or_null(slot_name)
		if slot_node:
			slot_node.gui_input.connect(_on_inventory_slot_input.bind(GRID_SLOT_ITEMS[slot_name]))
	
	# Quick slots
	for i in 3:
		_quick_slots[i].gui_input.connect(_on_quick_slot_input.bind(i))
	
	# Picker overlay items
	for picker_name in PICKER_ITEM_MAP:
		var picker_node = _picker_grid.get_node_or_null(picker_name)
		if picker_node:
			picker_node.gui_input.connect(_on_picker_item_input.bind(PICKER_ITEM_MAP[picker_name]))
	
	# Overlay close buttons
	var picker_close = _picker_overlay.get_node_or_null("PickerPanel/PickerMargin/PickerVBox/PickerCloseBtn")
	if picker_close:
		picker_close.pressed.connect(_close_picker_overlay)
	
	var picker_clear = _picker_overlay.get_node_or_null("PickerPanel/PickerMargin/PickerVBox/PickerClearBtn")
	if picker_clear:
		picker_clear.pressed.connect(_clear_pending_quick_slot)
	
	# Equip overlay close
	var equip_close = _equip_overlay.get_node_or_null("EquipPanel/Margin/VBox/CloseBtn")
	if equip_close:
		equip_close.pressed.connect(_close_equip_overlay)
	
	# Click outside to close overlays - need to connect to the dimmer
	var equip_dimmer = _equip_overlay.get_node_or_null("OverlayDimmer")
	if equip_dimmer:
		equip_dimmer.gui_input.connect(_on_overlay_background_click)
	
	var picker_dimmer = _picker_overlay.get_node_or_null("OverlayDimmer")
	if picker_dimmer:
		picker_dimmer.gui_input.connect(_on_picker_overlay_background_click)

# =============================================================================
#  UI REFRESH
# =============================================================================
func _refresh_ui() -> void:
	_refresh_character_display()
	_refresh_stats()
	_refresh_equipment_buttons()
	_refresh_inventory_grid()
	_refresh_quick_slots()

func _refresh_character_display() -> void:
	var char_data = DataDb.get_character(_selected_char)
	if char_data:
		_char_name_lbl.text = char_data.display_name.to_upper()
		if char_data.icon:
			_char_sprite.texture = char_data.icon
		
		# Update character selector icons
		for char_id in _char_icons:
			var c_data = DataDb.get_character(char_id)
			if c_data and c_data.icon:
				_char_icons[char_id].texture = c_data.icon

func _refresh_stats() -> void:
	var stats = _calculate_stats()
	_hp_value.text = str(stats.hp)
	_dmg_value.text = str(stats.dmg)
	_spd_value.text = str(stats.spd)

func _refresh_equipment_buttons() -> void:
	_update_equipment_button(_helmet_btn, "🪖", "Helmet", _equipped.get("helmet", ""))
	_update_equipment_button(_weapon_btn, "⚔", "Weapon", _equipped.get("weapon", ""))
	_update_equipment_button(_boots_btn, "👢", "Boots", _equipped.get("boots", ""))

func _update_equipment_button(btn: Button, icon: String, label: String, item_id: String) -> void:
	if item_id.is_empty():
		btn.text = "%s   %s     — Empty —" % [icon, label]
	else:
		var item = DataDb.get_item(item_id)
		if item:
			btn.text = "%s   %s   %s [%s]" % [icon, label, item.name, item.rarity]
		else:
			btn.text = "%s   %s     — Unknown —" % [icon, label]

func _refresh_inventory_grid() -> void:
	var inv = _get_inventory()
	
	for slot_name in GRID_SLOT_ITEMS:
		var item_id = GRID_SLOT_ITEMS[slot_name]
		var slot_node = _inv_grid.get_node_or_null(slot_name)
		if not slot_node:
			continue
		
		var count_label = slot_node.get_node_or_null("SlotLayout/ItemCount")
		var icon_rect = slot_node.get_node_or_null("SlotLayout/ItemIcon")
		var name_label = slot_node.get_node_or_null("SlotLayout/ItemName")
		
		var count = _get_item_count(item_id)
		if count_label:
			count_label.text = str(count)
		
		var item_data = DataDb.get_item(item_id)
		if item_data:
			if name_label:
				name_label.text = item_data.short_name if item_data.short_name else item_data.name
			if icon_rect and item_data.icon:
				icon_rect.texture = item_data.icon

func _refresh_quick_slots() -> void:
	for i in 3:
		var icon_rect = _quick_icons[i]
		if icon_rect:
			if _quick_data[i].is_empty():
				icon_rect.texture = null
			else:
				var item = DataDb.get_item(_quick_data[i])
				if item and item.icon:
					icon_rect.texture = item.icon
				else:
					icon_rect.texture = null

# =============================================================================
#  STATS CALCULATION
# =============================================================================
func _calculate_stats() -> Dictionary:
	var char_data = DataDb.get_character(_selected_char)
	if not char_data:
		return {"hp": 1, "dmg": 1, "spd": 1}
	
	var hp = char_data.base_hp
	var dmg = char_data.base_dmg
	var spd = char_data.base_spd
	
	# Add equipment bonuses
	for slot in ["helmet", "weapon", "boots"]:
		var item_id = _equipped.get(slot, "")
		if not item_id.is_empty():
			var item = DataDb.get_item(item_id)
			if item:
				hp += item.hp
				dmg += item.dmg
				spd += item.spd
	
	return {"hp": hp, "dmg": dmg, "spd": spd}

# =============================================================================
#  EVENT HANDLERS - CHARACTER SELECTION
# =============================================================================
func _on_character_selected(char_id: String) -> void:
	_selected_char = char_id
	_refresh_ui()
	_save_to_manager()

# =============================================================================
#  EVENT HANDLERS - EQUIPMENT DROPDOWN
# =============================================================================
func _on_equipment_button_pressed(slot: String) -> void:
	_pending_slot = slot
	_show_equip_dropdown(slot)

func _show_equip_dropdown(slot: String) -> void:
	# Clear existing items
	for child in _equip_list.get_children():
		child.queue_free()
	
	# Set title
	match slot:
		"helmet": _equip_title.text = "SELECT HELMET"
		"weapon": _equip_title.text = "SELECT WEAPON"
		"boots": _equip_title.text = "SELECT BOOTS"
		_: _equip_title.text = "SELECT EQUIPMENT"
	
	# Get available items for this slot from inventory
	var available_items = _get_available_items_for_slot(slot)
	
	print("=== EQUIP DROPDOWN for %s ===" % slot)
	print("Available items: ", available_items)
	
	# Create buttons for each item
	if available_items.is_empty():
		var no_items_label = Label.new()
		no_items_label.text = "No items available"
		no_items_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_equip_list.add_child(no_items_label)
	else:
		for item_id in available_items:
			var item = DataDb.get_item(item_id)
			if not item:
				continue
			
			var btn = Button.new()
			btn.text = "%s  %s  [%s]" % [_get_slot_icon(slot), item.name, item.rarity]
			btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
			
			# Highlight if this is currently equipped
			if _equipped.get(slot, "") == item_id:
				btn.text = "✓ " + btn.text
			
			btn.pressed.connect(_on_equip_item_selected.bind(item_id))
			_equip_list.add_child(btn)
	
	# Add separator and "Remove" button if something is equipped
	if not _equipped.get(slot, "").is_empty():
		var sep = HSeparator.new()
		_equip_list.add_child(sep)
		
		var remove_btn = Button.new()
		remove_btn.text = "✕  Unequip Current"
		remove_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		remove_btn.pressed.connect(_on_remove_equipment.bind(slot))
		_equip_list.add_child(remove_btn)
	
	# Position popup near the button
	var source_btn: Button
	match slot:
		"helmet": source_btn = _helmet_btn
		"weapon": source_btn = _weapon_btn
		"boots": source_btn = _boots_btn
		_: source_btn = _helmet_btn
	
	var btn_rect = source_btn.get_global_rect()
	var panel_size = Vector2(280, 0)
	_equip_panel.set_global_position(btn_rect.position + Vector2(btn_rect.size.x + 10, 0))
	_equip_panel.custom_minimum_size.x = panel_size.x
	
	_equip_overlay.visible = true

func _get_available_items_for_slot(slot: String) -> Array:
	var result = []
	var inv = _get_inventory()
	
	# Map slot to inventory category
	var category = ""
	match slot:
		"helmet": category = "helm"
		"weapon": category = "weap"
		"boots": category = "boots"
		_: return result
	
	# Get items from inventory for this category
	var items_in_category = inv.get(category, [])
	print("Items in category '%s': %s" % [category, items_in_category])
	
	for item_id in items_in_category:
		var item = DataDb.get_item(item_id)
		if item:
			# Verify the item belongs to this slot
			var belongs = false
			match slot:
				"helmet":
					belongs = (item.slot == ItemData.EquipSlot.HELMET)
				"weapon":
					belongs = (item.slot == ItemData.EquipSlot.WEAPON)
				"boots":
					belongs = (item.slot == ItemData.EquipSlot.BOOTS)
			
			if belongs:
				result.append(item_id)
	
	return result

func _get_slot_icon(slot: String) -> String:
	match slot:
		"helmet": return "🪖"
		"weapon": return "⚔"
		"boots": return "👢"
		_: return "•"

func _on_equip_item_selected(item_id: String) -> void:
	print("Equipping item: %s to slot: %s" % [item_id, _pending_slot])
	_equipped[_pending_slot] = item_id
	_close_equip_overlay()
	_refresh_ui()
	_save_to_manager()
	print("Equipped: ", _equipped)

func _on_remove_equipment(slot: String) -> void:
	print("Unequipping from slot: %s" % slot)
	_equipped[slot] = ""
	_close_equip_overlay()
	_refresh_ui()
	_save_to_manager()

func _close_equip_overlay() -> void:
	_equip_overlay.visible = false
	_pending_slot = ""

func _on_overlay_background_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var panel_rect = _equip_panel.get_global_rect()
		if not panel_rect.has_point(event.global_position):
			_close_equip_overlay()

# =============================================================================
#  EVENT HANDLERS - INVENTORY SLOTS
# =============================================================================
func _on_inventory_slot_input(event: InputEvent, item_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		var item = DataDb.get_item(item_id)
		if item and item.type == ItemData.ItemType.BAG:
			_open_bag(item_id)
		elif item and item.type == ItemData.ItemType.CONSUMABLE:
			_use_consumable(item_id)

func _open_bag(bag_id: String) -> void:
	if not _remove_item(bag_id):
		return
	
	var bag = DataDb.get_item(bag_id)
	if not bag or not bag.pool or bag.pool.is_empty():
		return
	
	var reward = bag.pool.pick_random()
	_add_item(reward)
	
	print("Opened bag: %s, got: %s" % [bag_id, reward])
	_refresh_ui()
	_save_to_manager()

func _use_consumable(item_id: String) -> void:
	# Implement consumable usage logic
	print("Using consumable: %s" % item_id)

# =============================================================================
#  EVENT HANDLERS - QUICK SLOTS
# =============================================================================
func _on_quick_slot_input(event: InputEvent, slot_index: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Use the item in the quick slot
			if not _quick_data[slot_index].is_empty():
				_use_quick_slot_item(slot_index)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Open picker to assign item
			_pending_qs = slot_index
			_show_picker_overlay()

func _use_quick_slot_item(slot_index: int) -> void:
	var item_id = _quick_data[slot_index]
	if item_id.is_empty():
		return
	
	if _has_item(item_id):
		_use_consumable(item_id)
		if _get_item_category(item_id) == "cons":
			_remove_item(item_id)
		_refresh_ui()
		_save_to_manager()

func _show_picker_overlay() -> void:
	_picker_overlay.visible = true

func _close_picker_overlay() -> void:
	_picker_overlay.visible = false
	_pending_qs = -1

func _on_picker_item_input(event: InputEvent, item_id: String) -> void:
	if event is InputEventMouseButton and event.pressed:
		if _has_item(item_id):
			_quick_data[_pending_qs] = item_id
			_close_picker_overlay()
			_refresh_ui()
			_save_to_manager()

func _clear_pending_quick_slot() -> void:
	if _pending_qs >= 0:
		_quick_data[_pending_qs] = ""
	_close_picker_overlay()
	_refresh_ui()
	_save_to_manager()

func _on_picker_overlay_background_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var panel_rect = _picker_overlay.get_node("PickerPanel").get_global_rect()
		if not panel_rect.has_point(event.global_position):
			_close_picker_overlay()

# =============================================================================
#  INPUT HANDLING
# =============================================================================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		# Number keys 1-3 for quick slot usage
		if event.keycode >= KEY_1 and event.keycode <= KEY_3:
			var slot_idx = event.keycode - KEY_1
			_use_quick_slot_item(slot_idx)
		
		# Escape to close overlays
		if event.keycode == KEY_ESCAPE:
			if _equip_overlay.visible:
				_close_equip_overlay()
				get_viewport().set_input_as_handled()
			elif _picker_overlay.visible:
				_close_picker_overlay()
				get_viewport().set_input_as_handled()

# =============================================================================
#  EXIT
# =============================================================================
func _exit_tree() -> void:
	_save_to_manager()
