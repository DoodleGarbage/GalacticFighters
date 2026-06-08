extends Control

class_name Docker

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
