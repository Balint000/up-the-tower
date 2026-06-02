## StoryOverlay.gd
## -------------------------------------------------------
## Cinematic story/cutscene overlay for Godot 4.
## Place at: res://scenes/ui/StoryOverlay.gd
##
## DESIGN PRINCIPLES (v2 rewrite):
##   - All animation driven by _process + delta, NOT Tween
##     (Tweens silently die when tree is paused — this was
##      the #1 source of bugs in v1)
##   - Minimal node tree, no nested containers that shift
##   - Signal-based: emits "finished" when done, owner
##     decides what to do next
##   - mouse_filter toggled only in play() / _end_play()
##
## CONTROLS:
##   SPACE / Left-Click  →  skip typing or advance card
##   ESC                  →  skip entire story
##   SkipButton           →  skip entire story
## -------------------------------------------------------
extends ColorRect

signal finished

# ── Exports ──────────────────────────────────────────────
@export_group("Timing")
@export var typing_speed: float = 35.0     ## characters per second
@export var card_pause: float = 1.2        ## pause between cards (s)
@export var fade_duration: float = 0.5     ## overlay fade in/out (s)
@export var image_fade_duration: float = 0.8
@export var ken_burns_duration: float = 6.0

@export_group("Ken Burns")
@export var kb_zoom_start: float = 1.0
@export var kb_zoom_end: float = 1.12

@export_group("Visual")
@export var bg_color: Color = Color(0.04, 0.04, 0.06, 1.0)
@export var hint_pulse_speed: float = 5.0

# ── Internal state ───────────────────────────────────────
var _cards: Array[Dictionary] = []
var _card_idx: int = 0
var _playing: bool = false
var _hint_time: float = 0.0

# Typewriter
var _typing: bool = false
var _char_count: float = 0.0
var _full_text: String = ""

# Ken Burns — we animate pivot_offset + scale + position
var _kb_time: float = 0.0
var _kb_drift: Vector2 = Vector2.ZERO   ## normalised direction
var _kb_active: bool = false
var _kb_fade: float = 0.0               ## image fade-in 0→1

# Overlay fade
var _overlay_alpha: float = 0.0
var _fading_in: bool = false
var _fading_out: bool = false

# Skip flags
var _skip_typing: bool = false
var _advance: bool = false
var _skip_all: bool = false

# Pause tracking
var _was_paused: bool = false

# ── Node refs ────────────────────────────────────────────
@onready var _image_box: Control        = $ImageBox
@onready var _story_image: TextureRect  = $ImageBox/StoryImage
@onready var _text_panel: PanelContainer = $TextPanel
@onready var _story_text: RichTextLabel = $TextPanel/Margin/VBox/StoryText
@onready var _continue_hint: Label      = $TextPanel/Margin/VBox/ContinueHint
@onready var _skip_btn: Button          = $SkipButton

# ── Ken Burns presets ───────────────────────────────────
var _kb_presets: Array[Vector2] = [
	Vector2( 1,  0),   # → right
	Vector2(-1,  0),   # ← left
	Vector2( 0,  1),   # ↓ down
	Vector2( 0, -1),   # ↑ up
	Vector2( 1,  1).normalized(),
	Vector2(-1,  1).normalized(),
]


# ═══════════════════════════════════════════════════════
#  PUBLIC
# ═══════════════════════════════════════════════════════

func play(cards: Array[Dictionary]) -> void:
	if _playing:
		return
	_playing = true
	_cards = cards
	_card_idx = 0

	# ── Pause game ──
	_was_paused = get_tree().paused
	get_tree().paused = true

	# ── Show overlay (captures input) ──
	mouse_filter = Control.MOUSE_FILTER_STOP
	_skip_btn.visible = true
	_text_panel.visible = true
	_continue_hint.visible = false
	_story_text.visible_characters = 0
	_story_image.visible = false
	_image_box.visible = false

	# ── Fade in overlay ──
	_overlay_alpha = 0.0
	color = Color(bg_color.r, bg_color.g, bg_color.b, 0.0)
	_fading_in = true
	_fading_out = false
	await _wait_for_fade()

	# ── Play each card ──
	while _card_idx < _cards.size() and not _skip_all:
		_show_card(_cards[_card_idx])
		await _wait_card_done()
		_card_idx += 1

	# ── Fade out ──
	_fading_out = true
	_fading_in = false
	await _wait_for_fade()

	# ── Cleanup ──
	_end_play()


func force_hide() -> void:
	_skip_all = true
	_fading_in = false
	_fading_out = false
	_overlay_alpha = 0.0
	color = Color(bg_color.r, bg_color.g, bg_color.b, 0.0)
	visible = false
	_end_play()


# ═══════════════════════════════════════════════════════
#  _PROCESS  —  all animation lives here
# ═══════════════════════════════════════════════════════

