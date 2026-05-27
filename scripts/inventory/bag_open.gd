extends Control

## ──────────────────────────────────────────────
##  BagOpenOverlay – weight-based lootbag overlay
##  Súlyozott droppolási rendszer + animáció
##  ItemResource alapú, EquipSlot enum támogatással
## ──────────────────────────────────────────────

signal bag_closed(loot: Array[String])
signal loot_taken

# ── Tween refs ──────────────────────────────────
var _open_tween: Tween
var _close_tween: Tween
var _glow_tween: Tween

# ── State ───────────────────────────────────────
var _is_open := false
var _is_animating := false
var _loot: Array[String] = []
var _source_item_id: String = ""

# ── Loot table: item_id → súly (minél nagyobb, annál gyakoribb)
#    Betöltődik a bag item pool mezőjéből
var loot_table: Dictionary = {}

# ── Bag beállítások ────────────────────────────
@export var bag_item_count_min: int = 1
@export var bag_item_count_max: int = 2
@export var animation_duration_open: float = 0.55
@export var animation_duration_close: float = 0.35
@export var item_reveal_delay: float = 0.10
@export var item_reveal_duration: float = 0.35

# ── Node refs ──────────────────────────────────
@onready var dim_bg: ColorRect = $DimBackground
@onready var bag_center: Control = $BagCenter
@onready var bag_glow: ColorRect = $BagCenter/BagGlow
@onready var bag_panel: PanelContainer = $BagCenter/BagPanel
@onready var bag_title: Label = $BagCenter/BagPanel/VBox/BagTitle
@onready var item_grid: GridContainer = $BagCenter/BagPanel/VBox/ScrollContainer/ItemGrid
@onready var take_btn: Button = $BagCenter/BagPanel/VBox/HBox/TakeBtn
@onready var close_btn: Button = $BagCenter/BagPanel/VBox/HBox/CloseBtn


func _ready() -> void:
	modulate.a = 0.0
	bag_center.scale = Vector2(0.0, 0.0)
	bag_center.pivot_offset = bag_center.size / 2.0
	dim_bg.color = Color(0, 0, 0, 0)
	visible = false

	take_btn.pressed.connect(_on_take_pressed)
	close_btn.pressed.connect(_on_close_pressed)


func _input(event: InputEvent) -> void:
	if not _is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## Megnyitja a bag overlay-t animációval
## source_item_id: a bag item id-ja (pl. "iron_chest") a már-nyitott ellenőrzéshez
## custom_pool: item_id-k amiket a bag tartalmazhat (a bag item pool mezőjéből)
func open(source_item_id: String, custom_pool: Array[String] = []) -> void:
	if _is_open or _is_animating:
		return

	# ── Már kinyitott bag ellenőrzése ───────────
	_source_item_id = source_item_id

	# ── Loot tábla felépítése a poolból ─────────
	loot_table = _build_loot_table_from_pool(custom_pool)

	_is_animating = true
	_is_open = true
	visible = true

	# Loot generálása
	_generate_loot()

	# Cím beállítása a bag item nevére
	_update_title()

	# Pivot beállítása a középpontra
	await get_tree().process_frame
	bag_center.pivot_offset = bag_center.size / 2.0

	# ── Nyitó animáció ──────────────────────────
	_kill_tweens()

	_open_tween = create_tween().set_parallel(true)

	_open_tween.tween_property(dim_bg, "color", Color(0, 0, 0, 0.55), animation_duration_open * 0.6)

	_open_tween.tween_property(bag_center, "scale", Vector2(1.0, 1.0), animation_duration_open)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_open_tween.tween_property(self, "modulate:a", 1.0, animation_duration_open * 0.5)

	_open_tween.chain().tween_callback(_start_glow_pulse)

	_schedule_item_reveals()

	await _open_tween.finished
	_is_animating = false


## Bezárja a bag overlay-t animációval
func close() -> void:
	if not _is_open or _is_animating:
		return

	_is_animating = true
	_kill_tweens()

	_close_tween = create_tween().set_parallel(true)

	_close_tween.tween_property(dim_bg, "color", Color(0, 0, 0, 0), animation_duration_close)

	_close_tween.tween_property(bag_center, "scale", Vector2(0.0, 0.0), animation_duration_close)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	_close_tween.tween_property(self, "modulate:a", 0.0, animation_duration_close * 0.7)

	await _close_tween.finished

	_is_open = false
	_is_animating = false
	visible = false

	_clear_grid()
	bag_closed.emit(_loot)

