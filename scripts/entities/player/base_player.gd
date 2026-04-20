class_name BasePlayer
extends Entity
## Közös 2D karakter alap:
## - állapotgép: IDLE / RUN / JUMP / FALL / ATTACK / HURT / DEAD
## - mozgás, ugrás, gravitáció
## - melee alap támadás enemies csoportra
## - ability: dash / double_jump / block / fireball – CharacterResource alapján
##
## Minden szám CharacterResource + GameManager.player_data alapján jön:
## - CharacterResource: base_hp, base_dmg, base_spd, jump_velocity, ability_type,
##   ability_cooldown, ability_power
## - GameManager.player_data: végső HP / DMG / SPD (equip itemekkel együtt)

# ============================================================================
# ÁLLAPOTGÉP
# ============================================================================

enum State {
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
	HURT,
	DEAD
}

var _state: State = State.IDLE
var _facing_right: bool = true

# ============================================================================
# RESOURCE ÉS KÉPESSÉGEK
# ============================================================================

var character_res: CharacterResource = null

var ability_type: String = "none"
var ability_cooldown: float = 0.0
var ability_power: float = 0.0

var _ability_cd_timer: float = 0.0

## Alap melee range – ha akarod, tehetsz rá külön mezőt a CharacterResource-ba,
## most ability_power-re támaszkodunk alapértelmezésként.
var melee_range: float = 50.0

# ============================================================================
# MOZGÁS PARAMÉTEREK (Resource-ból jönnek)
# ============================================================================

## Az Entity-ben lévő mezőket (move_speed, gravity, jump_force) ebből töltjük fel.
var jump_force: float = 300.0

# ============================================================================
# NODE REFERENCIÁK – a konkrét karakter scene-nek ezeket kell tartalmaznia
# ============================================================================

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var _hitbox: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# ============================================================================
# SIGNALOK – HUD / GAME LOGIC
# ============================================================================

signal character_stats_changed()
signal character_died()

# ============================================================================
# ÉLET­CÍKLUS
# ============================================================================

func _ready() -> void:
	super._ready()
	## Fontos: a konkrét karakter (pl. PlayerKnight) hívja meg később a
	## set_character_resource() metódust a megfelelő CharacterResource-szal.
	## Itt csak inicializáljuk a belső időzítőket.
	_ability_cd_timer = 0.0


func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_ability_cd_timer = max(0.0, _ability_cd_timer - delta)

	_handle_movement(delta)
	_update_state()
	_update_animation()


func _unhandled_input(event: InputEvent) -> void:
	if not is_alive:
		return

	_handle_action_input(event)

# ============================================================================
# INITIALIZÁLÁS – RESOURCE + GAMEMANAGER STATOK
# ============================================================================

func set_character_resource(res: CharacterResource) -> void:
	## Ezt hívja a konkrét karakter script (PlayerKnight stb.)
	## a DataDb.get_character(selected_id) eredményével.
	character_res = res
	if character_res == null:
		push_error("BaseCharacter: character_res is null!")
		return

	## 1) Resource-ból származtatott mozgás/ability paraméterek
	entity_name = character_res.character_id
	faction = "player"  ## játszható karakter

	## Mozgás
	move_speed = character_res.base_spd
	jump_force = -character_res.jump_velocity  ## Resource-ban negatív, itt pozitív erőként használjuk
	## Gravity maradhat egy globális default, vagy később tegyünk Resource-ba külön mezőt

	## Ability
	ability_type = character_res.ability_type
	ability_cooldown = character_res.ability_cooldown
	ability_power = character_res.ability_power

	## Alap melee range – ha szükséges, Resource-ba is tehetünk külön mezőt,
	## most legyen ability_power-rel arányos vagy fix.
	melee_range = 50.0

	## 2) GameManager.player_data-ból végső HP/DMG/SPD (equip itemekkel együtt)
	if GameManager != null:
		if GameManager.has_method("_update_player_stats"):
			GameManager._update_player_stats()
		apply_stats_from_dict(GameManager.player_data)

	emit_signal("character_stats_changed")

# ============================================================================
# MOZGÁS ÉS ÁLLAPOT
# ============================================================================

func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_axis("move_left", "move_right")

	# Vízszintes mozgás
	velocity.x = input_dir * move_speed

	# Gravitáció
	if not is_on_floor():
		velocity.y += gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = -jump_force

	# Nézési irány
	if abs(input_dir) > 0.1:
		_facing_right = input_dir > 0.0

	move_and_slide()