func _process(delta: float) -> void:
	if not _playing:
		return

	# ── Overlay fade ──
	if _fading_in:
		_overlay_alpha = move_toward(_overlay_alpha, 1.0, delta / fade_duration)
		color.a = _overlay_alpha
		if _overlay_alpha >= 1.0:
			_fading_in = false
	elif _fading_out:
		_overlay_alpha = move_toward(_overlay_alpha, 0.0, delta / fade_duration)
		color.a = _overlay_alpha
		if _overlay_alpha <= 0.0:
			_fading_out = false

	# ── Ken Burns ──
	if _kb_active and _story_image.visible:
		_kb_time += delta
		var t: float = clampf(_kb_time / ken_burns_duration, 0.0, 1.0)

		# Smooth ease-in-out
		var eased: float = t * t * (3.0 - 2.0 * t)

		# Zoom from center (pivot is center of ImageBox)
		var s: float = lerpf(kb_zoom_start, kb_zoom_end, eased)
		_story_image.scale = Vector2(s, s)

		# Pan drift
		var max_px: float = _image_box.size.x * 0.05
		var drift_offset: Vector2 = _kb_drift * max_px * eased
		# Position = center - half_scaled_size + drift
		var half_scaled: Vector2 = _image_box.size * s * 0.5
		_story_image.position = (_image_box.size * 0.5) - half_scaled + drift_offset

		# Image fade-in
		if _kb_fade < 1.0:
			_kb_fade = move_toward(_kb_fade, 1.0, delta / image_fade_duration)
			_story_image.modulate.a = _kb_fade

	# ── Typewriter ──
	if _typing:
		_char_count += typing_speed * delta
		var vis: int = int(_char_count)
		if vis >= _full_text.length():
			vis = _full_text.length()
			_typing = false
			_continue_hint.visible = true
		_story_text.visible_characters = vis
	
	if _continue_hint.visible:
		_hint_time += delta
		var pulse_alpha: float = 0.7 + 0.3 * sin(_hint_time * hint_pulse_speed)
		_continue_hint.modulate.a = pulse_alpha


# ═══════════════════════════════════════════════════════
#  CARD PLAYBACK
# ═══════════════════════════════════════════════════════

func _show_card(card: Dictionary) -> void:
	_skip_typing = false
	_advance = false

	# ── Image ──
	if card.has("image") and card["image"] != "":
		var tex: Texture2D = load(card["image"])
		if tex:
			_image_box.visible = true
			_story_image.visible = true
			_story_image.texture = tex
			_story_image.modulate.a = 0.0

			# Reset Ken Burns
			_kb_active = true
			_kb_time = 0.0
			_kb_fade = 0.0
			_kb_drift = _kb_presets[randi() % _kb_presets.size()]

			# Start at zoom_start, centered in ImageBox
			_story_image.scale = Vector2(kb_zoom_start, kb_zoom_start)
			var half_s: Vector2 = _image_box.size * kb_zoom_start * 0.5
			_story_image.position = (_image_box.size * 0.5) - half_s
		else:
			_image_box.visible = false
			_story_image.visible = false
			_kb_active = false
	else:
		_image_box.visible = false
		_story_image.visible = false
		_kb_active = false

	# ── Text ──
	_story_text.visible_characters = 0
	_continue_hint.visible = false
	_continue_hint.modulate.a = 1.0
	_hint_time = 1.5
	if card.has("text") and card["text"] != "":
		_full_text = card["text"]
		_story_text.text = _full_text
		_char_count = 0.0
		_typing = true
	else:
		_typing = false
		_full_text = ""
		_story_text.text = ""


func _wait_card_done() -> void:
	while _playing and not _skip_all:
		if _typing:
			if _skip_typing or _skip_all:
				_story_text.visible_characters = -1
				_typing = false
				_continue_hint.visible = true
			else:
				await get_tree().process_frame
				continue

		if _advance or _skip_all:
			return

		await get_tree().process_frame


# ═══════════════════════════════════════════════════════
#  FADE HELPERS
# ═══════════════════════════════════════════════════════

func _wait_for_fade() -> void:
	while (_fading_in or _fading_out) and not _skip_all:
		await get_tree().process_frame
	# Snap if skipped
	if _skip_all:
		if _fading_in:
			_overlay_alpha = 1.0
			color.a = 1.0
			_fading_in = false
		if _fading_out:
			_overlay_alpha = 0.0
			color.a = 0.0
			_fading_out = false


# ═══════════════════════════════════════════════════════
#  CLEANUP
# ═══════════════════════════════════════════════════════

func _end_play() -> void:
	_playing = false
	_typing = false
	_kb_active = false
	_skip_all = false
	_skip_typing = false
	_advance = false
	_fading_in = false
	_fading_out = false

	_story_image.visible = false
	_image_box.visible = false
	_skip_btn.visible = false
	_continue_hint.visible = false
	_text_panel.visible = false

	# Release input
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Unpause only if we paused it
	if not _was_paused:
		get_tree().paused = false

	finished.emit()


# ═══════════════════════════════════════════════════════
#  INPUT
# ═══════════════════════════════════════════════════════

func _input(event: InputEvent) -> void:
	if not _playing:
		return

	if event.is_action_pressed("ui_cancel"):
		_skip_all = true
		return

	if event.is_action_pressed("ui_accept") or \
	   (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		if _typing:
			_skip_typing = true
		else:
			_advance = true


func _on_skip_button_pressed() -> void:
	_skip_all = true


# ═══════════════════════════════════════════════════════
#  READY
# ═══════════════════════════════════════════════════════

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

	color = Color(bg_color.r, bg_color.g, bg_color.b, 0.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = true

	_skip_btn.visible = false
	_continue_hint.visible = false
	_story_image.visible = false
	_image_box.visible = false
	_text_panel.visible = false

	_skip_btn.pressed.connect(_on_skip_button_pressed)
	_skip_btn.process_mode = ProcessMode.PROCESS_MODE_ALWAYS
