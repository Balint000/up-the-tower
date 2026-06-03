extends Node2D

@onready var container = $Panel/CharacterContainer

var current_character: Node = null

func show_character(char_data: CharacterResource) -> void:

	if current_character:
		current_character.queue_free()
		current_character = null

	if char_data == null:
		return

	if char_data.scene_path == "":
		return

	var scene = load(char_data.scene_path)
	if scene == null:
		return

	current_character = scene.instantiate()
	container.add_child(current_character)
	
	if current_character is CharacterBody2D:
		# Kikapcsoljuk a teljes processzt, hogy ne fusson a _physics_process (mozgás/gravitáció)
		current_character.set_physics_process(false)
		current_character.set_process(false)
		
		# Opcionális: Ha vannak ütközések (CollisionShape2D), azokat is lelőhetjük
		for child in current_character.get_children():
			if child is CollisionShape2D:
				child.disabled = true

	_play_idle(current_character)

func _play_idle(character: Node) -> void:

	var sprite := character.find_child("AnimatedSprite2D", true, false)

	if sprite and sprite is AnimatedSprite2D:
		sprite.play("idle")
