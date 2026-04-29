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

var _coyote_left: float = 0.0
var _was_on_floor: bool = false
@export var coyote_time: float = 0.12

var _state: State = State.IDLE
var _facing_right: bool = true

# ============================================================================
# RESOURCE ÉS KÉPESSÉGEK
# ============================================================================

var character_res: CharacterResource = null

@onready var _ability: AbilityComponent = $AbilityComponent if has_node("AbilityComponent") else null

## Alap melee range – ha akarod, tehetsz rá külön mezőt a CharacterResource-ba,
## most ability_power-re támaszkodunk alapértelmezésként.
var melee_range: float = 50.0

## Characters CD for attacking. Cant spam attack.
var attack_cooldown: float = 0.4
var _attack_cd_timer: float = 0.0

var _is_dashing: bool = false
var _dash_timer: float = 0.0
@export var dash_duration: float = 0.15

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
	if faction == "neutral":
		faction = "player"
	register_groups_from_faction()


func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	if _ability != null:
		_ability.tick(delta)
	_attack_cd_timer   = max(0.0, _attack_cd_timer   - delta)

	_tick_coyote(delta)
	_handle_movement(delta)
	_update_state()
	_update_animation()
	
	_was_on_floor = is_on_floor()


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

	## Alap melee range – ha szükséges, Resource-ba is tehetünk külön mezőt,
	## most legyen ability_power-rel arányos vagy fix.
	melee_range = 50.0

	## Ability
	if _ability != null:
		_ability.setup(self, character_res)
	
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
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
		move_and_slide()
		return
	
	var input_dir := Input.get_axis("move_left", "move_right")

	# Vízszintes mozgás
	velocity.x = input_dir * move_speed

	# Gravitáció
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		pass
		
	var can_jump := is_on_floor() or _coyote_left > 0.0
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = -jump_force
		_coyote_left = 0.0

	# Nézési irány
	if abs(input_dir) > 0.1:
		_facing_right = input_dir > 0.0

	move_and_slide()


func _update_state() -> void:
	if not is_alive:
		_state = State.DEAD
		return

	if _state == State.ATTACK or _state == State.HURT or _state == State.DEAD:
		return

	if not is_on_floor():
		_state = State.JUMP if velocity.y < 0.0 else State.FALL
		return

	if abs(velocity.x) > 0.1:
		_state = State.RUN
	else:
		_state = State.IDLE

func _tick_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_left = coyote_time
	elif is_on_floor():
		_coyote_left = 0.0
	else:
		_coyote_left = max(0.0, _coyote_left - delta)

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

func _update_animation() -> void:
	if _sprite == null:
		return

	var anim_name: StringName = _get_animation_name()
	_sprite.play(anim_name)

	_sprite.flip_h = not _facing_right

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

func _get_melee_targets() -> Array:
	var result: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D:
			result.append(enemy)
	return result

func _do_melee_attack() -> void:
	if not is_alive:
		return

	if _attack_cd_timer > 0.0:
		return

	_state = State.ATTACK
	
	var origin: Vector2 = global_position
	if _hitbox != null and _hitbox is Node2D:
		origin = (_hitbox as Node2D).global_position

	var hit_count := 0
	var targets := _get_melee_targets()
	for enemy in targets:
		if not (enemy is Node2D):
			continue
		var enemy_pos := (enemy as Node2D).global_position
		if origin.distance_to(enemy_pos) <= melee_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)
				hit_count += 1

	_attack_cd_timer = attack_cooldown

	# Egyszerű előre lökés találatkor
	if hit_count > 0:
		var fwd := 1.0 if _facing_right else -1.0
		velocity.x += fwd * 40.0
		
	await get_tree().create_timer(0.5).timeout
	if _state == State.ATTACK:
		_state = State.IDLE
		

# ============================================================================
# ABILITY – dash / double_jump / block / fireball ; AbilityComponent
# ============================================================================

func _do_ability() -> void:
	if _ability != null:
		_ability.activate()

func spawn_projectile(power: float) -> void:
	pass

# ============================================================================
# INTERAKCIÓK / ITEM HASZNÁLAT – üres hook-ok, elvileg megvalósíthatóak ebben a fájlban
# ============================================================================

func _request_interaction() -> void:
	## Megkeressük a legközelebbi "interactable" csoportban lévő
	## Node2D-t egy kis sugarú körben, és ha van rajta "interact" metódus,
	## hívjuk meg.
	var nearest: Node2D = null
	var best_dist := 48.0  # max interakciós távolság (px)
	var interactable_items := get_tree().get_nodes_in_group("interactable")

	for node in interactable_items:
		if not (node is Node2D):
			continue
		var d := global_position.distance_to(node.global_position)
		if d <= best_dist:
			best_dist = d
			nearest = node

	if nearest and nearest.has_method("interact"):
		nearest.interact(self)



func _use_selected_item() -> void:
	## Inventory integráció – konkrét karakter (PlayerKnight) override-olja. 
	pass

# ============================================================================
# SEBZÉS / HALÁL – ALAP IMPLEMENTÁCIÓ
# ============================================================================

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	## Entity alap sebzés + állapotfrissítés.
	## Ha csak amount-ot adunk meg az ellenfélnél, akkor is működik, nem löki vissza a karaktert
	var final_amount := amount
	if _ability != null and get_meta("is_blocking", false):
		var reduction := clampf(_ability.ability_power, 0.0, 1.0)
		final_amount = int(amount * (1.0 - reduction))
	super.take_damage(final_amount)

	if is_alive:
		if knockback != Vector2.ZERO:
			velocity = knockback
		_state = State.HURT
		_on_took_damage(amount)
	else:
		_state = State.DEAD
		_on_died()

	emit_signal("character_stats_changed")
	await get_tree().create_timer(0.2).timeout
	if _state == State.HURT:
		_state = State.IDLE


func _on_took_damage(amount: int) -> void:
	## Default: csak logol – konkrét karakter (PlayerKnight) teheti hozzá a flash effektet.
	print("[BaseCharacter] Took damage: -%d | HP: %d / %d" % [amount, health, max_health])


func _on_died() -> void:
	emit_signal("character_died")
	## Itt még csak alap implementáció – konkrét karakter (PlayerKnight) pl. LevelManagernek szólhat.
