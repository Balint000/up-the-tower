class_name BasePlayer
extends Entity

signal character_take_damage(amount)
signal player_died(entity: Entity)

# ============================================================================
# ÁLLAPOTGÉP
# ============================================================================
enum State { IDLE, RUN, JUMP, FALL, ATTACK, HURT, DEAD }

var _state: State       = State.IDLE
var _facing_right: bool = true

# ============================================================================
# MOZGÁS / FIZIKA
# ============================================================================
var jump_force: float   = 300.0

var _coyote_left: float  = 0.0
var _was_on_floor: bool  = false
@export var coyote_time: float = 0.12

var _is_dashing: bool   = false
var _dash_timer: float  = 0.0
@export var dash_duration: float = 0.15

# ============================================================================
# HARC
# ============================================================================
var melee_range: float    = 50.0
var attack_cooldown: float = 0.4
var _attack_cd_timer: float = 0.0

## Block képességnél true, amíg aktív (AbilityComponent._do_block() állítja).
## BasePlayer.take_damage() olvassa a sebzés csökkentéséhez.
var is_blocking: bool = false

# ============================================================================
# VIZUÁLIS (hurt flash)
# ============================================================================
@export var hurt_flash_count: int   = 4
@export var hurt_flash_speed: float = 0.07

# ============================================================================
# PROJEKTIL (fireball képességhez)
# ============================================================================
## A karakter scene-ben kell beállítani az editorban.
## A Projectile scene-nek van egy setup() metódusa (ld. projectile.gd).
@export var projectile_scene: PackedScene = null

# ============================================================================
# RESOURCE / KÉPESSÉGEK
# ============================================================================
var character_res: CharacterResource = null
@onready var _ability: AbilityComponent = $AbilityComponent if has_node("AbilityComponent") else null

# ============================================================================
# NODE REFERENCIÁK
# ============================================================================
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D if has_node("AnimatedSprite2D") else null
@onready var _hitbox: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null

# ============================================================================
# ÉLETCIKLUS
# ============================================================================
func _ready() -> void:
	super._ready()
	if faction == "neutral":
		faction = "player"
	register_groups_from_faction()
	_load_character_resource()

## CharacterResource automatikus betöltése GameManager + DataDb alapján.
## Nincs szükség ezt manuálisan hívni leszármazottból.
func _load_character_resource() -> void:
	if GameManager == null or DataDb == null:
		push_error("BasePlayer: GameManager vagy DataDb nem elérhető!")
		return
	var selected_id: String = GameManager.runtime_data.get(
		GameManager.KEY_SELECTED_CHARACTER, "knight"
	)
	var res: CharacterResource = DataDb.get_character(selected_id)
	if res == null:
		push_error("BasePlayer: CharacterResource nem található: " + selected_id)
		return
	set_character_resource(res)

func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	if _ability != null:
		_ability.tick(delta)

	_attack_cd_timer = max(0.0, _attack_cd_timer - delta)

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
# RESOURCE BETÖLTÉS
# ============================================================================
func set_character_resource(res: CharacterResource) -> void:
	character_res = res
	if character_res == null:
		push_error("BasePlayer: character_res is null!")
		return

	entity_name = character_res.character_id
	faction     = "player"
	move_speed  = character_res.base_spd
	jump_force  = -character_res.jump_velocity  # resource-ban negatív, itt pozitív erőként
	melee_range = 50.0

	if _ability != null:
		_ability.setup(self, character_res)

	if GameManager != null:
		if GameManager.has_method("_update_player_stats"):
			GameManager._update_player_stats()
		apply_stats_from_dict(GameManager.player_data)

	emit_signal("stats_changed", self)

# ============================================================================
# MOZGÁS
# ============================================================================
func _handle_movement(delta: float) -> void:
	## Dash közben a normál mozgás felül van írva
	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false
		move_and_slide()
		return

	var input_dir := Input.get_axis("move_left", "move_right")
	velocity.x = input_dir * move_speed

	if not is_on_floor():
		velocity.y += gravity * delta

	var can_jump := is_on_floor() or _coyote_left > 0.0
	if Input.is_action_just_pressed("jump") and can_jump:
		velocity.y = -jump_force
		_coyote_left = 0.0

	if abs(input_dir) > 0.1:
		_facing_right = input_dir > 0.0

	move_and_slide()

## Coyote time – rövid ideig ugorhat még a szél után is
func _tick_coyote(delta: float) -> void:
	if _was_on_floor and not is_on_floor() and velocity.y >= 0.0:
		_coyote_left = coyote_time
	elif is_on_floor():
		_coyote_left = 0.0
	else:
		_coyote_left = max(0.0, _coyote_left - delta)

func _update_state() -> void:
	if not is_alive:
		_state = State.DEAD
		return
	## Locked állapotok: nem szabad felülírni
	if _state in [State.ATTACK, State.HURT, State.DEAD]:
		return
	if not is_on_floor():
		_state = State.JUMP if velocity.y < 0.0 else State.FALL
		return
	_state = State.RUN if abs(velocity.x) > 0.1 else State.IDLE

# ============================================================================
# ANIMÁCIÓ
# ============================================================================
## Override-old ha a sprite sheet más névkonvenciót követ (pl. "walk" vs "run").
func _get_animation_name() -> StringName:
	match _state:
		State.IDLE:   return &"idle"
		State.RUN:    return &"run"
		State.JUMP:   return &"jump"
		State.FALL:   return &"fall"
		State.ATTACK: return &"attack"
		State.HURT:   return &"hurt"
		State.DEAD:   return &"death"
	return &"idle"

