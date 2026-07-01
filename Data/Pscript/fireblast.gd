extends PowerScript

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card_GUI]) -> void:
	for target in _targets:
		target.apply_status("Fire")

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
