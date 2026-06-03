## @file test_base_enemy.gd
## @brief Unit tests for the [BaseEnemy] finite state machine.
##
## Covers: PATROL→AGGRO transition, chase movement, melee attack damage,
## HURT state recovery, and death from lethal damage.
extends GutTest


## @brief Creates a [BaseEnemy] instance with deterministic stats in the scene tree.
## @return A fully configured [BaseEnemy] ready for testing.
func _make_enemy() -> BaseEnemy:
	var e := BaseEnemy.new()
	add_child_autofree(e)

	e.apply_stats_from_dict({
		GameManager.KEY_HP: 100,
		GameManager.KEY_DMG: 10,
		GameManager.KEY_SPEED: 60.0,
	})

	# Override exported properties for deterministic test behaviour.
	e.patrol_speed = 40.0
	e.chase_speed = 80.0
	e.aggro_range = 140.0
	e.lose_aggro_range = 220.0
	e.attack_range = 35.0

	return e


## @brief Creates a minimal [BasePlayer] placed at [param pos] in the scene tree.
## @param pos World position to assign to the player.
## @return A [BasePlayer] registered in the "player" group.
func _make_player_at(pos: Vector2) -> BasePlayer:
	var p := BasePlayer.new()
	add_child_autofree(p)
	p.global_position = pos

	p.apply_stats_from_dict({
		GameManager.KEY_HP: 100,
		GameManager.KEY_DMG: 5,
		GameManager.KEY_SPEED: 80.0,
	})

	return p

# Aggro and movement

## @brief Enemy must transition from PATROL to AGGRO when the player enters aggro_range.
func test_enemy_enters_aggro_when_player_in_range() -> void:
	var enemy := _make_enemy()
	assert_eq(enemy._state, BaseEnemy.State.PATROL,
		"Enemy should start in PATROL state")

	var player := _make_player_at(
		enemy.global_position + Vector2(enemy.aggro_range - 5.0, 0.0)
	)

	# Wait one frame so _find_player() resolves the group query.
	await get_tree().process_frame

	enemy._physics_process(0.016)
	assert_eq(enemy._state, BaseEnemy.State.AGGRO,
		"Enemy should switch from PATROL to AGGRO when player is within aggro_range")


## @brief In AGGRO state the enemy must move toward the player at chase_speed.
func test_enemy_moves_towards_player_in_aggro() -> void:
	var enemy := _make_enemy()
	var player := _make_player_at(enemy.global_position + Vector2(100.0, 0.0))

	await get_tree().process_frame

	enemy._state = BaseEnemy.State.AGGRO
	enemy._physics_process(0.016)

	assert_gt(enemy.velocity.x, 0.0,
		"Enemy should move right towards the player when player is to the right")
	assert_almost_eq(enemy.velocity.x, enemy.chase_speed, 0.01,
		"Enemy horizontal speed in AGGRO should match chase_speed")


## @brief Enemy must return to PATROL when the player moves beyond lose_aggro_range.
func test_enemy_returns_to_patrol_when_player_leaves_range() -> void:
	var enemy := _make_enemy()
	var player := _make_player_at(
		enemy.global_position + Vector2(enemy.lose_aggro_range + 50.0, 0.0)
	)

	await get_tree().process_frame

	enemy._state = BaseEnemy.State.AGGRO
	enemy._physics_process(0.016)
	assert_eq(enemy._state, BaseEnemy.State.PATROL,
		"Enemy should return to PATROL when player is beyond lose_aggro_range")

# Attack

## @brief A melee attack must reduce the player's health when within attack_range.
func test_enemy_attack_damages_player() -> void:
	var enemy := _make_enemy()
	var player := _make_player_at(enemy.global_position + Vector2(5.0, 0.0))

	await get_tree().process_frame

	enemy._state = BaseEnemy.State.AGGRO
	enemy._attack_timer = 0.0

	var hp_before := player.health
	await enemy._do_attack()
	assert_lt(player.health, hp_before,
		"Player health should decrease after enemy melee attack")

# Damage reactions and death

## @brief take_damage sets HURT; enemy recovers to a non-HURT state.
func test_enemy_damage_sets_hurt_and_recovers() -> void:
	var enemy := _make_enemy()
	enemy._state = BaseEnemy.State.AGGRO

	enemy.take_damage(10)
	assert_eq(enemy._state, BaseEnemy.State.HURT,
		"Enemy should enter HURT state immediately after taking damage")

	await get_tree().create_timer(1.0).timeout
	assert_ne(enemy._state, BaseEnemy.State.HURT,
		"Enemy should leave HURT state after the recovery timer expires")


## @brief Lethal damage must set is_alive to false and transition to DEAD.
func test_lethal_damage_sets_dead_and_is_alive_false() -> void:
	var enemy := _make_enemy()

	enemy.take_damage(999)
	assert_false(enemy.is_alive,
		"Enemy should not be alive after lethal damage")
	assert_eq(enemy._state, BaseEnemy.State.DEAD,
		"Enemy state should be DEAD after lethal damage")
