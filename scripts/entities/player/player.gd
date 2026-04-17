## player.gd
## ==========================================================================
## BasePlayer – alap osztály minden játszható karakterhez.
## (CharacterResource + ItemResource alapú stat rendszer)
##
## Elhelyezés: scripts/entities/player/player.gd
##
## Setup folyamat (PlayerSpawner hívja, miután a scene betöltődött):
##   player.setup(char_res, equipped_items)
##   → beállítja a stat-okat, képességet, attack range-t a resource-okból
##
## Felülírható virtual metódusok gyerek osztályokban:
##   _on_ready(), _do_attack(), _use_ability(), _get_animation_name(),
##   _on_took_damage(), _on_died(), _on_physics_process()
## ==========================================================================

class_name BasePlayer
extends CharacterBody2D

# ---------------------------------------------------------------------------
# Signalok
# ---------------------------------------------------------------------------

signal died()
signal took_damage(amount: int)
signal healed(amount: int)
## HUD frissítéshez.
signal health_changed(current: int, maximum: int)
signal attacked()
signal landed()

# ---------------------------------------------------------------------------
# Exportált változók (Inspector fallback; setup() felülírja ezeket)
# ---------------------------------------------------------------------------

@export_group("Movement")
@export var speed: float            = 180.0
@export var jump_velocity: float    = -360.0
@export var gravity_scale: float    = 1.0
@export var coyote_time: float      = 0.12
@export var jump_buffer_time: float = 0.10

@export_group("Health")
@export var max_health: int               = 100
@export var invincibility_duration: float = 0.5

@export_group("Attack")
@export var base_damage: int   = 20
@export var attack_cooldown: float = 0.40
@export var attack_range: float    = 55.0

# ---------------------------------------------------------------------------
# Publikus futásidejű állapot
# ---------------------------------------------------------------------------

var current_health: int = 0
var is_dead: bool       = false

# ---------------------------------------------------------------------------
# Belső futásidejű változók
# ---------------------------------------------------------------------------

var _inv_timer:     float = 0.0
var _atk_timer:     float = 0.0
var _coyote_left:   float = 0.0
var _jump_buffer:   float = 0.0
var _ability_timer: float = 0.0

var _was_on_floor: bool = false
var _facing_right: bool = true
var _damage: int        = 20

## Betöltött CharacterResource (setup()-ban kerül be).
var _char_res: CharacterResource = null

## Felszerelt tárgyak (setup()-ban kerül be).
var _equipped_items: Array[ItemResource] = []

## Aktív ideiglenes buffok: [{stat, value, timer}]
var _active_buffs: Array[Dictionary] = []

## Képesség adatok (CharacterResource-ból töltve).
var _ability_type:     String = "dash"
var _ability_cooldown: float  = 1.2
var _ability_power:    float  = 350.0

var _gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

# ---------------------------------------------------------------------------
# Állapotgép
# ---------------------------------------------------------------------------

enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD }
var _state: State = State.IDLE

# ---------------------------------------------------------------------------
# Node referenciák
# ---------------------------------------------------------------------------

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
var _atk_hitbox: Area2D = null

# ---------------------------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------------------------

func _ready() -> void:
	add_to_group("player")
	_atk_hitbox = _find_area2d()
	if _atk_hitbox:
		_atk_hitbox.monitoring = false
	# Ha setup() nem lett hívva (pl. standalone teszt), Inspector értékek
	if _char_res == null:
		_apply_stats_fallback()
	current_health = max_health
	_on_ready()


## Virtual – extra inicializáláshoz gyerek osztályban.
## Meghívódik _ready() végén, miután az alap init kész.
func _on_ready() -> void:
	pass


## A PlayerSpawner hívja a példányosítás után, mielőtt a pályára kerül.
## @param char_res        CharacterResource a kiválasztott karakterhez.
## @param equipped_items  ItemResource[] a felszerelt tárgyakhoz.
func setup(char_res: CharacterResource, equipped_items: Array[ItemResource] = []) -> void:
	_char_res      = char_res
	_equipped_items = equipped_items
	_apply_stats_from_resources()
	current_health = max_health


