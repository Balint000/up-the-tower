## Base class for all living entities in the game (players, enemies, neutral).
##
## Entity is the root of the character hierarchy. It stores core stats such as
## health, damage, speed, and gravity, and exposes the fundamental methods
## [method take_damage], [method heal], and [method die].
##
## Subclasses should call [method super._ready] and, where relevant,
## [method register_groups_from_faction] so that scene-tree group
## membership is consistent for hit-detection queries.
extends CharacterBody2D
class_name Entity

## Maximum hit-points. Set via [method apply_stats_from_dict] or directly.
var max_health: int = 1
## Current hit-points. Clamped to [0, max_health] by [method take_damage] and [method heal].
var health: int = max_health
## Whether this entity is still alive. Set to [code]false[/code] permanently by [method die].
var is_alive: bool = true
## Base melee / contact damage dealt to other entities.
var damage: int = 1
## Horizontal movement speed in pixels per second.
var move_speed: float = 100.0
## Downward gravitational acceleration applied while not on the floor (px/s²).
var gravity: float = 1200.0

## Human-readable identifier; populated from [member CharacterResource.character_id].
var entity_name: String = ""
## Faction tag used for group registration and friendly-fire checks.
## Supported values: [code]"player"[/code], [code]"enemy"[/code], [code]"neutral"[/code].
var faction: String = "neutral"

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------

## Emitted whenever any stat changes (HP, DMG, SPD).
## The HUD and other systems should connect to this for live stat updates.
signal stats_changed(entity: Entity)

## Alias for [signal stats_changed], emitted specifically on health changes.
## Tests and the HUD health-bar listen to this signal.
signal health_changed(entity: Entity)

## Emitted exactly once when this entity's health reaches zero and [method die] runs.
signal died(entity: Entity)

# ---------------------------------------------------------------------------

## Standard Godot lifecycle callback. Subclasses must call [code]super._ready()[/code].
func _ready() -> void:
	pass

## Adds this entity to the correct scene-tree group based on [member faction].
## Call this from [method _ready] after setting the faction value.
func register_groups_from_faction() -> void:
	match faction:
		"player": add_to_group("player")
		"enemy":  add_to_group("enemies")

## Applies HP, damage, and speed values from a dictionary.
## Keys are resolved via [constant GameManager.KEY_HP], [constant GameManager.KEY_DMG],
## and [constant GameManager.KEY_SPEED]; missing keys are silently skipped.
## [param stats] Dictionary that may contain HP, DMG, and/or SPEED entries.
func apply_stats_from_dict(stats: Dictionary) -> void:
	if stats.has(GameManager.KEY_HP):
		max_health = int(stats[GameManager.KEY_HP])
		health     = max_health
	if stats.has(GameManager.KEY_DMG):
		damage = int(stats[GameManager.KEY_DMG])
	if stats.has(GameManager.KEY_SPEED):
		move_speed = float(stats[GameManager.KEY_SPEED])

## Subtracts [param amount] from [member health], clamping at 0.
## Emits [signal stats_changed] and [signal health_changed].
## Calls [method die] automatically when health reaches zero.
## Does nothing if the entity is already dead.
func take_damage(amount: int) -> void:
	if not is_alive:
		return
	health = max(health - amount, 0)
	emit_signal("stats_changed", self)
	emit_signal("health_changed", self)
	if health == 0:
		die()

## Adds [param amount] to [member health], clamping at [member max_health].
## Emits [signal stats_changed] and [signal health_changed].
## Does nothing if the entity is already dead.
func heal(amount: int) -> void:
	if not is_alive:
		return
	health = min(health + amount, max_health)
	emit_signal("stats_changed", self)
	emit_signal("health_changed", self)

## Marks the entity as dead and emits [signal died].
## Idempotent: calling it more than once has no effect.
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	emit_signal("died", self)
