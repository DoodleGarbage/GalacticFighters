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

## Whether or not cards should be re-ordered (compressed together) on update or should maintain the same positions
@export
var ordering_matters : bool = false

## Maximum number of cards that can be assigned to this docker - not enforced
@export
var max_cards : int = -1
var assigned_cards : Array[Card_GUI] = [] :
	set(value):
		card_assignment_changed(assigned_cards, value)
		assigned_cards = value

func get_unused_position() -> int:
	var occupied_positions : Array[int] = []
	for card in assigned_cards:
		occupied_positions.append(card.manager_position)
	print(occupied_positions)
	return -1

func check_if_position_is_valid(pos:int) -> bool:
	for card in assigned_cards:
		if card.manager_position == pos:
			return false
	return true

func card_assignment_changed(_before, _after) -> void:
	pass

## When -1 or less, default to getting the placements for the currently assigned cards.
func get_placements() -> Array[Vector2]:
	return []