func _update_animation() -> void:
	if _sprite == null:
		return
	_sprite.play(_get_animation_name())
	_sprite.flip_h = not _facing_right

# ============================================================================
# INPUT
# ============================================================================
func _handle_action_input(event: InputEvent) -> void:
	if event.is_action_pressed("attack"):
		_do_melee_attack()
	if event.is_action_pressed("special"):
		_do_ability()
	if event.is_action_pressed("interact"):
		_request_interaction()
	if event.is_action_pressed("use_item"):
		_use_selected_item()

# ============================================================================
# MELEE TÁMADÁS
# ============================================================================
func _do_melee_attack() -> void:
	if not is_alive or _attack_cd_timer > 0.0:
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

	_attack_cd_timer = attack_cooldown

	## Kis előre lökés találatkor (üsd vissza az ellenfelet)
	if hit_count > 0:
		velocity.x += (1.0 if _facing_right else -1.0) * 40.0

	await get_tree().create_timer(0.5).timeout
	if _state == State.ATTACK:
		_state = State.IDLE

# ============================================================================
# ABILITY
# ============================================================================
func _do_ability() -> void:
	if _ability != null:
		_ability.activate()

## Hook az AbilityComponent._do_fireball() számára.
## A projectile_scene exportot az editorban kell beállítani a karakter scene-ben.
## A Projectile scene-nek implementálnia kell a setup() metódust (ld. projectile.gd).
func spawn_projectile(power: float) -> void:
	if projectile_scene == null:
		push_warning("BasePlayer: projectile_scene nincs beállítva (%s)" % entity_name)
		return
	var proj: Node = projectile_scene.instantiate()
	if proj.has_method("setup"):
		proj.setup(
			global_position,
			1.0 if _facing_right else -1.0,
			int(power),
			"enemies"
		)
	get_tree().get_current_scene().add_child(proj)

# ============================================================================
# INTERAKCIÓ / ITEM HASZNÁLAT
# ============================================================================
func _request_interaction() -> void:
	## Megkeresi a legközelebbi "interactable" csoportbeli Node2D-t,
	## és ha van "interact" metódusa, meghívja.
	var best_dist := 48.0
	var nearest: Node2D = null
	for node in get_tree().get_nodes_in_group("interactable"):
		if not (node is Node2D):
			continue
		var d := global_position.distance_to(node.global_position)
		if d <= best_dist:
			best_dist = d
			nearest = node
	if nearest and nearest.has_method("interact"):
		nearest.interact(self)

## Override-old ha a karakternek van inventory-ja (pl. PlayerKnight).
func _use_selected_item() -> void:
	pass

# ============================================================================
# SEBZÉS – minden játszható karakterre azonos logika
# ============================================================================
func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if not is_alive:
		return

	## Block sebzés csökkentés (ability_power = csökkentési arány 0.0–1.0)
	var final_amount := amount
	if is_blocking and _ability != null:
		final_amount = int(amount * (1.0 - clampf(_ability.ability_power, 0.0, 1.0)))

	## Entity alap sebzés; ha health == 0, Entity.take_damage() meghívja
	## self.die() → BasePlayer.die() → player_died + _on_died()
	super.take_damage(final_amount)
	emit_signal("character_take_damage", final_amount)
	if is_alive:
		if knockback != Vector2.ZERO:
			velocity = knockback
		_state = State.HURT
		_on_took_damage(final_amount)
		await get_tree().create_timer(0.2).timeout
		if _state == State.HURT:
			_state = State.IDLE
	else:
		_state = State.DEAD
		## die() már meghívta _on_died()-t aszinkron módon

## Vizuális / audio visszajelzés sebzéskor.
## Override-old extra effektekhez; az alap viselkedés (flash) minden karakternél megvan.
func _on_took_damage(amount: int) -> void:
	print("[%s] Sebzés: -%d | HP: %d / %d" % [entity_name, amount, health, max_health])
	_flash_sprite()

## Sprite villogás hurt animációhoz
func _flash_sprite() -> void:
	if _sprite == null:
		return
	for i in hurt_flash_count:
		_sprite.visible = false
		await get_tree().create_timer(hurt_flash_speed).timeout
		_sprite.visible = true
		await get_tree().create_timer(hurt_flash_speed).timeout

# ============================================================================
# Death
# ============================================================================
func die() -> void:
	if not is_alive:
		return
	is_alive = false
	emit_signal("player_died")
	_on_died()

func _on_died() -> void:
	print("[%s] Meghalt" % entity_name)

	## Ütközési shape letiltása, hogy ne akadjon el a halál animáció közben
	if _hitbox != null:
		_hitbox.disabled = true

	## Halál statisztika frissítés és mentés
	if GameManager != null:
		var stats: Dictionary = GameManager.runtime_data.get(GameManager.KEY_STATISTICS, {})
		stats[GameManager.KEY_DEATHS] = stats.get(GameManager.KEY_DEATHS, 0) + 1
		GameManager.runtime_data[GameManager.KEY_STATISTICS] = stats
		GameManager.save_game()

	## Rövid várakozás a halál animációhoz, majd LevelManager értesítés (újratöltés)
	await get_tree().create_timer(0.7).timeout
	queue_free()
	if is_instance_valid(self) and LevelManager != null:
		LevelManager.on_player_death()
