## playerKnight.gd
## ==========================================================================
## Lovag karakter – a BasePlayer konkrét implementációja.
##
## Felülírt metódusok:
##   _on_ready()           – lovag-specifikus értékek, GameManager stat skálázás
##   _do_attack()          – hatótávolság-alapú közelharc + knockback
##   _handle_action_input()– Shift = dash képesség
##   _get_animation_name() – animáció nevek mappelés
##   _on_took_damage()     – sebzés flash effekt (sprite villogás)
##   _on_died()            – halál → LevelManager értesítés
##
## Scene: scenes/entities/player/MainCharacter.tscn
##   CharacterBody2D   ← ez a script csatolva
##   ├── AnimatedSprite2D
##   └── CollisionShape2D
## ==========================================================================

extends BasePlayer

# ---------------------------------------------------------------------------
# Lovag-specifikus konstansok
# ---------------------------------------------------------------------------

# const KNIGHT_SPEED:       float = 120.0
# const KNIGHT_JUMP_VEL:    float = -300.0
# const KNIGHT_HEALTH:      int   = 100
# const KNIGHT_DAMAGE:      int   = 10
const KNIGHT_ATTACK_RANGE: float = 50.0  ## px – közelharc ellenőrzési sugár

# ---------------------------------------------------------------------------
# Dash képesség (Shift)
# ---------------------------------------------------------------------------

## Dash vízszintes impulzus (px/s).
@export var dash_impulse: float     = 600.0
## Dash időtartama (másodperc) – ennyi ideig hat az impulzus.
@export var dash_duration: float    = 0.18
## Dash újratöltési idő (másodperc).
@export var dash_cooldown: float    = 1.20

var _dash_timer:    float = 0.0   # aktív dash visszaszámlálás
var _dash_cd_timer: float = 0.0   # cooldown visszaszámlálás
var _is_dashing:    bool  = false

# ---------------------------------------------------------------------------
# Életerő flash effekt (hurt visszajelzés)
# ---------------------------------------------------------------------------

## Hány alkalommal villog a sprite sebzéskor.
@export var hurt_flash_count: int   = 4
## Egy villanás fél-periódusa (másodperc).
@export var hurt_flash_speed: float = 0.07

# ---------------------------------------------------------------------------
# _on_ready – BasePlayer hook
# ---------------------------------------------------------------------------

func _on_ready() -> void:
	# Alap értékek beállítása mielőtt az _apply_stats() GameManager szorzókat alkalmaz
	# speed        = KNIGHT_SPEED
	# jump_velocity = KNIGHT_JUMP_VEL
	# max_health   = KNIGHT_HEALTH
	# base_damage  = KNIGHT_DAMAGE

	# stat-ok újra skálázása a frissített base értékekkel
	# _apply_stats()
	# current_health = max_health

	print("[Knight] Init – HP: %d / %d | DMG: %d | SPD: %.0f" % [
		current_health, max_health, _damage, speed
	])

# ---------------------------------------------------------------------------
# _on_physics_process – dash timer kezelés
# ---------------------------------------------------------------------------

func _on_physics_process(delta: float) -> void:
	_dash_cd_timer = max(0.0, _dash_cd_timer - delta)

	if _is_dashing:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			_is_dashing = false

# ---------------------------------------------------------------------------
# Input – dash hozzáadása a Shift gombra
# ---------------------------------------------------------------------------

## Felülírja a szülő akció inputját: megtartja az attack-ot, hozzáadja a dash-t.
func _handle_action_input() -> void:
	super._handle_action_input()   # alap attack megtartása

	if Input.is_action_just_pressed("special") and _dash_cd_timer <= 0.0 and not is_dead:
		_do_dash()

# ---------------------------------------------------------------------------
# Dash implementáció
# ---------------------------------------------------------------------------

func _do_dash() -> void:
	_is_dashing    = true
	_dash_timer    = dash_duration
	_dash_cd_timer = _ability_cooldown

	# Dash irány = jelenlegi nézési irány
	var dir := 1.0 if _facing_right else -1.0
	velocity.x = dir * _ability_power

# ---------------------------------------------------------------------------
# Támadás – felülírt közelharc + knockback
# ---------------------------------------------------------------------------

## Felülírja a szülő _do_attack()-ját:
## minden "enemies" csoportban lévő ellenséget sebez a hatótávon belül,
## és knockback-et alkalmaz a lovag iránya alapján.
func _do_attack() -> void:
	var hit_count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if global_position.distance_to(enemy.global_position) <= KNIGHT_ATTACK_RANGE:
			if enemy.has_method("take_damage"):
				enemy.take_damage(_damage)
				hit_count += 1

	if hit_count > 0:
		# Lovag lendülete: kis előre-impulzus támadáskor
		var fwd := 1.0 if _facing_right else -1.0
		velocity.x += fwd * 40.0

# ---------------------------------------------------------------------------
# Animáció – lovag sprite sheet névkonvenció
# ---------------------------------------------------------------------------

## Felülírja a szülő _get_animation_name()-jét.
## A Soldier sprite sheet: idle, walk, attack, hurt, death
## (nincs külön jump / fall frame → idle fallback marad)
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
# Hurt reakció – sprite flash effekt
# ---------------------------------------------------------------------------

## Felülírja a szülő _on_took_damage()-jét: sprite villogás + print.
func _on_took_damage(amount: int) -> void:
	print("[Knight] Sebzés: -%d | HP: %d / %d" % [amount, current_health, max_health])
	_flash_sprite()


## Sprite villogás coroutine a sebezhetetlen idő alatt.
func _flash_sprite() -> void:
	for i in hurt_flash_count:
		_sprite.visible = false
		await get_tree().create_timer(hurt_flash_speed).timeout
		_sprite.visible = true
		await get_tree().create_timer(hurt_flash_speed).timeout

# ---------------------------------------------------------------------------
# Halál – felülírt LevelManager értesítéssel
# ---------------------------------------------------------------------------

## Felülírja a szülő _on_died()-jét:
## halál animáció → rövid várakozás → LevelManager értesítése.
func _on_died() -> void:
	print("[Knight] Meghalt – LevelManager értesítve")
	set_collision_layer_value(1, false)   # átjárhatóvá teszi a holttestet
	# Rövid szünet hogy a death animáció lejátsszódjon
	await get_tree().create_timer(0.7).timeout
	LevelManager.on_player_death()

# ---------------------------------------------------------------------------
# Stat skálázás – GameManager stat szorzók alkalmazása
# ---------------------------------------------------------------------------