func _physics_process(delta: float) -> void:
	if is_dead:
		return
	_tick_timers(delta)
	_apply_gravity(delta)
	_handle_input(delta)
	move_and_slide()
	_check_landing()
	_sync_animation()
	_was_on_floor = is_on_floor()
	_on_physics_process(delta)


## Virtual – extra per-frame logikához gyerek osztályban.
func _on_physics_process(_delta: float) -> void:
	pass

# ---------------------------------------------------------------------------
# Stat rendszer
# ---------------------------------------------------------------------------

## Stat-ok betöltése CharacterResource + ItemResource bónuszok alapján.
## setup()-ból hívódik; ez az egyetlen hely ahol stat-ok változnak.
func _apply_stats_from_resources() -> void:
	if _char_res == null:
		_apply_stats_fallback()
		return

	# 1. Alap stat-ok a CharacterResource-ból
	max_health    = _char_res.max_health
	_damage       = _char_res.base_damage
	speed         = _char_res.move_speed
	jump_velocity = _char_res.jump_velocity

	# 2. Képesség adatok
	_ability_type     = _char_res.ability_type
	_ability_cooldown = _char_res.ability_cooldown
	_ability_power    = _char_res.ability_power

	# 3. Felszerelt tárgyak additív bónuszai
	for item in _equipped_items:
		max_health += item.health_bonus
		_damage    += item.damage_bonus
		speed      += item.speed_bonus
		if item.attack_range > 0.0:
			attack_range = item.attack_range
		if item.attack_cooldown_override > 0.0:
			attack_cooldown = item.attack_cooldown_override

	print("[BasePlayer] %s – HP:%d DMG:%d SPD:%.0f Képesség:%s" % [
		_char_res.character_name, max_health, _damage, speed, _ability_type
	])


## Fallback stat betöltés ha nincs CharacterResource.
## A GameManager.player_data szorzóit alkalmazza az exportált értékekre.
func _apply_stats_fallback() -> void:
	_damage = base_damage
	if not Engine.has_singleton("GameManager"):
		return
	var pd: Dictionary = GameManager.player_data
	speed      = speed      * pd.get(GameManager.KEY_SPEED, 1.0)
	_damage    = roundi(float(base_damage) * pd.get(GameManager.KEY_DMG, 1.0))
	max_health = roundi(float(max_health)  * pd.get(GameManager.KEY_HP,  1.0))


## Fogyasztható tárgy használata az inventory-ból.
## @param item_id  Az ItemResource.item_id értéke.
func use_consumable(item_id: String) -> void:
	var item_path := "res://data/items/" + item_id + ".tres"
	if not ResourceLoader.exists(item_path):
		push_warning("BasePlayer: item error: " + item_id)
		return
	var item := load(item_path) as ItemResource
	if item == null or not item.is_consumable():
		return

	match item.consumable_effect:
		"heal":         heal(int(item.effect_value))
		"damage_buff":  _add_buff("damage", item.effect_value, item.effect_duration)
		"speed_buff":   _add_buff("speed",  item.effect_value, item.effect_duration)

	var inv: Array = GameManager.runtime_data.get(GameManager.KEY_INVENTORY, [])
	inv.erase(item_id)


## Ideiglenes stat buff hozzáadása (consumable effekt).
func _add_buff(stat: String, value: float, duration: float) -> void:
	_active_buffs.append({"stat": stat, "value": value, "timer": duration})


func _tick_buffs(delta: float) -> void:
	for i in range(_active_buffs.size() - 1, -1, -1):
		_active_buffs[i]["timer"] -= delta
		if _active_buffs[i]["timer"] <= 0.0:
			_active_buffs.remove_at(i)


## Effektív sebzés = alap + active buffok.
func get_effective_damage() -> int:
	var bonus: float = 0.0
	for buff in _active_buffs:
		if buff["stat"] == "damage":
			bonus += buff["value"]
	return _damage + int(bonus)


