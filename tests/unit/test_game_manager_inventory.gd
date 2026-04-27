extends GutTest
## test_game_manager_inventory.gd
## Unit tesztek a GameManager inventory kezeléséhez.
##
## Lefedi: add, remove, has, get_count.
##
## A GameManager autoload szingleton, ezért before_each / after_each
## segítségével minden teszt előtt visszaállítjuk a clean állapotot,
## hogy a tesztek ne befolyásolják egymást.


# Az eredeti runtime_data másolata – a teszt után visszaállítjuk
var _saved_runtime_data: Dictionary = {}


## Minden teszt előtt elmentjük az eredeti adatot,
## és beállítunk egy tiszta, üres inventory-t
func before_each() -> void:
	_saved_runtime_data = GameManager.runtime_data.duplicate(true)
	GameManager.runtime_data[GameManager.KEY_INVENTORY] = {
		"helm":  [],
		"weap":  [],
		"boots": [],
		"cons":  {}
	}


## Minden teszt után visszaállítjuk az eredeti adatot
func after_each() -> void:
	GameManager.runtime_data = _saved_runtime_data


# --- inventory_add ---

## Fogyóeszköz hozzáadása után a számláló megfelelő értékű legyen
func test_add_consumable_increases_count() -> void:
	GameManager.inventory_add("health_potion", 2)
	assert_eq(GameManager.inventory_get_count("health_potion"), 2,
		"Count should be 2 after adding 2 health potions")


## Kétszeri hozzáadás esetén a mennyiségek összeadódnak (stacking)
func test_add_consumable_stacks() -> void:
	GameManager.inventory_add("health_potion", 1)
	GameManager.inventory_add("health_potion", 2)
	assert_eq(GameManager.inventory_get_count("health_potion"), 3,
		"Consumables should stack: 1 + 2 = 3")


## Felszerelés a megfelelő kategóriába kerüljön (weap)
func test_add_equipment_goes_to_correct_slot() -> void:
	GameManager.inventory_add("basic_sword")
	var inv = GameManager.runtime_data[GameManager.KEY_INVENTORY]
	assert_true(inv["weap"].has("basic_sword"),
		"basic_sword should be in the 'weap' category")


# --- inventory_has ---

## inventory_has true-t ad vissza, ha az elem megvan
func test_has_returns_true_for_owned_item() -> void:
	GameManager.inventory_add("health_potion", 1)
	assert_true(GameManager.inventory_has("health_potion"),
		"inventory_has should return true for an owned item")


## inventory_has false-t ad vissza, ha az elem hiányzik
func test_has_returns_false_for_missing_item() -> void:
	assert_false(GameManager.inventory_has("health_potion"),
		"inventory_has should return false for a missing item")


# --- inventory_remove ---

## Eltávolítás után a számláló csökken
func test_remove_decreases_count() -> void:
	GameManager.inventory_add("health_potion", 2)
	GameManager.inventory_remove("health_potion")
	assert_eq(GameManager.inventory_get_count("health_potion"), 1,
		"Count should decrease by 1 after remove")


## Nem létező elem eltávolítása false-t ad vissza
func test_remove_returns_false_when_not_owned() -> void:
	var result = GameManager.inventory_remove("health_potion")
	assert_false(result, "Removing an absent item should return false")


# --- inventory_get_count ---

## Hiányzó elemnél a számláló 0 legyen
func test_count_is_zero_for_absent_item() -> void:
	assert_eq(GameManager.inventory_get_count("health_potion"), 0,
		"Count should be 0 for an item never added")
