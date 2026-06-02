extends CanvasLayer

@export_group("Animation")
@export var slide_distance: float = 120.0
@export var slide_speed: float = 700.0
@export var fade_speed: float = 6.0
@export var display_time: float = 2.5

@onready var _panel: PanelContainer = $NotificationPanel
@onready var _label: Label = $NotificationPanel/MarginContainer/HBoxContainer/Message
@onready var _icon: TextureRect = $NotificationPanel/MarginContainer/HBoxContainer/Icon

var _queue: Array[Dictionary] = []

var _active := false
var _showing := false
var _timer := 0.0

var _target_y := 0.0
var _hidden_y := 0.0

func _ready() -> void:
	process_mode = ProcessMode.PROCESS_MODE_ALWAYS

	await get_tree().process_frame

	_target_y = _panel.position.y
	_hidden_y = _target_y - slide_distance

	_panel.position.y = _hidden_y
	_panel.modulate.a = 0.0

func _process(delta: float) -> void:
	if not _active:
		if _queue.size() > 0:
			_start_next()
		return

	if _showing:
		_panel.position.y = move_toward(
			_panel.position.y,
			_target_y,
			slide_speed * delta
		)

		_panel.modulate.a = move_toward(
			_panel.modulate.a,
			1.0,
			fade_speed * delta
		)

		_timer -= delta

		if _timer <= 0.0:
			_showing = false

	else:
		_panel.position.y = move_toward(
			_panel.position.y,
			_hidden_y,
			slide_speed * delta
		)

		_panel.modulate.a = move_toward(
			_panel.modulate.a,
			0.0,
			fade_speed * delta
		)

		if _panel.modulate.a <= 0.01:
			_active = false

func show_message(
	text: String,
	icon: Texture2D = null,
	duration: float = -1.0
) -> void:

	_queue.append({
		"text": text,
		"icon": icon,
		"time": duration
	})

func _start_next() -> void:
	var data: Dictionary = _queue.pop_front()

	_label.text = data["text"]

	if data["icon"] != null:
		_label.text = str(data["text"])
		_icon.visible = true
	else:
		_icon.visible = false

	_timer = display_time

	if data["time"] > 0:
		_timer = float(data["time"])

	_showing = true
	_active = true
