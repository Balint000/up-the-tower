## Area2D-based damage trigger placed in the environment.
##
## Deals a fixed amount of damage to any player-faction [Entity] that
## walks into the area. Can be toggled on and off at runtime via
## [method set_enabled]; visual opacity reflects the current enabled state.
extends Area2D
class_name SpikeTrap

## Damage applied to the player on each contact event.
@export var damage: int = 5
## Whether the trap is currently active. When [code]false[/code] the
## collision shape is disabled and no damage is dealt.
@export var enabled: bool = true

## Collision shape of the trap. Enabled/disabled via [method set_enabled].
@onready var collision: CollisionShape2D = $CollisionShape2D
## Optional sprite. Dimmed to 50 % opacity when the trap is disabled.
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null

## Connects the body-entered signal and applies the initial enabled state.
func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_state()


## Enables or disables the trap at runtime and updates visuals accordingly.
## [param value] Pass [code]true[/code] to activate, [code]false[/code] to deactivate.
func set_enabled(value: bool) -> void:
	enabled = value
	_update_state()


## Syncs [member Area2D.monitoring], the collision shape, and sprite opacity
## to the current [member enabled] value.
func _update_state() -> void:
	monitoring = enabled
	if collision:
		collision.disabled = not enabled
	if sprite:
		# Full opacity when active; dimmed when disabled to hint at the inactive state.
		sprite.modulate = Color(1, 1, 1, 1) if enabled else Color(1, 1, 1, 0.5)


## Deals [member damage] to any player-faction [Entity] that enters the area.
## Silently ignores non-Entity bodies and enemies.
## [param body] The [Node] that entered the trap area.
func _on_body_entered(body: Node) -> void:
	if not enabled:
		return
	if body is Entity and body.faction == "player":
		body.take_damage(damage)
