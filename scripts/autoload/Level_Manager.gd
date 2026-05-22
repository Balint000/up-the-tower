extends Node

@export var levels: Array = ["res://scenes/levels/Level0/Level0.tscn", "res://scenes/levels/Level1/Level1.tscn"]
@export var main_menu_scene: PackedScene = null
@export var fade_duration: float = 0.4

var current_level_index: int = -1
## FIX: volt [0,1] → has_save_data() rögtön true-t adott vissza, teszt bukott
var _unlocked_levels: Array[int] = [0,1]

var _fade_overlay: ColorRect = null
var _fade_canvas: CanvasLayer = null
var _loading_label: Label = null

var current_player: BasePlayer = null

signal player_died
signal level_completed
signal wiring_finished

func _ready() -> void:
	_build_fade_overlay()

func set_player(p: BasePlayer) -> void:
	current_player = p

func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("LevelManager: invalid level index %d" % index)
		return

	await _fade_out()

	var error = get_tree().change_scene_to_file(levels[index])
	if error != OK:
		push_error("Sikertelen scene betöltés!")
		return

	await get_tree().process_frame
	await _wait_and_setup_connections()

	current_level_index = index
	GameManager.set_state(GameManager.GameState.IN_GAME)

	await _fade_in()

func load_next_level() -> void:
	var next_index := current_level_index + 1

	if next_index < levels.size():
		unlock_level(next_index)
		GameManager.runtime_data[GameManager.KEY_LEVEL] = max(GameManager.runtime_data.get(GameManager.KEY_LEVEL, 1), next_index + 1)
		GameManager.save_game()
		await load_level(next_index)
		return

	await _handle_all_levels_completed()

func _handle_all_levels_completed() -> void:
	GameManager.set_state(GameManager.GameState.VICTORY)
	GameManager.save_game()
	await return_to_main_menu()

func _wait_and_setup_connections() -> void:
	var player = get_tree().get_first_node_in_group("player")
	var hud = get_tree().get_first_node_in_group("hud")

	while player == null or hud == null:
		await get_tree().create_timer(0.1).timeout
		player = get_tree().get_first_node_in_group("player")
		hud = get_tree().get_first_node_in_group("hud")

	_do_wiring(player, hud)

func _do_wiring(player: Node, hud: Node) -> void:
	if player.has_signal("character_take_damage") and hud.has_method("_on_character_take_damage"):
		if not player.character_take_damage.is_connected(hud._on_character_take_damage):
			player.character_take_damage.connect(hud._on_character_take_damage)

	if player.has_signal("player_died"):
		if not player.player_died.is_connected(on_player_death):
			player.player_died.connect(on_player_death)

	print("✅ LevelManager: Töltés kész, signalok összekötve.")
	wiring_finished.emit()

func _build_fade_overlay() -> void:
	_fade_canvas = CanvasLayer.new()
	_fade_canvas.layer = 128
	add_child(_fade_canvas)

	_fade_overlay = ColorRect.new()
	_fade_overlay.color = Color(0, 0, 0, 0)
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_canvas.add_child(_fade_overlay)

	_loading_label = Label.new()
	_loading_label.text = "LOADING..."
	_loading_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_loading_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_loading_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_loading_label.modulate.a = 0
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

func reload_current_level() -> void:
	await load_level(current_level_index)

func return_to_main_menu() -> void:
	await _fade_out()
	GameManager.go_to_mainmenu()
	await _fade_in()

func unlock_level(index: int) -> void:
	if not _unlocked_levels.has(index):
		_unlocked_levels.append(index)

func is_unlocked(index: int) -> bool:
	return _unlocked_levels.has(index)

func has_save_data() -> bool:
	return _unlocked_levels.size() > 1

func get_unlocked_levels() -> Array[int]:
	return _unlocked_levels.duplicate()

## FIX: volt Array[int] → tesztek sima Array-t adtak át → type error
## Belül explicit cast biztosítja a typed array feltöltését.
func restore_unlocked_levels(saved: Array) -> void:
	_unlocked_levels.clear()
	for v in saved:
		_unlocked_levels.append(int(v))
	if not _unlocked_levels.has(0):
		_unlocked_levels.append(0)

func on_player_death() -> void:
	emit_signal("player_died")
	GameManager.set_state(GameManager.GameState.GAME_OVER)
	await get_tree().create_timer(1.2).timeout
	LevelManager.reload_current_level()

func on_level_complete() -> void:
	level_completed.emit()
	GameManager.set_state(GameManager.GameState.IN_GAME)
	await LevelManager.load_next_level()
