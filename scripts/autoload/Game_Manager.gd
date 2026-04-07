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
const KEY_ARMOR := "armor"
const KEY_DMG := "damage"
const KEY_HP := "health"
const KEY_SPEED := "speed"

## Signals
signal state_changed(new_state: GameState)
#signal level_loaded(level_id: String)
signal game_paused()
signal game_resumed()
#signal lose()
#signal victory()

## Runtime Data
var runtime_data := {
	KEY_LEVEL: 1,
	KEY_XP: 10,
	
	KEY_INVENTORY: ["basic_sword"],
	
	KEY_SELECTED_CHARACTER: "knight",
	
	KEY_STATISTICS: {
		KEY_KILLS: 0,
		KEY_DEATHS: 0
	},
	
	KEY_EQUIPPED_ITEMS: {
		KEY_WEAPON: "",
		KEY_ARMOR: ""
	}
}

## Player Data
var player_data := {
	KEY_DMG: 1,
	KEY_HP: 1,
	KEY_SPEED: 1
}

## Current State
var current_state : GameState

func _ready() -> void:
	current_state = GameState.MAIN_MENU
	print("GameManager Init : ", GameState.keys()[current_state])

## game save
func save_game() -> void:
	SaveManager.save_player_data_json(runtime_data)

## game load
func load_game() -> void:
	var loaded_data := SaveManager.load_player_data_json()

	if loaded_data.is_empty():
		print("No save: default runtime_data")
		return

	runtime_data = loaded_data

func get_state() -> GameState:
	return current_state

func is_state(state: GameState) -> bool:
	return current_state == state

func set_state(new_state: GameState):
	var old_state = current_state
	current_state = new_state
	
	print("State changing: ", GameState.keys()[old_state], " -> ", GameState.keys()[new_state])
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
	set_state(GameState.MAIN_MENU)
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

## change scene --> LevelMenu
func go_to_levelmenu() -> void:
	set_state(GameState.LEVEL_SELECT)
	get_tree().change_scene_to_file("res://scenes/level_menu/level_menu.tscn")

## change scene --> InventoryMenu
func go_to_inventorymenu() -> void:
	set_state(GameState.INVENTORY)
	get_tree().change_scene_to_file("res://scenes/inventory/inventory.tscn")

## change scene --> Quit Game
func quit_game():
	get_tree().quit()
