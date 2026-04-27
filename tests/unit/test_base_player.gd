extends GutTest
## test_base_player.gd
## Unit tesztek a BasePlayer melee támadására és sebződésére/knockback-jére.

## Segédfüggvény: egyszerű BasePlayer példány a scene tree-ben.
func _make_player() -> BasePlayer:
	var p := BasePlayer.new()
	add_child_autofree(p)

	p.apply_stats_from_dict({
		GameManager.KEY_HP:    100,
		GameManager.KEY_DMG:   15,
		GameManager.KEY_SPEED: 80.0,
	})

	# Biztonság kedvéért nézzen jobbra és kapjon alap melee range-et.
	p.melee_range = 50.0

	return p


## Segédfüggvény: egyszerű BaseEnemy, akit a player le tud csapni melee-vel.
func _make_enemy_at(pos: Vector2) -> BaseEnemy:
	var e := BaseEnemy.new()
	add_child_autofree(e)
	e.global_position = pos

	e.apply_stats_from_dict({
		GameManager.KEY_HP:    50,
		GameManager.KEY_DMG:   5,
		GameManager.KEY_SPEED: 40.0,
	})

	return e


# ---------------------------------------------------------------------------
# Melee támadás
# ---------------------------------------------------------------------------

## A BasePlayer melee támadása sebzi a közelben álló ellenséget (enemies csoport).
func test_player_melee_attack_hits_enemy_in_range() -> void:
	var player := _make_player()
	player.global_position = Vector2.ZERO

	# Ellenség a melee_range-en belül.
	var enemy := _make_enemy_at(player.global_position + Vector2(20.0, 0.0))

	await get_tree().process_frame

	var hp_before := enemy.health
	await player._do_melee_attack()
	assert_lt(enemy.health, hp_before,
		"Enemy health should decrease when player performs melee attack in range")


# ---------------------------------------------------------------------------
# Sebződés és knockback
# ---------------------------------------------------------------------------

## Sebződéskor a BasePlayer HURT állapotba kerül, velocity-re ráíródik a knockback,
## majd kis idő után visszatér IDLE állapotba (ha életben maradt).
func test_player_take_damage_sets_hurt_and_applies_knockback() -> void:
	var player := _make_player()
	player.global_position = Vector2.ZERO

	var knock := Vector2(100.0, -50.0)
	var hp_before := player.health

	player.take_damage(20, knock)

	# Azonnali elvárások: HP csökken, állapot HURT, velocity beáll a knockback-re.
	assert_lt(player.health, hp_before, "Player health should decrease after taking damage")
	assert_eq(player._state, BasePlayer.State.HURT,
		"Player should enter HURT state right after taking damage")
	assert_eq(player.velocity, knock,
		"Player velocity should equal knockback vector right after taking damage")

	# A BasePlayer.take_damage ~0.2s után visszaállítja az állapotot (ha még HURT).
	await get_tree().create_timer(0.3).timeout
	assert_eq(player._state, BasePlayer.State.IDLE,
		"Player should return to IDLE from HURT after damage timeout when still alive")
