## boss.gd
## ==========================================================================
## Boss – kétfázisú főellenség, az aktuális enemy-architektúrára illesztve.
##
## Öröklési lánc:  Boss → BaseEnemy → Entity → CharacterBody2D
##
## ── Phase 1 (HP > 50 %) ────────────────────────────────────────────────────
##   Lassú, kitartó üldözés + közelharci támadás.
##   Egyszerű AI: megtalálja a playert, követ, üt.
##
## ── Phase 2 (HP ≤ 50 %) ────────────────────────────────────────────────────
##   Gyorsabb mozgás. Két új speciális akció váltakozhat:
##   • JUMP   – ugrik a játékos fölé, landoláskor sebez
##   • CHARGE – rövid wind-up → zárolt irányú gyors dash → recovery
##              (ChargerEnemy logikájára épül)
##
## Szükséges scene-felépítés (a .tscn-t a fejlesztő készíti):
##   Boss (CharacterBody2D)
##   ├── AnimatedSprite2D
##   │     clips: idle, walk, attack, hurt, death
##   │     opcionális: jump, charge, windup
##   ├── CollisionShape2D
##   ├── RayCastRight  (BaseEnemy patrol raycast – bossnak nem muszáj)
##   └── RayCastLeft
##
## EnemySpawner-rel is használható: a class BaseEnemy leszármazott, így
## scene.instantiate() as BaseEnemy működik rá.
## ==========================================================================
class_name Boss
extends BaseEnemy

# ── Fázis nyilvántartás ─────────────────────────────────────────────────────

## Aktuális harci fázis (1 vagy 2).
var _phase: int = 1

## Megakadályozza, hogy a Phase 2 átmenet kétszer fusson le.
var _phase2_triggered: bool = false

# ── Phase 1 beállítások ─────────────────────────────────────────────────────

@export_group("Phase 1")

## Követési sebesség Phase 1-ben (px/s).
@export var p1_speed: float = 60.0

## Közelharci hatótáv Phase 1-ben (px).
@export var p1_attack_range: float = 40.0

## Ütések közötti idő Phase 1-ben (s).
@export var p1_attack_cooldown: float = 1.8

# ── Phase 2 alap beállítások ────────────────────────────────────────────────

@export_group("Phase 2")

## Követési sebesség Phase 2-ben (px/s).
@export var p2_speed: float = 110.0

## Közelharci hatótáv Phase 2-ben (px).
@export var p2_attack_range: float = 45.0

## Ütések közötti idő Phase 2-ben (s).
@export var p2_attack_cooldown: float = 0.8

# ── Ugrótámadás (Phase 2) ───────────────────────────────────────────────────

@export_group("Jump Attack (Phase 2)")

## Ugróakciók közötti minimális idő (s).
@export var jump_interval: float = 4.0

## Felfelé irányuló induló sebesség az ugrásnál (negatív = felfelé).
@export var jump_up_velocity: float = -380.0

## Vízszintes sebesség a player felé ugráskor (px/s).
@export var jump_h_speed: float = 270.0

# ── Charge támadás (Phase 2) ────────────────────────────────────────────────

@export_group("Charge Attack (Phase 2)")

## Charge-ok közötti minimális idő (s).
@export var charge_interval: float = 6.0

## Wind-up (előkészítési) animáció időtartama (s).
@export var charge_windup_time: float = 0.9

## Vízszintes dash sebesség (px/s).
@export var charge_speed: float = 490.0

## Dash maximális időtartama (s).
@export var charge_duration: float = 0.5

## Sebzésszorzó a dash alatt (base damage * ez).
@export var charge_dmg_multiplier: float = 2.0

## Recovery (szünet) a sikeres charge után (s).
@export var charge_recovery_time: float = 0.65

## Stun időtartam, ha a charge falba ütközik (s).
@export var charge_wall_stun: float = 2

# ── Futásidejű állapotváltozók ──────────────────────────────────────────────

## True, amíg a boss ugróívben van.
var _is_jumping: bool = false
## Rögzített vízszintes irány az ugráshoz (1 = jobb, -1 = bal).
var _jump_dir: float = 1.0
## Előző frame-ben padlón állt-e (landolás detektáláshoz).
var _was_on_floor: bool = true

## True a charge előtti wind-up alatt.
var _is_winding_up: bool = false
## Hátralévő wind-up idő (s).
var _windup_timer: float = 0.0

## True az aktív dash alatt.
var _is_charging: bool = false
## Rögzített irány a chargehoz – indítás után nem változhat.
var _charge_dir: float = 1.0
## Hátralévő charge idő (s).
var _charge_timer: float = 0.0
## True, ha a charge ebben a dashban már sebzett playert
## (megakadályozza a frame-enkénti többszörös sebzést).
var _charge_hit_player: bool = false

## True a charge utáni recovery szünet alatt.
var _is_recovering: bool = false
## Hátralévő recovery / stun idő (s).
var _recovery_timer: float = 0.0

## Cooldown az ugrótámadásig (s).
var _jump_cd: float = 3.0

