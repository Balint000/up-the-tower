extends GutTest
## test_entity_health.gd
## Unit tesztek az Entity osztály életerő rendszeréhez.
##
## Lefedi: stat beállítás, sebzés, gyógyítás, halál, signalok.
## Az Entity CharacterBody2D leszármazott, ezért add_child_autofree()-vel
## adjuk a scene tree-be.


## Segédfüggvény: friss Entity példányt hoz létre adott max HP-val.
func _make_entity(hp: int) -> Entity:
	var e = Entity.new()
	add_child_autofree(e)
	e.apply_stats_from_dict({ GameManager.KEY_HP: hp })
	return e


# --- Stat beállítás ---

## Az apply_stats_from_dict helyesen állítja be a max és az aktuális HP-t
func test_apply_stats_sets_health() -> void:
	var e = _make_entity(100)
	assert_eq(e.max_health, 100, "max_health should be 100")
	assert_eq(e.health, 100, "health should equal max_health after init")


## A sebesség és sebzés is helyesen töltődik be
func test_apply_stats_sets_damage_and_speed() -> void:
	var e = Entity.new()
	add_child_autofree(e)
	e.apply_stats_from_dict({
		GameManager.KEY_HP:    100,
		GameManager.KEY_DMG:   15,
		GameManager.KEY_SPEED: 200.0
	})
	assert_eq(e.damage, 15, "damage should be 15")
	assert_almost_eq(e.move_speed, 200.0, 0.01, "move_speed should be 200")


# --- Sebzés ---

## Sebzés csökkenti az életerőt a várt mértékben
func test_take_damage_reduces_health() -> void:
	var e = _make_entity(100)
	e.take_damage(30)
	assert_eq(e.health, 70, "Health should be 70 after 30 damage")


## Az életerő nem mehet 0 alá, még túlsebzés esetén sem
func test_take_damage_cannot_go_below_zero() -> void:
	var e = _make_entity(10)
	e.take_damage(999)
	assert_gte(e.health, 0, "Health must not go below 0")


## Sebzéskor a health_changed signal ki kell adódjon
func test_take_damage_emits_health_changed() -> void:
	var e = _make_entity(100)
	watch_signals(e)
	e.take_damage(10)
	assert_signal_emitted(e, "health_changed", "health_changed should fire on damage")


# --- Gyógyítás ---

## Gyógyítás visszaadja az elveszett életerőt
func test_heal_restores_health() -> void:
	var e = _make_entity(100)
	e.take_damage(50)
	e.heal(20)
	assert_eq(e.health, 70, "Health should be 70 after 50 damage and 20 heal")


## Gyógyítás nem lépheti túl a max HP-t
func test_heal_cannot_exceed_max_health() -> void:
	var e = _make_entity(100)
	e.take_damage(10)
	e.heal(999)
	assert_eq(e.health, e.max_health, "Health must not exceed max_health after healing")


# --- Halál ---

## Halálos sebzés esetén az entitás nem lehet életben
func test_lethal_damage_sets_is_alive_false() -> void:
	var e = _make_entity(50)
	e.take_damage(50)
	# A queue_free() deferred, az is_alive flag azonnal frissül
	assert_false(e.is_alive, "Entity should not be alive after lethal damage")


## Halálos sebzéskor a died signal ki kell adódjon
func test_lethal_damage_emits_died_signal() -> void:
	var e = _make_entity(50)
	watch_signals(e)
	e.take_damage(50)
	assert_signal_emitted(e, "died", "died signal should fire on lethal damage")


## Halott entitás nem vehet fel további sebzést
func test_dead_entity_ignores_damage() -> void:
	var e = _make_entity(50)
	# Kézzel állítjuk halottra a queue_free() elkerülésére
	e.is_alive = false
	e.health = 0
	e.take_damage(30)
	assert_eq(e.health, 0, "Dead entity should not take further damage")
