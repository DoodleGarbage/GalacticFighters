extends Resource
class_name PowerScript
## The Card that this script is attached to (via attribute, passive, status, etc.)
var source : Card
## Access to the full board
var board : Node
# board.get_global_reference(source) -> gives n for the card this associated with
# board.ally[n] -> n is the player to target (global reference, not local)
# board.ally[n].safe_room = your saferoom
# board.ally[n].active = currently deployed characters
# board.enemy[n] -> same as ally for the opposing character

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card]) -> void:
	pass

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