## Cooldown a következő charge-ig (s).
## Kezdeti eltolás, hogy az első jump és charge ne egyszerre activálódjon.
var _charge_cd: float = 6.0

# ── Signalok ────────────────────────────────────────────────────────────────

## Kiadódik, amikor a boss fázist vált.
signal phase_changed(new_phase: int)

## Kiadódik, amikor a boss meghal (queue_free előtt).
signal boss_died()

# ── Ready ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	super._ready()

	# Phase 1 statisztikák alkalmazása.
	attack_range     = p1_attack_range
	attack_cooldown  = p1_attack_cooldown
	chase_speed      = p1_speed
	aggro_range      = 230.0
	lose_aggro_range = 550.0

	# A boss rögtön üldözni kezd – nem patroloz.
	_set_state(State.AGGRO)

# ── Fő fizikai loop ──────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	# Cooldown tick.
	_attack_timer = max(0.0, _attack_timer - delta)

	# Gravitáció.
	if not is_on_floor():
		velocity.y += gravity * delta

	# Fázisátmenet ellenőrzése minden frame-ben.
	_tick_phase_transition()

	# Phase 2 speciális cooldownok.
	if _phase == 2:
		_jump_cd   = max(0.0, _jump_cd   - delta)
		_charge_cd = max(0.0, _charge_cd - delta)

	# ── Prioritásos speciális állapotok (legmagasabb prioritástól) ───────────

	# 1. Recovery / wall stun – boss nem tud mozogni.
	if _is_recovering:
		_recovery_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 700.0)
		if _recovery_timer <= 0.0:
			_is_recovering = false
			_set_state(State.AGGRO)
		move_and_slide()
		_update_animation()
		return

	# 2. Aktív charge dash – irány zárolt.
	if _is_charging:
		_charge_timer -= delta
		velocity.x = _charge_dir * charge_speed

		# Fal ütközés → stun.
		for i in get_slide_collision_count():
			var col := get_slide_collision(i)
			if abs(col.get_normal().x) > 0.5:
				_end_charge(true)
				move_and_slide()
				_update_animation()
				return

		# Player eltalálása – csak egyszer per charge.
		if not _charge_hit_player and _player != null \
				and global_position.distance_to(_player.global_position) <= attack_range + 20.0:
			_charge_hit_player = true
			if _player.has_method("take_damage"):
				_player.take_damage(
					int(damage * charge_dmg_multiplier),
					Vector2(_charge_dir * 370.0, -210.0)
				)
			_end_charge(false)
			move_and_slide()
			_update_animation()
			return

		if _charge_timer <= 0.0:
			_end_charge(false)

		move_and_slide()
		_update_animation()
		return

	# 3. Wind-up (charge előkészítése) – boss lassul, telegrafál.
	if _is_winding_up:
		_windup_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 700.0)
		if _windup_timer <= 0.0:
			_is_winding_up = false
			_begin_charge()
		move_and_slide()
		_update_animation()
		return

	# ── Normál állapotgép ────────────────────────────────────────────────────

	match _state:
		State.PATROL:
			# Boss nem patroloz; amint megvan a player, üldöz.
			if _player != null:
				_set_state(State.AGGRO)
			else:
				velocity.x = move_toward(velocity.x, 0.0, chase_speed)

		State.AGGRO:
			_do_boss_aggro()

		State.ATTACK:
			# Melee ütés közben lassulás.
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)

		State.HURT:
			# A knockback velocity-t a take_damage állítja be.
			pass

		State.DEAD:
			velocity = Vector2.ZERO

	move_and_slide()

	# ── Landolás detektálása (jump attack vége) ──────────────────────────────
	if _is_jumping and is_on_floor() and not _was_on_floor:
		_on_jump_land()

	_was_on_floor = is_on_floor()
	_check_aggro()
	_update_animation()

# ── Fázisátmenet ─────────────────────────────────────────────────────────────

## Minden frame ellenőrzi, hogy le kell-e váltani Phase 2-re.
func _tick_phase_transition() -> void:
	if _phase2_triggered or max_health <= 0:
		return
	if float(health) / float(max_health) <= 0.5:
		_enter_phase_2()


## Phase 2 aktiválása: statisztikák frissítése + signal kiadása.
func _enter_phase_2() -> void:
	_phase2_triggered = true
	_phase = 2

	chase_speed     = p2_speed
	attack_range    = p2_attack_range
	attack_cooldown = p2_attack_cooldown

	# Rövid stagger a fázisváltásnál.
	_set_state(State.HURT)
	velocity = Vector2.ZERO

	print("[Boss] PHASE 2")
	phase_changed.emit(2)

# ── Boss AGGRO mozgáslogika ──────────────────────────────────────────────────