## Loot tábla felépítése a bag item pooljából
## A pool-ban lévő itemekhez a rarity alapján számítjuk a weight-et:
##   common  → 10,  rare → 4,  mythic → 1
## Ha a pool üres, üres táblát ad vissza
func _build_loot_table_from_pool(pool: Array[String]) -> Dictionary:
	var table: Dictionary = {}

	for item_id in pool:
		var item: ItemResource = DataDb.get_item(item_id) as ItemResource if DataDb else null
		if item:
			table[item_id] = _rarity_to_weight(item.rarity)
		else:
			# Ha nincs DataDb entry, alapértelmezett common weight
			table[item_id] = 10

	return table


## Rarity → weight mapping (nagyobb = gyakoribb)
func _rarity_to_weight(rarity: String) -> int:
	match rarity.to_lower():
		"common":  return 10
		"rare":    return 4
		"epic":  return 1
		_:         return 10


## Súlyozott véletlenszerű választás a loot_table-ből
func _weighted_random_item() -> String:
	var total_weight := 0
	for w in loot_table.values():
		total_weight += int(w)

	if total_weight == 0:
		return ""

	var roll := randi() % total_weight
	var cumulative := 0

	for item_id in loot_table:
		cumulative += int(loot_table[item_id])
		if roll < cumulative:
			return item_id

	var keys := loot_table.keys()
	return keys[keys.size() - 1] if keys.size() > 0 else ""


## Loot generálása a súlyozott tábla alapján
func _generate_loot() -> void:
	_loot.clear()
	if loot_table.is_empty():
		return

	var inv = GameManager.runtime_data[GameManager.KEY_INVENTORY]
	var already_owned: Array = []
	already_owned.append_array(inv.get("helm", []))
	already_owned.append_array(inv.get("weap", []))
	already_owned.append_array(inv.get("boots", []))

	var count := randi_range(bag_item_count_min, bag_item_count_max)
	var attempts := 0
	var max_attempts := count * 10

	while _loot.size() < count and attempts < max_attempts:
		attempts += 1
		var item_id := _weighted_random_item()
		if item_id == "":
			break

		var item: ItemResource = DataDb.get_item(item_id) as ItemResource if DataDb else null

		# Equippable: ha már van ilyen az inventoryban, kihagyjuk
		if item and item.type == ItemResource.ItemType.EQUIPPABLE:
			if item_id in already_owned:
				_loot.append("apple") # elveszi a fegyvert de kap helyette almát :D XD
				continue

		# Consumable / key_item: mindig engedjük (többször is)
		_loot.append(item_id)

## Cím beállítása a bag item nevére
func _update_title() -> void:
	if _source_item_id != "":
		var item: ItemResource = DataDb.get_item(_source_item_id) as ItemResource if DataDb else null
		if item and item.name != "":
			bag_title.text = "🎒  %s" % item.name.to_upper()
			return
	bag_title.text = "🎒  LOOT BAG"


# ═════════════════════════════════════════════════
#  UI ÉPÍTÉS
# ═════════════════════════════════════════════════

func _build_item_cards() -> void:
	_clear_grid()

	for i in _loot.size():
		var item_id: String = _loot[i]
		var card := _create_item_card(item_id, i)
		item_grid.add_child(card)


func _create_item_card(item_id: String, index: int) -> Control:
	var item: ItemResource = DataDb.get_item(item_id) as ItemResource if DataDb else null

	# ── Card container ──────────────────────────
	var card := PanelContainer.new()
	card.name = "ItemCard_%d" % index
	card.custom_minimum_size = Vector2(90, 100)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.9)
	style.border_width_bottom = 2
	style.border_width_top = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.35, 0.55, 0.75, 0.8)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_detail = 12
	style.shadow_color = Color(0.2, 0.4, 0.7, 0.25)
	style.shadow_size = 6
	card.add_theme_stylebox_override("panel", style)

	# Rejtett az animációhoz
	card.scale = Vector2(0.0, 0.0)
	card.modulate.a = 0.0
	card.pivot_offset = Vector2(45, 50)

	# ── VBox ────────────────────────────────────
	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)
	card.add_child(vbox)

	# ── Icon vagy placeholder ───────────────────
	if item and item.icon:
		var icon_rect := TextureRect.new()
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(44, 44)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.texture = item.icon
		vbox.add_child(icon_rect)
	else:
		var placeholder := ColorRect.new()
		placeholder.color = Color(0.3, 0.4, 0.55, 0.5)
		placeholder.custom_minimum_size = Vector2(44, 44)
		vbox.add_child(placeholder)

	# ── Név címke ───────────────────────────────
	var name_label := Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color(0.85, 0.9, 1.0, 1.0))
	name_label.add_theme_font_size_override("font_size", 11)

	if item and item.name != "":
		name_label.text = item.name
	else:
		name_label.text = item_id.capitalize()

	vbox.add_child(name_label)

	# ── Ritkaság szín a keréken ─────────────────
	if item and item.rarity != "":
		var rarity_color := _rarity_to_color(item.rarity)
		style.border_color = rarity_color
		style.shadow_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	return card


