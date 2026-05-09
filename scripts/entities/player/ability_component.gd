class_name AbilityComponent
extends Node2D
## Képességek kezelése – dash, double_jump, block, fireball.
##
## A BasePlayer tartalmaz egy _ability: AbilityComponent referenciát.
## Az activate() metódus minden frame-re meghívódik, ha a "special" akció
## le van nyomva. A setup() a CharacterResource alapján konfigurálja.
##
## Képességek leírása:
##   dash        → vízszintes impulzus a néző irányába
##   double_jump → légben extra ugrás (ability_power = ugrás erő)
##   block       → 0.6s sebzés csökkentés (ability_power = csökkentési arány 0.0–1.0)
##   fireball    → projektil indítás (BasePlayer.spawn_projectile() hook-on át)

var _player: BasePlayer = null

var ability_type: String    = "none"
var ability_cooldown: float = 0.0
var ability_power: float    = 0.0
var _cd_timer: float        = 0.0

signal ability_used(type: String)
signal ability_ready()

# ---------------------------------------------------------------------------
# Inicializálás
# ---------------------------------------------------------------------------
func setup(player: BasePlayer, res: CharacterResource) -> void:
	_player          = player
	ability_type     = res.ability_type
	ability_cooldown = res.ability_cooldown
	ability_power    = res.ability_power

# ---------------------------------------------------------------------------
# Tick – cooldown visszaszámlálás
# ---------------------------------------------------------------------------
func tick(delta: float) -> void:
	var was_ready := _cd_timer <= 0.0
	_cd_timer = max(0.0, _cd_timer - delta)
	if not was_ready and _cd_timer <= 0.0:
		emit_signal("ability_ready")

func is_ready() -> bool:
	return _cd_timer <= 0.0

# ---------------------------------------------------------------------------
# Aktiválás
# ---------------------------------------------------------------------------
func activate() -> void:
	if ability_type == "none" or not is_ready() or _player == null:
		return
	match ability_type:
		"dash":        _do_dash()
		"double_jump": _do_double_jump()
		"block":       _do_block()
		"fireball":    _do_fireball()
	_cd_timer = ability_cooldown
	emit_signal("ability_used", ability_type)

# ---------------------------------------------------------------------------
# DASH
## Vízszintes impulzus a néző irányába.
## BasePlayer._is_dashing flag-gel a _handle_movement()-ben prioritást kap
## (a normál mozgás le van tiltva a dash ideje alatt).
## ability_power = impulzus erőssége (px/s)
# ---------------------------------------------------------------------------
func _do_dash() -> void:
	var dir := 1.0 if _player._facing_right else -1.0
	_player.velocity.x  = dir * ability_power
	_player._is_dashing = true
	_player._dash_timer = _player.dash_duration

# ---------------------------------------------------------------------------
# DOUBLE JUMP
## Csak levegőben aktív; a földön állva a normál ugrás használható.
## ability_power = felfelé irányú impulzus erőssége (px/s)
# ---------------------------------------------------------------------------
func _do_double_jump() -> void:
	if not _player.is_on_floor():
		_player.velocity.y = -absf(ability_power)

# ---------------------------------------------------------------------------
# BLOCK
## 0.6 másodpercig csökkenti a beérkező sebzést.
## BasePlayer.take_damage() az is_blocking flag alapján alkalmazza a csökkentést.
## ability_power = sebzés csökkentési arány (0.0 = nincs csökkentés, 1.0 = teljes blokk)
## Ajánlott érték: 0.5 (50%-os csökkentés)
# ---------------------------------------------------------------------------
func _do_block() -> void:
	_player.is_blocking = true
	await _player.get_tree().create_timer(0.6).timeout
	## Ellenőrzés: a játékos nem halt meg közben
	if is_instance_valid(_player):
		_player.is_blocking = false

# ---------------------------------------------------------------------------
# FIREBALL
## Projektilt indít a néző irányába.
## BasePlayer.spawn_projectile() kezeli az instanciálást és az elhelyezést.
## A projectile_scene exportot a karakter scene-ben kell beállítani az editorban.
## ability_power = a projektil sebzése
# ---------------------------------------------------------------------------
func _do_fireball() -> void:
	_player.spawn_projectile(ability_power)
