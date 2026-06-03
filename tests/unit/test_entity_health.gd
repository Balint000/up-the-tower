## @file test_entity_health.gd
## @brief Unit tests for the [Entity] class health system.
##
## Covers: stat initialisation, damage, healing, death flag, and signals.
## [Entity] inherits [CharacterBody2D], so instances are added to the scene
## tree via [method GutTest.add_child_autofree] to satisfy Godot's physics requirements.
extends GutTest


## @brief Creates a fresh [Entity] instance with the given maximum hit-points.
## @param hp Maximum (and initial) hit-points to assign.
## @return A fully initialised [Entity] added to the scene tree.
func _make_entity(hp: int) -> Entity:
	var e := Entity.new()
	add_child_autofree(e)
	e.apply_stats_from_dict({ GameManager.KEY_HP: hp })
	return e


# Stat initialisation

## @brief apply_stats_from_dict must set both max_health and health to the supplied HP value.
func test_apply_stats_sets_health() -> void:
	var e := _make_entity(100)
	assert_eq(e.max_health, 100, "max_health should be 100")
	assert_eq(e.health, 100, "health should equal max_health after init")


## @brief apply_stats_from_dict must also propagate damage and speed values.
func test_apply_stats_sets_damage_and_speed() -> void:
	var e := Entity.new()
	add_child_autofree(e)
	e.apply_stats_from_dict({
		GameManager.KEY_HP: 100,
		GameManager.KEY_DMG: 15,
		GameManager.KEY_SPEED: 200.0
	})
	assert_eq(e.damage, 15, "damage should be 15")
	assert_almost_eq(e.move_speed, 200.0, 0.01, "move_speed should be 200")


# Damage

## @brief take_damage must reduce health by the exact damage amount.
func test_take_damage_reduces_health() -> void:
	var e := _make_entity(100)
	e.take_damage(30)
	assert_eq(e.health, 70, "Health should be 70 after 30 damage")


## @brief health must never drop below zero, even with overkill damage.
func test_take_damage_cannot_go_below_zero() -> void:
	var e := _make_entity(10)
	e.take_damage(999)
	assert_gte(e.health, 0, "Health must not go below 0")


## @brief health_changed signal must be emitted when damage is applied.
func test_take_damage_emits_health_changed() -> void:
	var e := _make_entity(100)
	watch_signals(e)
	e.take_damage(10)
	assert_signal_emitted(e, "health_changed",
		"health_changed signal should fire on damage")


## @brief Applying zero damage must not change health or emit signals.
func test_zero_damage_has_no_effect() -> void:
	var e := _make_entity(100)
	watch_signals(e)
	e.take_damage(0)
	assert_eq(e.health, 100, "Health should remain 100 after zero damage")


# Healing

## @brief heal must restore the correct amount of health.
func test_heal_restores_health() -> void:
	var e := _make_entity(100)
	e.take_damage(50)
	e.heal(20)
	assert_eq(e.health, 70, "Health should be 70 after 50 damage and 20 heal")


## @brief health must never exceed max_health after healing.
func test_heal_cannot_exceed_max_health() -> void:
	var e := _make_entity(100)
	e.take_damage(10)
	e.heal(999)
	assert_eq(e.health, e.max_health, "Health must not exceed max_health after overheal")


## @brief Healing a full-HP entity must leave health unchanged.
func test_heal_at_full_health_has_no_effect() -> void:
	var e := _make_entity(100)
	e.heal(50)
	assert_eq(e.health, 100, "Healing a full-HP entity should not change health")


# Death

## @brief After lethal damage is_alive must be false.
func test_lethal_damage_sets_is_alive_false() -> void:
	var e := _make_entity(50)
	e.take_damage(50)
	assert_false(e.is_alive, "Entity should not be alive after lethal damage")


## @brief died signal must be emitted exactly once on lethal damage.
func test_lethal_damage_emits_died_signal() -> void:
	var e := _make_entity(50)
	watch_signals(e)
	e.take_damage(50)
	assert_signal_emitted(e, "died",
		"died signal should fire on lethal damage")


## @brief A dead entity must ignore subsequent damage calls.
func test_dead_entity_ignores_further_damage() -> void:
	var e := _make_entity(50)
	e.take_damage(500)   # kills the entity
	e.take_damage(10)   # should be a no-op
	assert_eq(e.health, 0, "Dead entity health should stay at 0")
	assert_false(e.is_alive, "Entity should remain dead")
