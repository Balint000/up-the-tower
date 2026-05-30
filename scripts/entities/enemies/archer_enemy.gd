## @class ArcherEnemy
## @brief Íjász ellenség, aki lövedékekkel (EnemyArrow) támad a játékosra.
##
## Preferált távolságot tart a playertől: ha a player közelít, hátrál;
## ha túl messze van, közeledik. A megfelelő távolságon megáll és nyilat lő.
## Az arrow_scene exportot az editorban kell beállítani; enélkül a karakter
## nem támad (push_warning jelzi a hiányt, nincs beégetett fallback).
class_name ArcherEnemy
extends BaseEnemy

## @export preferred_distance
## @brief Ideális tartózkodási távolság a playertől (pixelben).
@export var preferred_distance: float = 130.0

## @export arrow_damage
## @brief A kilőtt nyíl sebzése (felülírja a CharacterResource.base_dmg-t).
@export var arrow_damage: int = 12

## @export shoot_cooldown
## @brief Lövések közötti minimális várakozási idő (másodperc).
@export var shoot_cooldown: float = 2.0

## @export arrow_speed
## @brief A nyíl repülési sebessége (px/s).
@export var arrow_speed: float = 220.0

## @export arrow_scene
## @brief A kilőtt nyíl PackedScene-je. Editorban kötelező beállítani!
@export var arrow_scene: PackedScene = null

## @var _shoot_timer
## @brief Lövési visszaszámláló; 0 alatt engedélyezett az újabb lövés.
var _shoot_timer: float = 0.0


## @brief Inicializálás: attack_range és aggro_range beállítása.
func _ready() -> void:
	super._ready()
	attack_range = preferred_distance + 20.0
	aggro_range  = 180.0


## @brief Fizikai frissítés: állapotgép vezérlése, mozgás, animáció.
## @param delta Frame idő másodpercekben.
func _physics_process(delta: float) -> void:
	if not is_alive:
		_state = State.DEAD
		_update_animation()
		return

	_attack_timer = max(0.0, _attack_timer - delta)
	_shoot_timer  = max(0.0, _shoot_timer  - delta)

	if not is_on_floor():
		velocity.y += gravity * delta

	match _state:
		State.PATROL: _do_patrol()
		State.AGGRO:  _do_archer_movement()
		State.ATTACK:
			velocity.x = move_toward(velocity.x, 0.0, chase_speed)
			if _shoot_timer <= 0.0:
				_shoot_arrow()
				_shoot_timer = shoot_cooldown
				await get_tree().create_timer(0.5).timeout
				if _state == State.ATTACK:
					_set_state(State.AGGRO)
		State.HURT: pass
		State.DEAD: velocity = Vector2.ZERO

	move_and_slide()
	_check_aggro()
	_update_animation()


## @brief Archer-specifikus mozgáslogika: preferált távolság tartása.
func _do_archer_movement() -> void:
	if _player == null:
		_set_state(State.PATROL)
		return

	var dist := global_position.distance_to(_player.global_position)

	if dist > lose_aggro_range:
		_set_state(State.PATROL)
		return

	# Player túl közel → hátrálás
	if dist < preferred_distance - 25.0:
		var away = sign(global_position.x - _player.global_position.x)
		velocity.x = away * chase_speed
		if _sprite:
			_sprite.flip_h = away < 0.0
		return

	# Player túl messze → közeledés lövőtávolságra
	if dist > preferred_distance + 25.0:
		var toward = sign(_player.global_position.x - global_position.x)
		velocity.x = toward * patrol_speed
		if _sprite:
			_sprite.flip_h = toward < 0.0
		return

	# Megfelelő távolságon → megáll és lő
	velocity.x = move_toward(velocity.x, 0.0, chase_speed)
	_set_state(State.ATTACK)


## @brief Nyíl kilövése a player irányába.
## Ha arrow_scene nincs beállítva, push_warning jelzi és abbahagyja (nincs fallback).
func _shoot_arrow() -> void:
	if _player == null:
		return

	if arrow_scene == null:
		push_warning("ArcherEnemy: arrow_scene nincs beállítva! Töltsd be az editorban.")
		return

	var dir := (_player.global_position - global_position).normalized()
	var arrow := arrow_scene.instantiate()
	if arrow.has_method("setup"):
		arrow.setup(global_position, dir, arrow_damage, arrow_speed)
	get_tree().get_current_scene().add_child(arrow)
