## @file test_game_manager_inventory.gd
## @brief Unit tests for GameManager inventory management.
##
## Uses item IDs that exist in DataDb: "beer", "apple" (consumables)
## and "basic_sword" (weapon). Using non-existent IDs causes inventory_add
## to silently return without modifying the inventory.
extends GutTest

var _saved_runtime_data: Dictionary = {}

## @brief Saves runtime_data and resets inventory to a clean state.
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

# --- inventory_add ---

## @brief Adding a consumable must set the count to the supplied amount.
func test_add_consumable_increases_count() -> void:
	GameManager.inventory_add("beer", 2)
	assert_eq(GameManager.inventory_get_count("beer"), 2,
		"Count should be 2 after adding 2 beers")

## @brief Adding the same consumable twice must stack the quantities.
func test_add_consumable_stacks() -> void:
	GameManager.inventory_add("apple", 1)
	GameManager.inventory_add("apple", 2)
	assert_eq(GameManager.inventory_get_count("apple"), 3,
		"Consumables should stack: 1 + 2 = 3")

## @brief Equipment items must be placed in the correct category slot.
func test_add_equipment_goes_to_correct_slot() -> void:
	GameManager.inventory_add("basic_sword")
	var inv: Dictionary = GameManager.runtime_data[GameManager.KEY_INVENTORY]
	assert_true(inv["weap"].has("basic_sword"),
		"basic_sword should be placed in the 'weap' category")

# --- inventory_has ---

## @brief inventory_has must return true for an owned consumable.
func test_has_returns_true_for_owned_item() -> void:
	GameManager.inventory_add("beer", 1)
	assert_true(GameManager.inventory_has("beer"),
		"inventory_has should return true for an owned item")

## @brief inventory_has must return false for a missing item.
func test_has_returns_false_for_missing_item() -> void:
	assert_false(GameManager.inventory_has("beer"),
		"inventory_has should return false when item was never added")

# --- inventory_remove ---

## @brief Removing one unit must decrement the count by one.
func test_remove_decreases_count() -> void:
	GameManager.inventory_add("beer", 2)
	GameManager.inventory_remove("beer")
	assert_eq(GameManager.inventory_get_count("beer"), 1,
		"Count should decrease by 1 after a single remove")

## @brief Removing an absent item must return false.
func test_remove_returns_false_when_not_owned() -> void:
	var result: bool = GameManager.inventory_remove("beer")
	assert_false(result, "Removing an absent item should return false")

# --- inventory_get_count ---

## @brief The count for an item that was never added must be zero.
func test_count_is_zero_for_absent_item() -> void:
	assert_eq(GameManager.inventory_get_count("beer"), 0,
		"Count should be 0 for an item that was never added")
