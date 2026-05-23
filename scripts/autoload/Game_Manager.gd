extends Node

## GameStates
enum GameState {
	MAIN_MENU,
	INVENTORY,
	LEVEL_SELECT,
	IN_GAME,
	PAUSED,
	GAME_OVER,
	VICTORY
}

## Constants
const KEY_LEVEL := "level"
const KEY_XP := "xp"
const KEY_INVENTORY := "inventory"
const KEY_SELECTED_CHARACTER := "selected_character"
const KEY_STATISTICS := "statistics"
const KEY_KILLS := "kills"
const KEY_DEATHS := "deaths"
const KEY_EQUIPPED_ITEMS := "equipped_items"
const KEY_WEAPON := "weapon"
const KEY_HELMET := "helmet"
const KEY_DMG := "damage"
const KEY_HP := "health"
const KEY_SPEED := "speed"
const KEY_BOOTS := "boots"
const KEY_QUICK_SLOTS := "quick_slots"
const KEY_BAG = "bag"
const KEY_OPENED_BAGS = "opened_bags"

## Signals
signal state_changed(new_state: GameState)
#signal level_loaded(level_id: String)
signal game_paused()
signal game_resumed()
signal inventory_updated()
#signal lose()
#signal victory()

## Runtime Data
var runtime_data := {
	KEY_LEVEL: 1,
	KEY_XP: 10,
	
	KEY_INVENTORY: {
		"helm": [],
		"weap": ['basic_sword'],
		"boots": [],
		"cons": {
			"beer": 0,
			"apple": 0,
			"key": 0,
			KEY_BAG: 2
		}
	},
	
	KEY_SELECTED_CHARACTER: "knight",
	
	KEY_STATISTICS: {
		KEY_KILLS: 0,
		KEY_DEATHS: 0
	},
	
	KEY_EQUIPPED_ITEMS: {
		KEY_WEAPON: "",
		KEY_HELMET: "",
		KEY_BOOTS: ""
	}
}

## Player Data
var player_data := {
	KEY_DMG: 1,
	KEY_HP: 1,
	KEY_SPEED: 1,
	KEY_ABILITY: "dash"
}

## Current State
var current_state : GameState

func _ready() -> void:
	current_state = GameState.MAIN_MENU
	print("GameManager Init : ", GameState.keys()[current_state])
	load_game()
	_update_player_stats()
	print("DataDb from GameManager: ",DataDb.enemies)

## game save
func save_game() -> void:
	SaveManager.save_player_data_json(runtime_data)
 
## game load
func load_game() -> void:
	var loaded_data := SaveManager.load_player_data_json()

	if loaded_data.is_empty():
		print("Nincs mentés: default runtime_data marad")
		return

	runtime_data = loaded_data
	
	_ensure_data_structure()


func _ensure_data_structure() -> void:

	if not runtime_data.has(KEY_INVENTORY):
		runtime_data[KEY_INVENTORY] = {
			"helm": [],
			"weap": [],
			"boots": [],
			"cons": {}
		}
	
	var inv = runtime_data[KEY_INVENTORY]
	if not inv.has("helm"): inv["helm"] = []
	if not inv.has("weap"): inv["weap"] = []
	if not inv.has("boots"): inv["boots"] = []
	if not inv.has("cons"): inv["cons"] = {}
	

	if not runtime_data.has(KEY_EQUIPPED_ITEMS):
		runtime_data[KEY_EQUIPPED_ITEMS] = {
			KEY_HELMET: "",
			KEY_WEAPON: "",
			KEY_BOOTS: ""
		}
	
	if not runtime_data.has(KEY_QUICK_SLOTS):
		runtime_data[KEY_QUICK_SLOTS] = ["", "", ""]
	
	if not runtime_data.has(KEY_STATISTICS):
		runtime_data[KEY_STATISTICS] = {KEY_KILLS: 0, KEY_DEATHS: 0}

# Inventory managment
func inventory_add(item_id: String, amount: int = 1) -> void:
	var item = DataDb.get_item(item_id)
	if item == null:
		push_warning("Item not found: " + item_id)
		return
	
	var inv: Dictionary = runtime_data.get(KEY_INVENTORY, {})
	var category = _get_item_category(item)
	
	match category:
		"helm", "weap", "boots":
			if not inv.has(category):
				inv[category] = []
			# Equipment is unique - add only if not already owned
			if not inv[category].has(item_id):
				inv[category].append(item_id)
		"cons":
			if not inv.has("cons"):
				inv["cons"] = {}
			inv["cons"][item_id] = inv["cons"].get(item_id, 0) + amount
	
	runtime_data[KEY_INVENTORY] = inv
	inventory_updated.emit()

