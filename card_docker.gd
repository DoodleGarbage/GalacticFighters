extends Control

class_name Docker

## Which player this docker belongs to
@export
var player : int = -1

## A unique id used for communicating which node is being touched between clients/server - please set this manually and make it a different id from all other dockers to avoid strange bugs.
@export
var id : int = 0

@export
var identifier : String = ""

## Whether or not this card is owned/controlled by this client (relative to player)
@export
var player_controlled : bool = false

## Maximum number of cards that can be assigned to this docker
var max_cards : int = -1
var assigned_cards : Array[Card_GUI] = [] :
	set(value):
		card_assignment_changed(assigned_cards, value)
		assigned_cards = value

func card_assignment_changed(_before, _after) -> void:
	pass

## When -1 or less, default to getting the placements for the currently assigned cards.
func get_placements(_number_of_cards:int=-1) -> Array[Vector2]:
	return []
