extends BaseEnemy

## Ideális tartózkodási távolság a playertől
@export var preferred_distance: float = 130.0
## Nyíl sebzése (felülírja a CharacterResource.base_dmg-t)
@export var arrow_damage: int = 12
## Lövési cooldown
@export var shoot_cooldown: float = 2.0
## Nyíl sebessége (px/s)
@export var arrow_speed: float = 220.0

var _shoot_timer: float = 0.0

## A nyíl scene-t itt tárolod (assign az editorban, vagy hagyod null-on
## – null esetén csak sebzést alkalmaz, nincs vizuális lövedék)
@export var arrow_scene: PackedScene = null

func _ready() -> void:
	super._ready()
	attack_range = preferred_distance + 20.0
	aggro_range  = 180.0

func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer  = max(0.0, _attack_timer  - delta)
	_shoot_timer   = max(0.0, _shoot_timer   - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	match _state:
		State.PATROL:  _do_patrol()
		State.AGGRO:   _do_archer_movement()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)
			if _shoot_timer <= 0.0:
				_shoot_arrow()
				_shoot_timer = shoot_cooldown
				# Rövid szünet után visszaáll AGGRO-ba
				await get_tree().create_timer(0.5).timeout
				if _state == State.ATTACK:
					_set_state(State.AGGRO)
		State.HURT:    pass
		State.DEAD:    velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()

func _do_archer_movement() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	# Ha közeledik a player → hátrál
	if dist < preferred_distance - 25.0:
		var away = sign(global_position.x - _player.global_position.x)
		velocity.x = away * chase_speed
		if _sprite: _sprite.flip_h = away < 0.0
		return

	# Ha túl messze → közeledik lövőtávolságra
	if dist > preferred_distance + 25.0:
		var toward = sign(_player.global_position.x - global_position.x)
		velocity.x = toward * patrol_speed
		if _sprite: _sprite.flip_h = toward < 0.0
		return

	# Jó távolságon → megáll és lő
	velocity.x = move_toward(velocity.x, 0.0, chase_speed)
	_set_state(State.ATTACK)

func _shoot_arrow() -> void:
	if _player == null:
		return

	var dir := (_player.global_position - global_position).normalized()

	if arrow_scene != null:
		var arrow := arrow_scene.instantiate()
		if arrow.has_method("setup"):
			arrow.setup(global_position, dir, arrow_damage, arrow_speed)
		get_tree().get_current_scene().add_child(arrow)
	else:
		# Nincs scene: ha közel van, közvetlenül sebez (fallback)
		if _player and global_position.distance_to(_player.global_position) < attack_range + 30.0:
			_player.take_damage(arrow_damage, dir * 120.0)