func _update_state() -> void:
	if not is_alive:
		_state = State.DEAD
		return

	if not is_on_floor():
		_state = State.JUMP if velocity.y < 0.0 else State.FALL
		return

	if abs(velocity.x) > 0.1:
		_state = State.RUN
	else:
		_state = State.IDLE


func _update_animation() -> void:
	if _sprite == null:
		return

	var anim_name: StringName = _get_animation_name()
	_sprite.play(anim_name)

	_sprite.flip_h = not _facing_right


func _get_animation_name() -> StringName:
	## Default mapping – konkrét karakter (pl. PlayerKnight) override-olhatja.
	match _state:
		State.IDLE:             return &"idle"
		State.RUN:              return &"run"
		State.JUMP:             return &"jump"
		State.FALL:             return &"fall"
		State.ATTACK:           return &"attack"
		State.HURT:             return &"hurt"
		State.DEAD:             return &"death"
	return &"idle"

# ============================================================================
# INPUT: MELEE ATTACK + ABILITY + INTERACT + ITEM USE
# ============================================================================

func _handle_action_input(event: InputEvent) -> void:
	# Alap melee támadás (minden játszható karakter melee)
	if event.is_action_pressed("attack"):
		_do_melee_attack()

	# Ability (Shift / "special")
	if event.is_action_pressed("special"):
		_do_ability()

	# Interakció
	if event.is_action_pressed("interact"):
		_request_interaction()

	# Item használat – ezt a konkrét karakter (PlayerKnight) implementálja, mert tud az inventoryról
	if event.is_action_pressed("use_item"):
		_use_selected_item()

# ============================================================================
# MELEE TÁMADÁS – enemies csoport ellen
# ============================================================================

func _do_melee_attack() -> void:
	if not is_alive:
		return

	_state = State.ATTACK

	var hit_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D):
			continue
		if global_position.distance_to(enemy.global_position) <= melee_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_count += 1

	# Egyszerű előre lökés találatkor
	if hit_count > 0:
		var fwd := 1.0 if _facing_right else -1.0
		velocity.x += fwd * 40.0

# ============================================================================
# ABILITY – dash / double_jump / block / fireball
# ============================================================================

func _do_ability() -> void:
	if ability_type == "none":
		return
	if _ability_cd_timer > 0.0:
		return

	match ability_type:
		"dash":
			_do_dash()
		"double_jump":
			_do_double_jump()
		"block":
			_do_block()
		"fireball":
			_do_fireball()

	_ability_cd_timer = ability_cooldown


func _do_dash() -> void:
	## Dash: ability_power = vízszintes impulzus px/s
	var dir := 1.0 if _facing_right else -1.0
	velocity.x = dir * ability_power


func _do_double_jump() -> void:
	## Double jump: ability_power = második ugrás velocity (negatív)
	if not is_on_floor():
		velocity.y = ability_power


func _do_block() -> void:
	## Block: ability_power = sebzéscsökkentés aránya 0..1
	## Itt csak egy flaget állíthatnánk, amit a take_damage figyelembe vesz.
	## Egyszerű implementáció: next hit reduced – ezt a konkrét játékdesign szerint finomíthatod.
	pass


func _do_fireball() -> void:
	## Fireball: ability_power = lövedék sebzése.
	## Itt projectile spawnt kellene meghívni (pl. egy PackedScene-ből),
	## amit a konkrét karakter script (PlayerKnight) tudna előkészíteni.
	pass

# ============================================================================
# INTERAKCIÓK / ITEM HASZNÁLAT – üres hook-ok, elvileg megvalósíthatóak ebben a fájlban
# ============================================================================

func _request_interaction() -> void:
	## Ajtók, triggerek stb. kezdeti hook – konkrét karakter override-olja.
	pass


func _use_selected_item() -> void:
	## Inventory integráció – konkrét karakter (PlayerKnight) override-olja. 
	pass

# ============================================================================
# SEBZÉS / HALÁL – ALAP IMPLEMENTÁCIÓ
# ============================================================================

func take_damage(amount: int) -> void:
	## Entity alap sebzés + állapotfrissítés.
	super.take_damage(amount)

	if is_alive:
		_state = State.HURT
		_on_took_damage(amount)
	else:
		_state = State.DEAD
		_on_died()

	emit_signal("character_stats_changed")


func _on_took_damage(amount: int) -> void:
	## Default: csak logol – konkrét karakter (PlayerKnight) teheti hozzá a flash effektet.
	print("[BaseCharacter] Took damage: -%d | HP: %d / %d" % [amount, health, max_health])


func _on_died() -> void:
	emit_signal("character_died")
	## Itt még csak alap implementáció – konkrét karakter (PlayerKnight) pl. LevelManagernek szólhat.
