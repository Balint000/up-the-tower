extends Area2D
class_name Lever

signal lever_switched(on: bool)

@export var is_on: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null

var _player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_visual()


func _process(_delta: float) -> void:
	if not _player_in_range:
		return

	if Input.is_action_just_pressed("interact"):
		_toggle()


func _toggle() -> void:
	is_on = not is_on
	_update_visual()
	emit_signal("lever_switched", is_on)


func _update_visual() -> void:
	if sprite and sprite is AnimatedSprite2D:
		sprite.play("on" if is_on else "off")
	elif sprite and "frame" in sprite:
		sprite.frame = 1 if is_on else 0


func _on_body_entered(body: Node) -> void:
	if body is Entity and body.faction == "player":
		_player_in_range = true


func _on_body_exited(body: Node) -> void:
	if body is Entity and body.faction == "player":
		_player_in_range = false
