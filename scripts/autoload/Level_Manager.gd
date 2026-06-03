## LevelManager.gd
## -------------------------------------------------------
## Scene-based autoload (register LevelManager.tscn, NOT .gd).
##
## Handles:
##   - Level loading with fade transitions
##   - Player/HUD signal wiring after scene load
##   - Story intro/outro playback around levels
##   - Player death → reload
##   - Level unlocking & save data
##   - Return to main menu
##
## The .tscn provides these child nodes under UILayer:
##   FadeOverlay   (ColorRect, full-screen, mouse_filter=IGNORE)
##   LoadingLabel  (Label, centered on FadeOverlay)
##   LoadingLabel modulate.a tracks the fade (visible during fade-out)
##   StoryOverlay  (instance of scenes/ui/StoryOverlay.tscn)
## -------------------------------------------------------
extends Node

# ── Signals ──────────────────────────────────────────────
signal player_died
signal level_completed
signal wiring_finished

# ── Exports ──────────────────────────────────────────────
@export var levels: Array = [
	"res://scenes/levels/Level0/Level0.tscn",
	"res://scenes/levels/Level1/Level1.tscn",
	"res://scenes/levels/Level3/Level3.tscn",
]
@export var main_menu_scene: PackedScene = null
@export var fade_out_duration: float = 0.4
@export var fade_in_duration: float = 1.5
@export var minimum_loading_time: float = 1.0

# ── State ────────────────────────────────────────────────
var current_level_index: int = -1
var _unlocked_levels: Array = []
var _is_reloading: bool = false
var current_player: BasePlayer = null
var _transitioning: bool = false


# ── Node refs (from .tscn) ──────────────────────────────
@onready var _fade_overlay: ColorRect = $UILayer/FadeOverlay
@onready var _loading_label: Label = $UILayer/FadeOverlay/LoadingLabel
@onready var _story_overlay = $UILayer/StoryOverlay

# ── Fade state (_process-driven, pause-safe) ─────────────
var _fade_target: float = 0.0
var _fade_current: float = 0.0
var _fading: bool = false
var _current_fade_time: float = 0.4


# ═══════════════════════════════════════════════════════
#  _PROCESS — fade animation (pause-safe)
# ═══════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _fading:
		return
	_fade_current = move_toward(_fade_current, _fade_target, delta / _current_fade_time)
	_fade_overlay.color.a = _fade_current
	_loading_label.modulate.a = _fade_current
	if is_equal_approx(_fade_current, _fade_target):
		_fading = false


func _fade_out() -> void:
	_current_fade_time = fade_out_duration
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_target = 1.0
	_fade_current = _fade_overlay.color.a
	_fading = true
	while _fading:
		await get_tree().process_frame


func _fade_in() -> void:
	_current_fade_time = fade_in_duration
	_fade_target = 0.0
	_fade_current = _fade_overlay.color.a
	_fading = true
	while _fading:
		await get_tree().process_frame
	_fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ═══════════════════════════════════════════════════════
#  PUBLIC API
# ═══════════════════════════════════════════════════════

func set_player(p: BasePlayer) -> void:
	current_player = p


func load_level(index: int) -> void:
	if index < 0 or index >= levels.size():
		push_error("LevelManager: invalid level index %d" % index)
		return
	if _transitioning:
		return

	_transitioning = true

	await _fade_out()
	
	# ── Play intro story (if any) ──
	var stories: Dictionary = StoryDataLoader.load_level_stories(index)
	if stories["intro"].size() > 0:
		_story_overlay.play(stories["intro"])
		await _story_overlay.finished
	
	_loading_label.visible = true
	var loading_start := Time.get_ticks_msec()
	var error: int = get_tree().change_scene_to_file(levels[index])
	if error != OK:
		push_error("Sikertelen scene betöltés!")
		_transitioning = false
		return

	await get_tree().process_frame
	await _wait_and_setup_connections()

	var elapsed := (Time.get_ticks_msec() - loading_start) / 1000.0
	if elapsed < minimum_loading_time:
		await get_tree().create_timer(minimum_loading_time - elapsed).timeout
	
	current_level_index = index
	GameManager.set_state(GameManager.GameState.IN_GAME)
	
	_loading_label.visible = false

	await _fade_in()

	_transitioning = false