## Üldöző viselkedés. Phase 2-ben speciális akciókat is indít.
func _do_boss_aggro() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist: float = global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	# Közelharci támadás prioritással.
	if dist <= attack_range and _attack_timer <= 0.0:
		_set_state(State.ATTACK)
		_do_attack()
		return

	# Phase 2 speciális akciók.
	if _phase == 2:
		# Ugrótámadás: levegőben lévő boss nem ugorhat újra.
		if _jump_cd <= 0.0 and not _is_jumping and is_on_floor() \
				and dist > attack_range + 15.0:
			_begin_jump()
			return

		# Charge: csak ha a player távolabb van, és nem ugrik éppen.
		if _charge_cd <= 0.0 and not _is_jumping \
				and dist > attack_range + 55.0:
			_begin_windup()
			return

	# Alapmozgás: egyenesen a player felé.
	var move_dir = sign(_player.global_position.x - global_position.x)
	velocity.x = move_dir * chase_speed
	if _sprite:
		_sprite.flip_h = move_dir < 0.0

# ── Ugrótámadás ──────────────────────────────────────────────────────────────

## Elindítja a boss ugrótámadását a player irányába.
func _begin_jump() -> void:
	if _player == null:
		return

	_is_jumping   = true
	_jump_dir     = sign(_player.global_position.x - global_position.x)
	velocity.x    = _jump_dir * jump_h_speed
	velocity.y    = jump_up_velocity
	_jump_cd      = jump_interval

	if _sprite:
		_sprite.flip_h = _jump_dir < 0.0


## Meghívódik, amikor a boss az ugrótámadás után talajt ér.
## Közelség esetén sebez egyet.
func _on_jump_land() -> void:
	_is_jumping = false
	if _player != null \
			and global_position.distance_to(_player.global_position) <= attack_range + 35.0:
		if _player.has_method("take_damage"):
			_player.take_damage(damage, Vector2(_jump_dir * 200.0, -160.0))

# ── Charge támadás ────────────────────────────────────────────────────────────

## Elindítja a charge előkészítési fázisát (wind-up / telegraf).
func _begin_windup() -> void:
	_set_state(State.ATTACK)
	_is_winding_up = true
	_windup_timer  = charge_windup_time
	_charge_cd     = charge_interval   # cooldown azonnal indul, hogy ne loop-oljon


## Wind-up után elindítja az aktív dasht. Az irány itt zárolódik.
func _begin_charge() -> void:
	if _player == null:
		_set_state(State.AGGRO)
		return

	attack_range = 25
	_charge_dir        = sign(_player.global_position.x - global_position.x)
	_is_charging       = true
	_charge_timer      = charge_duration
	_charge_hit_player = false

	if _sprite:
		_sprite.flip_h = _charge_dir < 0.0


## Lezárja a charge dasht.
## [param wall_hit] true, ha fal ütközés állította meg.
func _end_charge(wall_hit: bool) -> void:
	_is_charging = false
	velocity.x   = 0.0
	attack_range = p2_attack_range

	if wall_hit:
		# Falba csapódás → hosszabb stun.
		_set_state(State.HURT)
		_is_recovering  = true
		_recovery_timer = charge_wall_stun
	else:
		# Tiszta charge vége → rövid recovery szünet.
		_is_recovering  = true
		_recovery_timer = charge_recovery_time
		_set_state(State.AGGRO)

# ── Animáció ──────────────────────────────────────────────────────────────────

func _update_animation() -> void:
	if _sprite == null:
		return

	# A speciális állapotok felülírják a normál animációkat.
	if _is_charging:
		var clip: StringName = &"charge" \
			if _sprite.sprite_frames.has_animation("charge") else &"walk"
		_sprite.play(clip)
		return

	if _is_winding_up:
		var clip: StringName = &"windup" \
			if _sprite.sprite_frames.has_animation("windup") else &"idle"
		_sprite.play(clip)
		return

	if _is_jumping:
		var clip: StringName = &"jump" \
			if _sprite.sprite_frames.has_animation("jump") else &"walk"
		_sprite.play(clip)
		return

	if _is_recovering:
		_sprite.play("hurt")
		return

	match _state:
		State.PATROL, State.AGGRO:
			_sprite.play("walk" if abs(velocity.x) > 1.0 else "idle")
		State.ATTACK:
			_sprite.play("attack")
		State.HURT:
			_sprite.play("hurt")
		State.DEAD:
			_sprite.play("death")

# ── Halál ─────────────────────────────────────────────────────────────────────

## Felülírja a BaseEnemy._on_died()-t: hosszabb halálanimáció +
## pályateljesítés jelzése a LevelManagernek.
func _on_died() -> void:
	boss_died.emit()
	print("[Boss] Legyőzve!")

	if GameManager != null:
		var stats: Dictionary = GameManager.runtime_data.get(
			GameManager.KEY_STATISTICS, {}
		)
		stats[GameManager.KEY_KILLS] = stats.get(GameManager.KEY_KILLS, 0) + 1
		GameManager.runtime_data[GameManager.KEY_STATISTICS] = stats

	await get_tree().create_timer(2.0).timeout

	if not is_instance_valid(self):
		return

	# Pályateljesítés → LevelManager átlép a következő pályára.
	if LevelManager != null:
		LevelManager.on_level_complete()
	else:
		queue_free()
