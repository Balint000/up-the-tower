extends GutTest
## test_level_manager.gd
## Unit tesztek a LevelManager szkripthez.
##
## MEGJEGYZÉS: A LevelManager autoload szingleton, ezért a szkriptet
## load() + new() segítségével töltjük be, hogy ne a globális példányt
## módosítsuk a tesztek alatt.


# A szkript elérési útja – innen hozzuk létre az izolált példányt
const LM_PATH := "res://scripts/autoload/Level_Manager.gd"


## Segédfüggvény: friss LevelManager példányt hoz létre a teszthez.
## Az add_child_autofree() gondoskodik a cleanup-ról a teszt végén.
func _make_lm() -> Node:
	var lm = load(LM_PATH).new()
	add_child_autofree(lm)
	return lm


# --- Alapállapot tesztek ---

## A 0. szintnek mindig feloldottnak kell lennie – ezt a konstruktor garantálja
func test_level_zero_is_unlocked_by_default() -> void:
	var lm = _make_lm()
	assert_true(lm.is_unlocked(0), "Level 0 should be unlocked by default")


## Kezdetben nincs mentési adat, csak a 0. szint van feloldva
func test_no_save_data_initially() -> void:
	var lm = _make_lm()
	assert_false(lm.has_save_data(), "Initially there should be no save data")


# --- unlock_level tesztek ---

## Egy szint feloldása után az is_unlocked() true-t kell visszaadjon
func test_unlock_level_makes_it_accessible() -> void:
	var lm = _make_lm()
	lm.unlock_level(1)
	assert_true(lm.is_unlocked(1), "Level 1 should be unlocked after unlock_level(1)")


## Ha legalább egy szint (0-on kívül) fel van oldva, van mentési adat
func test_has_save_data_after_unlocking_level() -> void:
	var lm = _make_lm()
	lm.unlock_level(1)
	assert_true(lm.has_save_data(), "has_save_data should be true after unlocking level 1")


## Soha nem feloldott szintre false-t kell visszaadni
func test_locked_level_returns_false() -> void:
	var lm = _make_lm()
	assert_false(lm.is_unlocked(5), "Level 5 should not be unlocked by default")


# --- restore_unlocked_levels tesztek ---

## A 0. szint még akkor is megmarad feloldottnak, ha a restore-ban nincs benne
func test_restore_always_keeps_level_zero() -> void:
	var lm = _make_lm()
	lm.restore_unlocked_levels([2, 3])
	assert_true(lm.is_unlocked(0), "Level 0 must always remain unlocked after restore")


## A visszaállított szintek valóban feloldottak lesznek
func test_restore_unlocks_specified_levels() -> void:
	var lm = _make_lm()
	lm.restore_unlocked_levels([0, 2])
	assert_true(lm.is_unlocked(2), "Level 2 should be unlocked after restore")
