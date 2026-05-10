## FlyingEnemy – Gravity nélküli, lebegő ellenfél.
## Szinuszhullámban repül patrol közben, majd a playert követi aggróban.
## Érintésre sebez, nincs külön melee animáció szükséges.
extends BaseEnemy

@export var float_speed: float = 55.0
@export var vertical_amplitude: float = 28.0
@export var vertical_frequency: float = 2.2

var _time: float = 0.0

func _ready() -> void:
	super._ready()
	gravity = 0.0          # nincs gravitáció
	attack_range = 18.0    # érintéses sebzés → kis range
	attack_cooldown = 0.8
	aggro_range = 130.0

func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)
	_time += delta

	match _state:
		State.PATROL:   _do_flying_patrol()
		State.AGGRO:    _do_flying_chase()
		State.ATTACK:   _do_contact_attack()
		State.HURT:     pass
		State.DEAD:     velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()

func _do_flying_patrol() -> void:
	# Akadályok esetén irányt vált (raycast alapú, örökölt logika)
	if _dir > 0.0 and _ray_right and _ray_right.is_colliding():
		_dir = -1.0
	elif _dir < 0.0 and _ray_left and _ray_left.is_colliding():
		_dir = 1.0

	velocity.x = _dir * float_speed
	velocity.y = sin(_time * vertical_frequency) * vertical_amplitude
	if _sprite:
		_sprite.flip_h = _dir < 0.0

func _do_flying_chase() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	if dist <= attack_range:
		_set_state(State.ATTACK)
		return

	# Egyenesen a player felé repül
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	if _sprite:
		_sprite.flip_h = dir.x < 0.0

func _do_contact_attack() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist > attack_range + 5.0:
		_set_state(State.AGGRO)
		return

	if _attack_timer <= 0.0 and _player.is_alive:
		_player.take_damage(damage, Vector2.ZERO)
		_attack_timer = attack_cooldown

func _update_animation() -> void:
	if _sprite == null:
		return
	match _state:
		State.PATROL, State.AGGRO, State.ATTACK:
			_sprite.play("walk")   # repülő animáció (walk frame-eket használjuk)
		State.HURT:
			_sprite.play("hurt")
		State.DEAD:
			_sprite.play("death")
