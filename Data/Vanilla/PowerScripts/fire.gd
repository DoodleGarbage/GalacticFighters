extends PowerScript

@export var damage : int = 2

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card_GUI]) -> void:
	pass

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	source.damage(ability, damage)
