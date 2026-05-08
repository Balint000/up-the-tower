extends Node

## Levels in play order.
@export var levels: Array = ["res://scenes/levels/Level0/Level0.tscn"]
@export var main_menu_scene: PackedScene = null
@export var fade_duration: float = 0.4

var current_level_index: int = -1 
var _unlocked_levels: Array[int] = [0]

# UI elemek a töltéshez
var _fade_overlay: ColorRect = null
var _fade_canvas: CanvasLayer = null
var _loading_label: Label = null

## Current player character
var current_player: BasePlayer = null

signal player_died
signal level_completed
signal wiring_finished # Új signal: akkor fut le, ha minden node a helyén van

func _ready() -> void:
	_build_fade_overlay()

func set_player(p: BasePlayer) -> void:
	current_player = p


# ---------------------------------------------------------------------------
# Level loading
# ---------------------------------------------------------------------------

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("LevelManager: invalid level index %d" % index)
		return

	# 1. Elindítjuk a sötétítést
	await _fade_out()
	
	# 2. Scene váltás
	var error = get_tree().change_scene_to_file(levels[index])
	if error != OK:
		push_error("Sikertelen scene betöltés!")
		return

	# 3. Várunk, amíg a Godot felépíti a fát (legalább 1 frame)
	await get_tree().process_frame
	
	# 4. Megpróbáljuk összekötni a szálakat. 
	# Ha nem találja elsőre (pl. bonyolult scene), addig várunk, amíg meglesznek.
	await _wait_and_setup_connections()
	
	current_level_index = index
	GameManager.set_state(GameManager.GameState.IN_GAME)
	
	# 5. Csak most fedjük fel a játékot
	await _fade_in()

## Biztonságos összekötés: addig próbálkozik, amíg meg nem találja a Player-t és a HUD-ot
func _wait_and_setup_connections() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var hud = get_tree().get_first_node_in_group("hud")
	
	# Ha még nincsenek ott, várunk egy kicsit (időzítési problémák ellen)
	while player == null or hud == null:
		await get_tree().create_timer(0.1).timeout
		player = get_tree().get_first_node_in_group("player")
		hud = get_tree().get_first_node_in_group("hud")
	
	# Most már biztosan megvannak, jöhet a wiring
	_do_wiring(player, hud)

func _do_wiring(player: Node, hud: Node) -> void:
	# Player -> HUD kapcsolat (Health)
	if player.has_signal("character_take_damage") and hud.has_method("_on_character_take_damage"):
		if not player.character_take_damage.is_connected(hud._on_character_take_damage):
			player.character_take_damage.connect(hud._on_character_take_damage)
	
	# Player -> LevelManager kapcsolat (Halál)
	if player.has_signal("died"):
		if not player.died.is_connected(on_player_death):
			player.died.connect(on_player_death)
			
	print("✅ LevelManager: Töltés kész, signalok összekötve.")
	wiring_finished.emit()

# ---------------------------------------------------------------------------
# Fade & Loading UI
# ---------------------------------------------------------------------------

func _build_fade_overlay() -> void:
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 128 
	add_child(_fade_canvas)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_canvas.add_child(_fade_overlay)
	
	# Töltés felirat hozzáadása
	_loading_label = Label.new()
	_loading_label.text = "LOADING..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_label.modulate.a = 0 # Alapból láthatatlan
	_fade_overlay.add_child(_loading_label)

func _fade_out() -> void:
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(_fade_overlay, "color:a", 1.0, fade_duration)
	t.tween_property(_loading_label, "modulate:a", 1.0, fade_duration)
	await t.finished

func _fade_in() -> void:
	var t: Tween = create_tween().set_parallel(true)
	t.tween_property(_fade_overlay, "color:a", 0.0, fade_duration)
	t.tween_property(_loading_label, "modulate:a", 0.0, fade_duration)
	await t.finished

## Restart the current level (called on game over / player death).
func reload_current_level() -> void:
	await load_level(current_level_index)

## Go back to the main menu.
func return_to_main_menu() -> void:

	await _fade_out()
	GameManager.go_to_mainmenu()
	await _fade_in() # elvileg nem fut le

# ---------------------------------------------------------------------------
# Unlock system
# ---------------------------------------------------------------------------

## Unlock a level by index so it appears in Level Select.
func unlock_level(index: int) -> void:
	if not _unlocked_levels.has(index):
		_unlocked_levels.append(index)


## Returns true if the level at index has been unlocked.
## levels.gd uses this to decide what to show on each level select button.
func is_unlocked(index: int) -> bool:
	return _unlocked_levels.has(index)


## Returns true if any level beyond the first has been unlocked.
## main.gd uses this to show or hide the Level Select button.
func has_save_data() -> bool:
	return _unlocked_levels.size() > 1


## Returns the full unlocked list. SaveSystem calls this before writing a save.
func get_unlocked_levels() -> Array[int]:
	return _unlocked_levels.duplicate()


## Restores the unlocked list from a save file. SaveSystem calls this on load.
func restore_unlocked_levels(saved: Array[int]) -> void:
	_unlocked_levels = saved
	# Make sure level 0 is always accessible even if the save file is broken.
	if not _unlocked_levels.has(0):
		_unlocked_levels.append(0)


# ---------------------------------------------------------------------------
# Fade helpers
# ---------------------------------------------------------------------------

func on_player_death() -> void:
	# GameManager.runtime_data[KEY_STATISTICS][KEY_DEATHS] += 1 ; ha lesz ilyen statisztika, akkor valami hasonlót kell berakni
	player_died.emit()
	GameManager.set_state(GameManager.GameState.GAME_OVER)
	# Short pause so the death animation plays before we reload.
	await get_tree().create_timer(1.2).timeout
	LevelManager.reload_current_level()
 
## Called when the player touches the Goal object.
func on_level_complete() -> void:
	level_completed.emit()
	GameManager.set_state(GameManager.GameState.IN_GAME)
	await LevelManager.load_next_level()