## Effektív sebesség = alap + active buffok.
func get_effective_speed() -> float:
	var bonus: float = 0.0
	for buff in _active_buffs:
		if buff["stat"] == "speed":
			bonus += buff["value"]
	return speed + bonus

# ---------------------------------------------------------------------------
# Input
# ---------------------------------------------------------------------------

func _handle_input(_delta: float) -> void:
	_handle_movement_input()
	_handle_jump_input()
	_handle_action_input()


func _handle_movement_input() -> void:
	if _state in [State.ATTACK, State.HURT, State.DEAD]:
		velocity.x = move_toward(velocity.x, 0.0, get_effective_speed())
		return
	var dir := Input.get_axis("move_left", "move_right")
	if dir != 0.0:
		_facing_right = dir > 0.0
		_sprite.flip_h = not _facing_right
		velocity.x = dir * get_effective_speed()
	else:
		velocity.x = move_toward(velocity.x, 0.0, get_effective_speed())


func _handle_jump_input() -> void:
	if _state == State.DEAD:
		return
	if Input.is_action_just_pressed("jump"):
		_jump_buffer = jump_buffer_time
	var can_jump := is_on_floor() or _coyote_left > 0.0
	if _jump_buffer > 0.0 and can_jump and _state != State.HURT:
		_perform_jump()
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y *= 0.5


## Virtual – extra akciók (speciális képesség, interakció) hozzáadásához.
func _handle_action_input() -> void:
	if Input.is_action_just_pressed("attack"):
		try_attack()
	if Input.is_action_just_pressed("special") and _ability_timer <= 0.0 and not is_dead:
		_use_ability()


func _perform_jump() -> void:
	velocity.y = jump_velocity
	_coyote_left = 0.0
	_jump_buffer = 0.0
	_set_state(State.JUMP)

# ---------------------------------------------------------------------------
# Képesség rendszer
# ---------------------------------------------------------------------------

## Képesség aktiválása – CharacterResource.ability_type alapján dispatch.
## Felülírd gyerek osztályban ha egyedi képesség logika kell.
func _use_ability() -> void:
	_ability_timer = _ability_cooldown
	match _ability_type:
		"dash":        _ability_dash()
		"double_jump": _ability_double_jump()
		"block":       _ability_block()
		"fireball":    _ability_fireball()
		_: push_warning("BasePlayer: ismeretlen képesség: " + _ability_type)


func _ability_dash() -> void:
	var dir := 1.0 if _facing_right else -1.0
	velocity.x = dir * _ability_power


func _ability_double_jump() -> void:
	# ability_power negatív értéket kell, hogy tartalmazzon
	velocity.y = _ability_power


func _ability_block() -> void:
	# Gyerek osztályban implementálandó részletesen
	pass


## Virtual – tűzgolyó spawning gyerek osztályban implementálandó.
func _ability_fireball() -> void:
	push_warning("BasePlayer._ability_fireball(): felülírandó gyerek osztályban")

# ---------------------------------------------------------------------------
# Fizika
# ---------------------------------------------------------------------------

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y += _gravity * gravity_scale * delta


func _check_landing() -> void:
	var on_floor_now := is_on_floor()
	if on_floor_now and not _was_on_floor:
		landed.emit()
	if not on_floor_now and _was_on_floor and velocity.y >= 0.0:
		_coyote_left = coyote_time
	if on_floor_now:
		_coyote_left = 0.0
	if not _state in [State.ATTACK, State.HURT, State.DEAD]:
		if on_floor_now:
			_set_state(State.RUN if abs(velocity.x) > 10.0 else State.IDLE)
		else:
			_set_state(State.JUMP if velocity.y < 0.0 else State.FALL)

# ---------------------------------------------------------------------------
# Életerő
# ---------------------------------------------------------------------------

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if is_dead or _inv_timer > 0.0 or amount <= 0:
		return
	current_health = max(0, current_health - amount)
	_inv_timer = invincibility_duration
	took_damage.emit(amount)
	health_changed.emit(current_health, max_health)
	if current_health == 0:
		_trigger_death()
		return
	if knockback != Vector2.ZERO:
		velocity = knockback
	_set_state(State.HURT)
	_on_took_damage(amount)
	await get_tree().create_timer(0.30).timeout
	if _state == State.HURT:
		_set_state(State.IDLE)


