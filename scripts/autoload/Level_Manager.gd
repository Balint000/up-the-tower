## Autoload singleton, registered as "LevelManager" in Project Settings.
## Handles level loading, unlocked levels, and fade transitions.
##
## Other scripts that use this:
##   - main.gd           : calls has_save_data() to show/hide the Level Select button
##   - levels.gd         : calls load_level(index) when the player picks a level,
##                         and is_unlocked(index) to grey out locked levels
##   - GameManager.gd    : calls load_next_level() on goal reached,
##                         reload_current_level() on game over
##   - SaveSystem.gd     : calls restore_unlocked_levels() after loading a save file,
##                         reads get_unlocked_levels() before writing a save file
extends Node

## Levels in play order. Drag Level_01.tscn, Level_02.tscn ... here in the editor.
@export var levels: Array = ["res://scenes/levels/level0.tscn"]

## The main menu scene. Drag scenes/main/main.tscn here in the editor.
@export var main_menu_scene: PackedScene = null

## Fade duration in seconds (black-out between scene changes).
@export var fade_duration: float = 0.4

## Current level index stored (helper). 
## -1 means we are on the main menu
var current_level_index: int = -1 

## Level 0 is always unlocked. More are added by unlock_level().
var _unlocked_levels: Array[int] = [0]

## Fade overlay nodes, created once in _ready().
var _fade_overlay: ColorRect = null
var _fade_canvas: CanvasLayer = null


func _ready() -> void:
	_build_fade_overlay()


# ---------------------------------------------------------------------------
# Level loading
# ---------------------------------------------------------------------------

## Load a level by index. Plays a fade transition around the scene swap.
func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("LevelManager: invalid level index %d" % index)
		return

	await _fade_out()
	get_tree().change_scene_to_file("res://scenes/levels/level0.tscn")
	GameManager.set_state(GameManager.GameState.IN_GAME)
	current_level_index = index
	await _fade_in()

## Load the level that comes after the current one.
## Unlocks it first, then loads it. Returns to main menu if there is no next level.
func load_next_level() -> void:
	var next: int = current_level_index + 1

	if next >= levels.size():
		await GameManager.go_to_mainmenu()
		return

	unlock_level(next)
	await load_level(next)

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

## Creates a black full-screen rect on a high CanvasLayer.
## It starts transparent and is animated by _fade_out / _fade_in.
func _build_fade_overlay() -> void:
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 128  # On top of everything.
	add_child(_fade_canvas)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0, 0, 0, 0)  # Transparent to start.
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_canvas.add_child(_fade_overlay)


## Animate alpha from 0 to 1 (screen goes black).
func _fade_out() -> void:
	var t: Tween = create_tween()
	t.tween_property(_fade_overlay, "color:a", 1.0, fade_duration)
	await t.finished


## Animate alpha from 1 to 0 (screen reveals the new scene).
func _fade_in() -> void:
	var t: Tween = create_tween()
	t.tween_property(_fade_overlay, "color:a", 0.0, fade_duration)
	await t.finished
