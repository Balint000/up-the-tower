extends GutTest
## test_base_enemy.gd
## Unit tesztek a BaseEnemy állapotgépéhez: mozgás, aggro, támadás, sebződés.

## Segédfüggvény: létrehoz egy BaseEnemy példányt a scene tree-ben, alap statokkal.
func _make_enemy() -> BaseEnemy:
	var e := BaseEnemy.new()
	add_child_autofree(e)

	# Statok az Entity.apply_stats_from_dict API szerint:
	e.apply_stats_from_dict({
		GameManager.KEY_HP:    100,
		GameManager.KEY_DMG:   10,
		GameManager.KEY_SPEED: 60.0,
	})

	# Determinisztikusabb viselkedés kedvéért explicit beállítjuk a sebességeket / hatótávokat.
	e.patrol_speed    = 40.0
	e.chase_speed     = 80.0
	e.aggro_range     = 140.0
	e.lose_aggro_range = 220.0
	e.attack_range    = 35.0

	return e


## Segédfüggvény: egyszerű BasePlayer, aki sebezhető és a scene tree-ben van.
func _make_player_at(pos: Vector2) -> BasePlayer:
	var p := BasePlayer.new()
	add_child_autofree(p)
	p.global_position = pos

	p.apply_stats_from_dict({
		GameManager.KEY_HP:    100,
		GameManager.KEY_DMG:   5,
		GameManager.KEY_SPEED: 80.0,
	})

	return p


# ---------------------------------------------------------------------------
# Aggro és mozgás
# ---------------------------------------------------------------------------

## Az enemy PATROL-ból AGGRO-ba vált, ha a player az aggro_range-en belülre kerül.
func test_enemy_enters_aggro_when_player_in_range() -> void:
	var enemy := _make_enemy()
	assert_eq(enemy._state, BaseEnemy.State.PATROL, "Enemy should start in PATROL state")

	var player := _make_player_at(enemy.global_position + Vector2(enemy.aggro_range - 5.0, 0.0))

	# Várunk egy frame-et, hogy a BaseEnemy _find_player() megtalálja a player csoportot.
	await get_tree().process_frame

	enemy._physics_process(0.016)
	assert_eq(enemy._state, BaseEnemy.State.AGGRO,
		"Enemy should switch from PATROL to AGGRO when player is within aggro_range")


## AGGRO módban az enemy a player felé mozog chase_speed sebességgel.
func test_enemy_moves_towards_player_in_aggro() -> void:
	var enemy := _make_enemy()
	var player := _make_player_at(enemy.global_position + Vector2(100.0, 0.0))

	await get_tree().process_frame

	enemy._state = BaseEnemy.State.AGGRO
	enemy._physics_process(0.016)

	assert_gt(enemy.velocity.x, 0.0,
		"Enemy should move right towards the player when player is to the right")
	assert_almost_eq(enemy.velocity.x, enemy.chase_speed, 0.01,
		"Enemy horizontal speed in AGGRO should be close to chase_speed")


# ---------------------------------------------------------------------------
# Támadás
# ---------------------------------------------------------------------------

## Ha a player attack_range-en belül van és nincs cooldown, az enemy támadása sebzi a playert.
func test_enemy_attack_damages_player() -> void:
	var enemy := _make_enemy()
	# Player nagyon közel az enemyhez, biztosan attack_range + buffer belül.
	var player := _make_player_at(enemy.global_position + Vector2(5.0, 0.0))

	await get_tree().process_frame

	enemy._state = BaseEnemy.State.AGGRO
	enemy._attack_timer = 0.0

	var hp_before := player.health
	await enemy._do_attack()
	assert_lt(player.health, hp_before,
		"Player health should decrease after enemy melee attack")


# ---------------------------------------------------------------------------
# Sebződés és halál
# ---------------------------------------------------------------------------

## Sebződéskor az enemy HURT állapotba kerül, majd a hurt időzítő után visszatér AGGRO-ba.
func test_enemy_damage_sets_hurt_and_returns_to_aggro() -> void:
	var enemy := _make_enemy()
	enemy._state = BaseEnemy.State.AGGRO

	enemy.take_damage(10)
	assert_eq(enemy._state, BaseEnemy.State.HURT,
		"Enemy should enter HURT state right after taking damage")

	# A BaseEnemy.take_damage 0.4s után visszaállítja AGGRO-ra, ha életben maradt.
	await get_tree().create_timer(0.5).timeout
	assert_eq(enemy._state, BaseEnemy.State.AGGRO,
		"Enemy should return to AGGRO after hurt timer")


## Lethal sebzés után az enemy DEAD állapotba kerül és is_alive false lesz.
func test_lethal_damage_sets_dead_and_is_alive_false() -> void:
	var enemy := _make_enemy()

	enemy.take_damage(999)
	assert_false(enemy.is_alive, "Enemy should not be alive after lethal damage")
	assert_eq(enemy._state, BaseEnemy.State.DEAD,
		"Enemy state should be DEAD after lethal damage")
