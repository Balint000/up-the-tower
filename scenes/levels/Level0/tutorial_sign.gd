extends Area2D

var message: String

func _on_body_entered(body: Node2D) -> void:
	NotificationManager.show_message(message)

func _set_message(text: String) -> void:
	message = text
