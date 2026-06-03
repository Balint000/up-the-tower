## @file test_level_manager.gd
## @brief Unit tests for the [LevelManager] autoload script.
##
## LevelManager is registered as an autoload singleton via its .tscn wrapper,
## so the script is instantiated directly with load+new() to keep tests isolated.
extends GutTest


## @brief Filesystem path to the [LevelManager] GDScript.
const LM_PATH := "res://scripts/autoload/Level_Manager.gd"


## @brief Creates a fresh, isolated [LevelManager] instance for the current test.
## @return A new [LevelManager] node added to the scene tree.
func _make_lm() -> Node:
	var lm: Node = load(LM_PATH).new()
	add_child_autofree(lm)
	return lm

# Default state

## @brief Level 0 must always be unlocked after construction.
func test_level_zero_is_unlocked_by_default() -> void:
	var lm := _make_lm()
	assert_true(lm.is_unlocked(0), "Level 0 should be unlocked by default")

## @brief A freshly constructed LevelManager must report no save data.
func test_no_save_data_initially() -> void:
	var lm := _make_lm()
	assert_false(lm.has_save_data(), "Initially there should be no save data")

## @brief Any level index beyond 0 must be locked after construction.
func test_arbitrary_level_is_locked_by_default() -> void:
	var lm := _make_lm()
	assert_false(lm.is_unlocked(5), "Level 5 should be locked by default")

# unlock_level

## @brief unlock_level must make the target level accessible.
func test_unlock_level_makes_it_accessible() -> void:
	var lm := _make_lm()
	lm.unlock_level(1)
	assert_true(lm.is_unlocked(1),
		"Level 1 should be unlocked after calling unlock_level(1)")

## @brief After unlocking any level beyond 0, has_save_data must return true.
func test_has_save_data_after_unlocking_level() -> void:
	var lm := _make_lm()
	lm.unlock_level(1)
	assert_true(lm.has_save_data(),
		"has_save_data should be true after unlocking level 1")

## @brief Unlocking multiple levels must make every one of them accessible.
func test_unlock_multiple_levels() -> void:
	var lm := _make_lm()
	lm.unlock_level(1)
	lm.unlock_level(2)
	assert_true(lm.is_unlocked(1), "Level 1 should be unlocked")
	assert_true(lm.is_unlocked(2), "Level 2 should be unlocked")

# restore_unlocked_levels

## @brief Level 0 must remain unlocked even if absent from the restore list.
func test_restore_always_keeps_level_zero() -> void:
	var lm := _make_lm()
	lm.restore_unlocked_levels([2, 3])
	assert_true(lm.is_unlocked(0),
		"Level 0 must always remain unlocked after restore")

## @brief Levels included in the restore list must be accessible afterwards.
func test_restore_unlocks_specified_levels() -> void:
	var lm := _make_lm()
	lm.restore_unlocked_levels([0, 2])
	assert_true(lm.is_unlocked(2),
		"Level 2 should be unlocked after restore_unlocked_levels([0, 2])")

## @brief Levels NOT in the restore list must remain locked after a restore call.
func test_restore_does_not_unlock_extra_levels() -> void:
	var lm := _make_lm()
	lm.restore_unlocked_levels([0, 1])
	assert_false(lm.is_unlocked(2),
		"Level 2 should remain locked when not included in the restore list")
