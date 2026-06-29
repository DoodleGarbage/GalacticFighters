extends Panel

var moves : int = 2 : 
	set(value):
		moves = value
		$HBoxContainer/Moves.button_pressed = false
		$HBoxContainer/Moves2.button_pressed = false
		if moves >= 1:
			$HBoxContainer/Moves.button_pressed = true
		if moves >= 2:
			$HBoxContainer/Moves2.button_pressed = true

signal turn_ended

func _on_end_turn_pressed() -> void:
	turn_ended.emit()

func begin_turn() -> void:
	$YourTurn.show()
