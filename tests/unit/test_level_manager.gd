## @file test_level_manager.gd
## @brief Unit tests for level unlock logic via GameManager.runtime_data.
##
## LevelManager cannot be instantiated standalone because its @onready vars
## require UILayer child nodes from the .tscn scene. Instead, the unlock
## state stored in GameManager.runtime_data is tested directly, which is
## the actual persistent data that matters.
extends GutTest

## @brief Snapshot saved before each test to prevent state pollution.
var _saved_unlocked: Array = []

## @brief Saves the current unlocked levels before each test.
func before_each() -> void:
	_saved_unlocked = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS].duplicate()

## @brief Restores the original unlocked levels after each test.
func after_each() -> void:
	GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS] = _saved_unlocked.duplicate()

# --- Default state ---

## @brief Level 0 must be present in the default runtime_data.
func test_level_zero_is_unlocked_by_default() -> void:
	var unlocked: Array = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS]
	assert_true(unlocked.has(0), "Level 0 should be unlocked by default")

## @brief An arbitrary level beyond 0 must not be in the default unlock list.
func test_arbitrary_level_is_locked_by_default() -> void:
	var unlocked: Array = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS]
	assert_false(unlocked.has(5), "Level 5 should be locked by default")

# --- Manual unlock via runtime_data ---

## @brief Appending a level index must make it accessible.
func test_unlock_level_makes_it_accessible() -> void:
	GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS].append(1)
	var unlocked: Array = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS]
	assert_true(unlocked.has(1), "Level 1 should be unlocked after appending it")

## @brief Unlocking multiple levels must make every one of them accessible.
func test_unlock_multiple_levels() -> void:
	GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS].append(1)
	GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS].append(2)
	var unlocked: Array = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS]
	assert_true(unlocked.has(1), "Level 1 should be unlocked")
	assert_true(unlocked.has(2), "Level 2 should be unlocked")

## @brief A level not explicitly added must remain locked.
func test_not_unlocked_level_stays_locked() -> void:
	GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS].append(1)
	var unlocked: Array = GameManager.runtime_data[GameManager.KEY_UNLOCKED_LEVELS]
	assert_false(unlocked.has(2), "Level 2 should remain locked when only level 1 was unlocked")
