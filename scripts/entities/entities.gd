extends CharacterBody2D
class_name Entity

var max_health: int   = 1
var health: int       = max_health
var is_alive: bool    = true
var damage: int       = 1
var move_speed: float = 100.0
var gravity: float    = 1200.0

var entity_name: String = ""
var faction: String     = "neutral"

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal stats_changed(entity: Entity)
signal health_changed(entity: Entity)  ## alias – tesztek és HUD erre figyelnek
signal died(entity: Entity)            ## halálkor emittálódik

# ---------------------------------------------------------------------------
func _ready() -> void:
	pass

func register_groups_from_faction() -> void:
	match faction:
		"player": add_to_group("player")
		"enemy":  add_to_group("enemies")

func apply_stats_from_dict(stats: Dictionary) -> void:
	if stats.has(GameManager.KEY_HP):
		max_health = int(stats[GameManager.KEY_HP])
		health     = max_health
	if stats.has(GameManager.KEY_DMG):
		damage = int(stats[GameManager.KEY_DMG])
	if stats.has(GameManager.KEY_SPEED):
		move_speed = float(stats[GameManager.KEY_SPEED])

func take_damage(amount: int) -> void:
	if not is_alive:
		return
	health = max(health - amount, 0)
	emit_signal("stats_changed", self)
	emit_signal("health_changed", self)
	if health == 0:
		die()

func heal(amount: int) -> void:
	if not is_alive:
		return
	health = min(health + amount, max_health)
	emit_signal("stats_changed", self)
	emit_signal("health_changed", self)

func die() -> void:
	if not is_alive:
		return
	is_alive = false
	emit_signal("died", self)
