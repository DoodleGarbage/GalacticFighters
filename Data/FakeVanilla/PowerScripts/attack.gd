extends PowerScript

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card_GUI]) -> void:
	for target in _targets:
		if not is_instance_valid(target):
			continue
		target.damage(ability, source.attack)

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
