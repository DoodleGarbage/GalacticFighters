extends Control

var moves : int = 2 : 
	set(value):
		moves = value
		$Mgn/vls/mms/Moves.button_pressed = false
		$Mgn/vls/mms/Moves2.button_pressed = false
		if moves >= 1: ## There is probably a less ugly way to do this
			$Mgn/vls/mms/Moves.button_pressed = true
		if moves >= 2:
			$Mgn/vls/mms/Moves2.button_pressed = true

signal turn_ended

func _on_end_turn_pressed() -> void:
	turn_ended.emit()

func begin_turn() -> void:
	$Mgn/vls/ret/TurnIndicator.show()

func end_turn() -> void:
	$Mgn/vls/ret/TurnIndicator.hide()
