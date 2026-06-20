@abstract class_name PowerScript extends GDScript
## The Card that this script is attached to (via attribute, passive, status, etc.)
var source : Card_GUI
## Access to the full board
var board : Node
# board.get_global_reference(source) -> gives n for the card this associated with
# board.ally[n] -> n is the player to target (global reference, not local)
# board.ally[n].safe_room = your saferoom
# board.ally[n].active = currently deployed characters
# board.enemy[n] -> same as ally for the opposing character


func _init(input:Array) -> void:
	source = input[0]

# Virtual Functions - Override in extensions

## Triggered when the power script is activated (such as using an ability).
func _interaction(_targets:Array[Card_GUI]) -> void:
	pass

## Called at the start of the game turn
func _turnstart() -> void:
	pass

## Called when the turn ends.
func _turnend() -> void:
	pass
