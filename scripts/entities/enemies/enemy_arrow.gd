extends Area2D

var _velocity: Vector2 = Vector2.ZERO
var _damage: int = 10

func setup(from: Vector2, direction: Vector2, dmg: int, speed: float = 220.0) -> void:
	global_position  = from
	_velocity        = direction * speed
	_damage          = dmg

	# A sprite forgatása menet irányba
	rotation = direction.angle()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# 4 másodperc után magától eltűnik
	await get_tree().create_timer(4.0).timeout
	if is_instance_valid(self):
		queue_free()

func _physics_process(delta: float) -> void:
	position += _velocity * delta

func _on_body_entered(body: Node) -> void:
	if body is Entity and body.faction == "player":
		body.take_damage(_damage, _velocity.normalized() * 100.0)
		queue_free()
	elif body is TileMapLayer or body is StaticBody2D:
		queue_free()

func _on_area_entered(_area: Area2D) -> void:
	pass  # kibővíthető shield-del való ütközésre
