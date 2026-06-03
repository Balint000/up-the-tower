## @file test_base_player.gd
## @brief Unit tests for [BasePlayer] melee attack and damage/knockback handling.
##
## Covers: melee hit detection, health reduction on hit,
## HURT state entry, knockback velocity, and IDLE recovery.
##
## Note: BasePlayer overrides Entity.take_damage with an additional
## knockback parameter: take_damage(amount: int, knockback: Vector2 = Vector2.ZERO).
extends GutTest


## @brief Creates a [BasePlayer] instance with base stats in the scene tree.
## @return A fully configured [BasePlayer] ready for testing.
func _make_player() -> BasePlayer:
	var p := BasePlayer.new()
	add_child_autofree(p)

	p.apply_stats_from_dict({
		GameManager.KEY_HP: 100,
		GameManager.KEY_DMG: 15,
		GameManager.KEY_SPEED: 80.0,
	})

	p.melee_range = 50.0
	return p


## @brief Creates a [BaseEnemy] placed at [param pos] in the scene tree.
## @param pos World position to assign to the enemy.
## @return A [BaseEnemy] with reduced stats that the player can hit.
func _make_enemy_at(pos: Vector2) -> BaseEnemy:
	var e := BaseEnemy.new()
	add_child_autofree(e)
	e.global_position = pos

	e.apply_stats_from_dict({
		GameManager.KEY_HP: 50,
		GameManager.KEY_DMG: 5,
		GameManager.KEY_SPEED: 40.0,
	})

	return e

# Melee attack

## @brief A melee attack must reduce the health of an enemy within melee_range.
func test_player_melee_attack_hits_enemy_in_range() -> void:
	var player := _make_player()
	player.global_position = Vector2.ZERO

	var enemy := _make_enemy_at(player.global_position + Vector2(20.0, 0.0))

	await get_tree().process_frame

	var hp_before := enemy.health
	await player._do_melee_attack()
	assert_lt(enemy.health, hp_before,
		"Enemy health should decrease when player performs melee attack in range")


## @brief An enemy outside melee_range must not be damaged.
func test_player_melee_attack_misses_enemy_out_of_range() -> void:
	var player := _make_player()
	player.global_position = Vector2.ZERO

	var enemy := _make_enemy_at(player.global_position + Vector2(200.0, 0.0))

	await get_tree().process_frame

	var hp_before := enemy.health
	await player._do_melee_attack()
	assert_eq(enemy.health, hp_before,
		"Enemy health should not change when player attacks out of melee range")


# ---------------------------------------------------------------------------
# Damage and knockback
# ---------------------------------------------------------------------------

## @brief take_damage must reduce health, enter HURT state, and apply knockback to velocity.
func test_player_take_damage_sets_hurt_and_applies_knockback() -> void:
	var player := _make_player()
	player.global_position = Vector2.ZERO

	var knock := Vector2(100.0, -50.0)
	var hp_before := player.health

	player.take_damage(20, knock)

	assert_lt(player.health, hp_before,
		"Player health should decrease after taking damage")
	assert_eq(player._state, BasePlayer.State.HURT,
		"Player should enter HURT state right after taking damage")
	assert_eq(player.velocity, knock,
		"Player velocity should equal the knockback vector immediately after damage")

	# BasePlayer restores IDLE after ~0.2 s; wait 0.3 s to be safe.
	await get_tree().create_timer(0.3).timeout
	assert_eq(player._state, BasePlayer.State.IDLE,
		"Player should return to IDLE from HURT after the damage timeout")


## @brief Lethal damage must set is_alive to false and switch the player state to DEAD.
func test_lethal_damage_kills_player() -> void:
	var player := _make_player()
	player.take_damage(999)
	assert_false(player.is_alive,
		"Player should not be alive after lethal damage")
	assert_eq(player._state, BasePlayer.State.DEAD,
		"Player state should be DEAD after lethal damage")
