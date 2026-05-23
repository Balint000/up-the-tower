extends BaseEnemy

## Roham sebessége
@export var charge_speed: float = 300.0
## Roham időtartama (mp)
@export var charge_duration: float = 0.45
## Kiszeles ideje (mp) – a player látja, hogy jön a roham
@export var windup_time: float = 0.7
## Kábulás ideje roham után
@export var stun_duration: float = 0.8

var _is_charging: bool = false
var _is_stunned:  bool = false
var _charge_dir:  float = 1.0
var _charge_timer: float = 0.0
var _windup_timer: float = 0.0
var _stun_timer:   float = 0.0

func _ready() -> void:
	super._ready()
	attack_range    = 60.0
	attack_cooldown = charge_duration + windup_time + stun_duration + 0.3

func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	# Kábulat kezelése
	if _is_stunned:
		_stun_timer -= delta
		velocity.x = move_toward(velocity.x, 0.0, 400.0)
		if _stun_timer <= 0.0:
			_is_stunned = false
			_set_state(State.AGGRO)
		move_and_slide()
		return

	# Roham kezelése
	if _is_charging:
		_charge_timer -= delta
		velocity.x = _charge_dir * charge_speed

		# Falnak csapódott? → elkábul
		if get_slide_collision_count() > 0:
			for i in get_slide_collision_count():
				var col := get_slide_collision(i)
				if abs(col.get_normal().x) > 0.5:
					_end_charge(true)
					break

		if _charge_timer <= 0.0:
			_end_charge(false)

		# Sebzés ütközéskor
		if _player and global_position.distance_to(_player.global_position) <= attack_range:
			_player.take_damage(damage * 2, Vector2(_charge_dir * 350.0, -180.0))

		move_and_slide()
		return

	match _state:
		State.PATROL:   _do_patrol()
		State.AGGRO:    _do_chase()
		State.ATTACK:
			if _windup_timer > 0.0:
				_windup_timer -= delta
				velocity.x = move_toward(velocity.x, 0.0, 300.0)
			elif not _is_charging:
				_begin_charge()
		State.HURT:     pass
		State.DEAD:     velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()

## Felülírjuk a base attack-et: kiszeles → roham
func _do_attack() -> void:
	_windup_timer = windup_time
	# (az _physics_process ATTACK ágában indul a roham)

func _begin_charge() -> void:
	if _player == null:
		_set_state(State.AGGRO)
		return
	_charge_dir   = sign(_player.global_position.x - global_position.x)
	_is_charging  = true
	_charge_timer = charge_duration

func _end_charge(wall_hit: bool) -> void:
	_is_charging = false
	velocity.x   = 0.0
	if wall_hit:
		_is_stunned  = true
		_stun_timer  = stun_duration
		_set_state(State.HURT)
	else:
		_attack_timer = attack_cooldown
		_set_state(State.AGGRO)

func _update_animation() -> void:
	if _sprite == null: return
	match _state:
		State.PATROL, State.AGGRO:
			_sprite.play("walk" if abs(velocity.x) > 1.0 else "idle")
		State.ATTACK:
			# Kiszeles animáció – ha nincs "windup" frame, "idle" is megfelel
			_sprite.play("idle")
		State.HURT:
			_sprite.play("hurt" if not _is_stunned else "hurt")
		State.DEAD:
			_sprite.play("death")
