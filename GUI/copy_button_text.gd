extends Button

func _pressed() -> void:
	DisplayServer.clipboard_set(text)