## Virtual – hurt reakcióhoz (sprite flash, hang, kamera rázás).
func _on_took_damage(_amount: int) -> void:
	pass


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return
	current_health = min(current_health + amount, max_health)
	healed.emit(amount)
	health_changed.emit(current_health, max_health)


func is_alive() -> bool:
	return not is_dead


func get_health_ratio() -> float:
	if max_health == 0:
		return 0.0
	return float(current_health) / float(max_health)

# ---------------------------------------------------------------------------
# Halál
# ---------------------------------------------------------------------------

func _trigger_death() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector2.ZERO
	set_physics_process(false)
	_set_state(State.DEAD)
	died.emit()
	_on_died()


## Virtual – MINDEN gyerek osztályban felül KELL írni
## (LevelManager.on_player_death() híváshoz).
func _on_died() -> void:
	pass

# ---------------------------------------------------------------------------
# Támadás
# ---------------------------------------------------------------------------

func try_attack() -> void:
	if _atk_timer > 0.0 or is_dead or _state == State.HURT:
		return
	_atk_timer = attack_cooldown
	_set_state(State.ATTACK)
	attack()


## Virtual – magas szintű támadás wrapper.
func attack() -> void:
	attacked.emit()
	_do_attack()
	await get_tree().create_timer(0.35).timeout
	if _state == State.ATTACK:
		_set_state(State.IDLE)


## Virtual – tényleges sebzés kiosztása.
## Felülírd ha egyedi hitbox/raycast/area logika kell.
func _do_attack() -> void:
	var dmg := get_effective_damage()
	if _atk_hitbox:
		_atk_hitbox.monitoring = true
		await get_tree().create_timer(0.20).timeout
		if is_instance_valid(_atk_hitbox):
			_atk_hitbox.monitoring = false
			for body in _atk_hitbox.get_overlapping_bodies():
				if body.has_method("take_damage"):
					body.take_damage(dmg)
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= attack_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(dmg)

# ---------------------------------------------------------------------------
# Animáció
# ---------------------------------------------------------------------------

func _sync_animation() -> void:
	if _sprite == null:
		return
	var anim := _get_animation_name()
	if _sprite.animation != anim:
		_sprite.play(anim)


## Virtual – állapot → animáció névmapping.
## Felülírd ha a sprite sheet más neveket használ.
func _get_animation_name() -> StringName:
	match _state:
		State.IDLE:             return &"idle"
		State.RUN:              return &"walk"
		State.JUMP, State.FALL: return &"idle"
		State.ATTACK:           return &"attack"
		State.HURT:             return &"hurt"
		State.DEAD:             return &"death"
	return &"idle"

# ---------------------------------------------------------------------------
# Időzítők
# ---------------------------------------------------------------------------

func _tick_timers(delta: float) -> void:
	_inv_timer     = max(0.0, _inv_timer     - delta)
	_atk_timer     = max(0.0, _atk_timer     - delta)
	_jump_buffer   = max(0.0, _jump_buffer   - delta)
	_ability_timer = max(0.0, _ability_timer - delta)
	if not is_on_floor():
		_coyote_left = max(0.0, _coyote_left - delta)
	_tick_buffs(delta)

# ---------------------------------------------------------------------------
# Állapotgép
# ---------------------------------------------------------------------------

func _set_state(s: State) -> void:
	if _state != s:
		_state = s

# ---------------------------------------------------------------------------
# Publikus segédek
# ---------------------------------------------------------------------------

func is_invincible() -> bool:
	return _inv_timer > 0.0

func add_impulse(impulse: Vector2) -> void:
	velocity += impulse

func face_direction(dir: float) -> void:
	if dir != 0.0:
		_facing_right = dir > 0.0
		_sprite.flip_h = not _facing_right

func _find_area2d() -> Area2D:
	for child in get_children():
		if child is Area2D:
			return child
	return null