## Remove item from inventory
func inventory_remove(item_id: String, amount: int = 1) -> bool:
	var item = DataDb.get_item(item_id)
	if item == null:
		return false
	
	var inv: Dictionary = runtime_data.get(KEY_INVENTORY, {})
	var category = _get_item_category(item)
	
	match category:
		"helm", "weap", "boots":
			if inv.get(category, []).has(item_id):
				inv[category].erase(item_id)
				runtime_data[KEY_INVENTORY] = inv
				inventory_updated.emit()
				return true
		"cons":
			if inv.get("cons", {}).get(item_id, 0) > 0:
				inv["cons"][item_id] -= amount
				if inv["cons"][item_id] <= 0:
					inv["cons"].erase(item_id)
				runtime_data[KEY_INVENTORY] = inv
				inventory_updated.emit()
				return true
	
	return false

## Check if player has item
func inventory_has(item_id: String, amount: int = 1) -> bool:
	var item = DataDb.get_item(item_id)
	if item == null:
		return false
	
	var inv: Dictionary = runtime_data.get(KEY_INVENTORY, {})
	var category = _get_item_category(item)
	
	match category:
		"helm", "weap", "boots":
			return inv.get(category, []).has(item_id)
		"cons":
			return inv.get("cons", {}).get(item_id, 0) >= amount
	
	return false

## Get item count (for consumables)
func inventory_get_count(item_id: String) -> int:
	var inv: Dictionary = runtime_data.get(KEY_INVENTORY, {})
	return inv.get("cons", {}).get(item_id, 0)

## Get category for an item
func _get_item_category(item: Resource) -> String:
	if item is ItemResource:
		match item.slot:
			ItemResource.EquipSlot.HELMET: return "helm"
			ItemResource.EquipSlot.WEAPON: return "weap"
			ItemResource.EquipSlot.BOOTS: return "boots"
	return "cons"

#Equipment Managment

func equip_item(item_id: String) -> bool:
	var item = DataDb.get_item(item_id)
	if item == null:
		return false
	
	if not inventory_has(item_id):
		push_warning("Cannot equip item not in inventory: " + item_id)
		return false
	
	var equipped = runtime_data.get(KEY_EQUIPPED_ITEMS, {})
	
	match item.slot:
		ItemResource.EquipSlot.HELMET:
			equipped[KEY_HELMET] = item_id
		ItemResource.EquipSlot.WEAPON:
			equipped[KEY_WEAPON] = item_id
		ItemResource.EquipSlot.BOOTS:
			equipped[KEY_BOOTS] = item_id
		_:
			push_warning("Item is not equippable: " + item_id)
			return false
	
	runtime_data[KEY_EQUIPPED_ITEMS] = equipped
	_update_player_stats()
	save_game()
	return true

## Unequip an item
func unequip_item(slot: String) -> void:
	var equipped = runtime_data.get(KEY_EQUIPPED_ITEMS, {})
	equipped[slot] = ""
	runtime_data[KEY_EQUIPPED_ITEMS] = equipped
	_update_player_stats()
	save_game()

## Update player stats based on character and equipment
func _update_player_stats() -> void:
	var char_data = DataDb.get_character(runtime_data.get(KEY_SELECTED_CHARACTER, "knight"))
	if char_data == null:
		return
	
	var hp = char_data.base_hp
	var dmg = char_data.base_dmg
	var spd = char_data.base_spd
	var ability = char_data.ability_type
	
	var equipped = runtime_data.get(KEY_EQUIPPED_ITEMS, {})
	
	for slot_key in [KEY_HELMET, KEY_WEAPON, KEY_BOOTS]:
		var item_id = equipped.get(slot_key, "")
		if not item_id.is_empty():
			var item = DataDb.get_item(item_id)
			if item:
				hp += item.hp
				dmg += item.dmg
				spd += item.spd
	
	player_data[KEY_HP] = hp
	player_data[KEY_DMG] = dmg
	player_data[KEY_SPEED] = spd
	player_data[KEY_ABILITY] = ability

func get_state() -> GameState:
	return current_state

func is_state(state: GameState) -> bool:
	return current_state == state

func set_state(new_state: GameState):
	var old_state = current_state
	current_state = new_state
	
	print("Állapotváltás: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
	state_changed.emit(new_state)
	
	# Állapot-specifikus műveletek
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
			game_paused.emit()
		GameState.IN_GAME, GameState.MAIN_MENU, GameState.INVENTORY, GameState.LEVEL_SELECT:
			get_tree().paused = false
			if old_state == GameState.PAUSED:
				game_resumed.emit()

## change scene --> MainMenu
func go_to_mainmenu() -> void:
	save_game()
	set_state(GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

## change scene --> LevelMenu
func go_to_levelmenu() -> void:
	save_game()
	set_state(GameState.LEVEL_SELECT)
	get_tree().change_scene_to_file("res://scenes/level_menu/level_menu.tscn")

## change scene --> InventoryMenu
func go_to_inventorymenu() -> void:
	print("GameState: mainmenu -> inventory, inventory -> mainmenu")
	print("Under maintenance")
	# set_state(GameState.INVENTORY)
	# get_tree().change_scene_to_file("res://scenes/inventory/inventory.tscn")

func go_to_game() -> void:
	_update_player_stats()
	set_state(GameState.IN_GAME)
	# get_tree().change_scene_to_file("res://scenes/game/game.tscn")

## change scene --> Quit Game
func quit_game():
	save_game()
	get_tree().quit()
