extends PowerScript

## POWER SCRIPT DOCUMENTATION. DO NOT UNCOMMENT
# The Card that this script is attached to (via attribute, passive, status, etc.)
#var source : Card
# Access to the full board state
#var board : Node
# board.get_global_reference(source) -> gives n for the card this associated with
# board.character[n] -> n is the playfield to target (global reference, see get_global_reference)
# board.character[n].safe_room : Array = your saferoom
# board.character[n].active : Array = currently deployed characters
# etc.


## Triggered when the associated ability or move triggers a targeting request.
## Only Interactions and Abilities can trigger this event.
func _interaction(_targets:Array[Card]) -> void:
	pass

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
