extends Docker


const empty_card_scene := preload("res://GUI/Card/empty_card.tscn")

## How much space should left on the sides (x) and top (y)
@export
var margin : Vector2 = Vector2(0,0)


func get_placements(number_of_cards : int=-1) -> Array[Vector2]:
	var ret_val : Array[Vector2] = []
	var pos_to_get : int = number_of_cards
	if number_of_cards < 0:
		pos_to_get = assigned_cards.size()
	@warning_ignore("narrowing_conversion")
	var distribution : int = (size.x - margin.x * 2) / (max_cards)
	var x_modifier : float = 0.5 * (distribution - 300) if distribution > (300) else 0.0
	while ret_val.size() < pos_to_get:
		ret_val.append( global_position + scale * Vector2(
			margin.x + x_modifier + distribution * ret_val.size(),
			margin.y + (size.y - margin.y*2)/2 - 250 if size.y > margin.y*2 else margin.y + size.y/2 - 250
		))
	return ret_val


var card_shadows : Array[Control] = []

func _ready() -> void:
	max_cards = 3
	var poses := get_placements(3)
	for i in max_cards:
		var new_empty = empty_card_scene.instantiate()
		add_child(new_empty)
		new_empty.global_position = poses[i]
		card_shadows.append(new_empty)
