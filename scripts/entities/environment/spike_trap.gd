extends Area2D
class_name SpikeTrap

@export var damage: int = 5
@export var enabled: bool = true

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_state()


func set_enabled(value: bool) -> void:
	enabled = value
	_update_state()


func _update_state() -> void:
	monitoring = enabled
	if collision:
		collision.disabled = not enabled
	if sprite:
		sprite.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.5)


func _on_body_entered(body: Node) -> void:
	if not enabled:
		return
	if body is Entity and body.faction == "player":
		body.take_damage(damage)