func load_next_level() -> void:
	var next_index: int = current_level_index + 1
	
	await _fade_out()
	
	# ── Play current level's outro before loading next ──
	var stories: Dictionary = StoryDataLoader.load_level_stories(current_level_index)
	if stories["outro"].size() > 0:
		_story_overlay.play(stories["outro"])
		await _story_overlay.finished

	if next_index < levels.size():
		unlock_level(next_index)
		GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS] = _unlocked_levels
		GameManager.save_game()

		await load_level(next_index)
		return

	await _handle_all_levels_completed()


func reload_current_level() -> void:
	await load_level(current_level_index)


func return_to_main_menu() -> void:
	await _fade_out()
	GameManager.go_to_mainmenu()
	await _fade_in()


func play_intro() -> void:
	var cards: Array[Dictionary] = StoryDataLoader.load_intro()
	if cards.size() > 0:
		_story_overlay.play(cards)
		await _story_overlay.finished


# ═══════════════════════════════════════════════════════
#  DEATH / COMPLETE
# ═══════════════════════════════════════════════════════

func on_player_death() -> void:
	if _is_reloading:
		return
	_is_reloading = true

	emit_signal("player_died")
	GameManager.set_state(GameManager.GameState.GAME_OVER)
	await get_tree().create_timer(1.2).timeout
	LevelManager.reload_current_level()

	_is_reloading = false


func on_level_complete() -> void:
	level_completed.emit()
	GameManager.set_state(GameManager.GameState.IN_GAME)
	await LevelManager.load_next_level()


func _handle_all_levels_completed() -> void:
	GameManager.set_state(GameManager.GameState.VICTORY)
	GameManager.save_game()
	await return_to_main_menu()


# ═══════════════════════════════════════════════════════
#  WIRING
# ═══════════════════════════════════════════════════════

func _wait_and_setup_connections() -> void:
	var player: Node = get_tree().get_first_node_in_group("player")
	var hud: Node = get_tree().get_first_node_in_group("hud")

	while player == null or hud == null:
		await get_tree().create_timer(0.1).timeout
		player = get_tree().get_first_node_in_group("player")
		hud = get_tree().get_first_node_in_group("hud")

	_do_wiring(player, hud)


func _do_wiring(player: Node, hud: Node) -> void:
	if player.has_signal("character_take_damage") and hud.has_method("_on_character_take_damage"):
		if not player.character_take_damage.is_connected(hud._on_character_take_damage):
			player.character_take_damage.connect(hud._on_character_take_damage)

	if player.has_signal("player_heal") and hud.has_method("_on_character_heal"):
		if not player.player_heal.is_connected(hud._on_character_heal):
			player.player_heal.connect(hud._on_character_heal)
			print("heal összekötve")

	if player.has_signal("player_died"):
		if not player.player_died.is_connected(on_player_death):
			player.player_died.connect(on_player_death)

	#if player.has_signal("ability_used") and hud.has_method("_on_character_ability_used"):
	#	if not player.ability_used.is_connected(hud._on_character_ability_used):
	#		player.ability_used.connect(hud._on_character_ability_used)

	print("✅ LevelManager: Töltés kész, signalok összekötve.")
	wiring_finished.emit()


# ═══════════════════════════════════════════════════════
#  UNLOCK / SAVE
# ═══════════════════════════════════════════════════════

func unlock_level(index: int) -> void:
	if not _unlocked_levels.has(index):
		_unlocked_levels.append(index)


func is_unlocked(index: int) -> bool:
	return _unlocked_levels.has(index)


func has_save_data() -> bool:
	return _unlocked_levels.size() > 1


func get_unlocked_levels() -> Array[int]:
	return _unlocked_levels.duplicate()


func restore_unlocked_levels(saved: Array) -> void:
	_unlocked_levels.clear()
	for v in saved:
		_unlocked_levels.append(int(v))
	if not _unlocked_levels.has(0):
		_unlocked_levels.append(0)


# ═══════════════════════════════════════════════════════
#  READY
# ═══════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS
	_unlocked_levels = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS]
