extends Docker

## The amount of space between the edges of the control node and the cards inside
@export
var margins : float = 0
## How far apart each origin (top left corner) each card should be - x is for left-right, y is for up-down
@export
var card_spacing : Vector2 = Vector2(1.0, 1.0)
## A small step that is applied to cards as they move left->rightt to better distinguish them
@export
var step : float = 0.0

## Assume the cards are full-sized when node is full-sized, and then adjust them to this node's scale
func get_placements(_number_of_cards:int=-1) -> Array[Vector2]:
	var total : int = _number_of_cards
	if _number_of_cards < 0:
		total = assigned_cards.size()
	# subtract the first card to ensure it doesn't get give 0
	var max_p_row : int = ceil(  (size.x - 2*margins - (300*(1-card_spacing.x))) / (300 * card_spacing.x) )
	if fmod(size.x - 2*margins - (300*(1-card_spacing.x)), 300*card_spacing.x) < (300 - (1-card_spacing.x)):
		max_p_row -= 1
	var distance_on_row : float = (size.x-2*margins) / max_p_row
	var origin : Vector2 = global_position + Vector2(margins, margins) * scale.x
	var placements : Array[Vector2] = []
	while placements.size() < total:
		var new_placement : Vector2 = origin
		new_placement.x += scale.x * distance_on_row * (placements.size() % max_p_row)
		@warning_ignore("integer_division")
		new_placement.y += 500 * scale.y * card_spacing.y * floor(placements.size() / max_p_row) + step * scale.y * (placements.size() % max_p_row)
		placements.append(new_placement)
	return placements