## Ritkaság → szín mapping (ItemResource rarity mezőjéhez)
func _rarity_to_color(rarity: String) -> Color:
	match rarity.to_lower():
		"common":  return Color(0.7, 0.7, 0.7, 0.9)
		"rare":    return Color(0.3, 0.5, 1.0, 0.9)
		"epic":  return Color(0.85, 0.35, 1.0, 0.9)
		_:         return Color(0.35, 0.55, 0.75, 0.8)


# ═════════════════════════════════════════════════
#  ANIMÁCIÓK
# ═════════════════════════════════════════════════

func _schedule_item_reveals() -> void:
	_build_item_cards()

	var cards := item_grid.get_children()
	for i in cards.size():
		var card: Control = cards[i]
		var delay := animation_duration_open * 0.5 + i * item_reveal_delay

		var reveal_tween := create_tween()
		reveal_tween.tween_interval(delay)
		reveal_tween.set_parallel(true)
		reveal_tween.tween_property(card, "scale", Vector2(1.0, 1.0), item_reveal_duration)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		reveal_tween.tween_property(card, "modulate:a", 1.0, item_reveal_duration * 0.6)


func _start_glow_pulse() -> void:
	if not is_instance_valid(bag_glow):
		return
	_glow_tween = create_tween().set_loops()
	_glow_tween.tween_property(bag_glow, "modulate:a", 0.35, 1.2).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(bag_glow, "modulate:a", 0.08, 1.2).set_trans(Tween.TRANS_SINE)


func _kill_tweens() -> void:
	for tw in [_open_tween, _close_tween, _glow_tween]:
		if is_instance_valid(tw) and tw.is_running():
			tw.kill()
	_open_tween = null
	_close_tween = null
	_glow_tween = null


# ═════════════════════════════════════════════════
#  CALLBACKS
# ═════════════════════════════════════════════════

func _on_take_pressed() -> void:
	for item_id in _loot:
		_add_item_to_inventory(item_id)
		
	loot_taken.emit()
	close()

func _add_item_to_inventory(item_id: String) -> void:
	var item: ItemResource = DataDb.get_item(item_id)
	if not item:
		return
	
	var inv = GameManager.runtime_data[GameManager.KEY_INVENTORY]
	match item.type:
		ItemResource.ItemType.EQUIPPABLE:
			match item.slot:
				ItemResource.EquipSlot.HELMET:
					if item_id not in inv["helm"]:
						inv["helm"].append(item_id)
						
				ItemResource.EquipSlot.WEAPON:
					if item_id not in inv["weap"]:
						inv["weap"].append(item_id)
						
				ItemResource.EquipSlot.BOOTS:
					if item_id not in inv["boots"]:
						inv["boots"].append(item_id)
			
		_: inv["cons"][item_id] = inv["cons"].get(item_id, 0) + 1

func _on_close_pressed() -> void:
	close()


# ═════════════════════════════════════════════════
#  HELPERS
# ═════════════════════════════════════════════════

## Item kategória meghatározása az ItemResource EquipSlot enum alapján
func _item_to_category(item_id: String) -> String:
	var item: ItemResource = DataDb.get_item(item_id) as ItemResource if DataDb else null
	if not item:
		return ""

	# Ha consumable vagy key_item → cons dict
	if item.type == ItemResource.ItemType.CONSUMABLE or item.type == ItemResource.ItemType.KEY_ITEM:
		return "cons"

	# Ha equippable → slot enum alapján
	if item.type == ItemResource.ItemType.EQUIPPABLE:
		match item.slot:
			ItemResource.EquipSlot.HELMET: return "helm"
			ItemResource.EquipSlot.WEAPON: return "weap"
			ItemResource.EquipSlot.BOOTS:  return "boots"

	# Fallback
	return "cons"


func _clear_grid() -> void:
	for c in item_grid.get_children():
		c.queue_free()
