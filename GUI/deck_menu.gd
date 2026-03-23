extends Control

signal exit()

func _exit_pressed() -> void:
	exit.emit()
