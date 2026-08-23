@abstract class_name PowerScript extends GDScript


## The Card that this script is attached to (via attribute, passive, status, etc.)
## - Use this for retrieving data and information about the card
var source : Card_GUI
## This is a reference to the resource this script is attached to
var ability : Attribute
## This is initalized when the attribute scripts are initalized, and is the active tracker for the duration of this attribute's turns
var duration_tracker : int = -1

var stacks : int = 1

const built_in_data : Array[StringName] = ["duration_tracker", "stacks"]
## TODO: Assign this during Resource loading
var sync_data : Array[StringName] = []

func get_data() -> Array:
	var data : Array = []
	for variable in built_in_data + sync_data:
		data.append([variable, get(variable)])
	return data

func set_data(data:Array) -> void:
	for datum in data:
		set(datum[0], datum[1])

func _init(src, input:Dictionary={}) -> void:
	source = src
	for key in input.keys():
		set(key, input[key])

func get_splash(manager:Docker, manager_position:int, radius:int) -> Array[DockerChild]:
	var reslt : Array[DockerChild] = []
	for card in manager.assigned_cards:
		if card.manager_position <= manager_position+radius and card.manager_position >= manager_position-radius:
			reslt.append(card)
	return reslt


# Virtual Functions - Override in extensions

## Called when the card this script/ability is attached to is first created.
# Not currently implemented
func _initialized() -> void:
	pass

## Called when the power script is activated (primarily, when using an ability).
func _interaction(_targets:Array[Card_GUI]) -> void:
	pass

## Called at the start of the player's turn.
func _turnstart() -> void:
	pass

## Called when the player's turn ends.
func _turnend() -> void:
	pass
