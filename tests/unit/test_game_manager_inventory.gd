## @file test_game_manager_inventory.gd
## @brief Unit tests for [GameManager] inventory management.
##
## Covers: inventory_add, inventory_remove, inventory_has, inventory_get_count.
## GameManager is an autoload singleton; before_each / after_each
## save and restore runtime_data to prevent test pollution.
extends GutTest


## @brief Snapshot of runtime_data saved before each test for teardown restoration.
var _saved_runtime_data: Dictionary = {}


## @brief Saves the current runtime_data and installs a clean, empty inventory.
func before_each() -> void:
	_saved_runtime_data = GameManager.runtime_data.duplicate(true)
	GameManager.runtime_data[GameManager.KEY_INVENTORY] = {
		"helm":  [],
		"weap":  [],
		"boots": [],
		"cons":  {}
	}


## @brief Restores the original runtime_data after each test.
func after_each() -> void:
	GameManager.runtime_data = _saved_runtime_data


# inventory_add

## @brief Adding a consumable must set the count to the supplied amount.
func test_add_consumable_increases_count() -> void:
	GameManager.inventory_add("health_potion", 2)
	assert_eq(GameManager.inventory_get_count("health_potion"), 2,
		"Count should be 2 after adding 2 health potions")


## @brief Adding the same consumable twice must stack the quantities.
func test_add_consumable_stacks() -> void:
	GameManager.inventory_add("health_potion", 1)
	GameManager.inventory_add("health_potion", 2)
	assert_eq(GameManager.inventory_get_count("health_potion"), 3,
		"Consumables should stack: 1 + 2 = 3")


## @brief Equipment items must be placed in the correct category slot.
func test_add_equipment_goes_to_correct_slot() -> void:
	GameManager.inventory_add("basic_sword")
	var inv: Dictionary = GameManager.runtime_data[GameManager.KEY_INVENTORY]
	assert_true(inv["weap"].has("basic_sword"),
		"basic_sword should be placed in the 'weap' category")

# inventory_has

## @brief inventory_has must return true for an owned item.
func test_has_returns_true_for_owned_item() -> void:
	GameManager.inventory_add("health_potion", 1)
	assert_true(GameManager.inventory_has("health_potion"),
		"inventory_has should return true for an owned item")

## @brief inventory_has must return false for a missing item.
func test_has_returns_false_for_missing_item() -> void:
	assert_false(GameManager.inventory_has("health_potion"),
		"inventory_has should return false for a missing item")

# inventory_remove

## @brief Removing one unit of a consumable must decrement the count by one.
func test_remove_decreases_count() -> void:
	GameManager.inventory_add("health_potion", 2)
	GameManager.inventory_remove("health_potion")
	assert_eq(GameManager.inventory_get_count("health_potion"), 1,
		"Count should decrease by 1 after a single remove")

## @brief Removing an absent item must return false.
func test_remove_returns_false_when_not_owned() -> void:
	var result: bool = GameManager.inventory_remove("health_potion")
	assert_false(result, "Removing an absent item should return false")

# inventory_get_count

## @brief The count for an item that was never added must be zero.
func test_count_is_zero_for_absent_item() -> void:
	assert_eq(GameManager.inventory_get_count("health_potion"), 0,
		"Count should be 0 for an item that was never added")
