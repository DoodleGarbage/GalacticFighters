extends Docker




## How much space should left on the sides (x) and top (y)
@export
var margin : Vector2 = Vector2(0,0)


func get_placements() -> Array[Vector2]:
	var ret_val : Array[Vector2] = []
	#var pos_to_get : int = number_of_cards
	#if number_of_cards < 0:
		#pos_to_get = assigned_cards.size()
	@warning_ignore("narrowing_conversion")
	var distribution : int = (size.x - margin.x * 2) / (max_cards)
	var x_modifier : float = 0.5 * (distribution - 300) if distribution > (300) else 0.0
	for card in assigned_cards:
		ret_val.append( global_position + scale * Vector2(
			margin.x + x_modifier + distribution * card.manager_position,
			margin.y + (size.y - margin.y*2)/2 - 250 if size.y > margin.y*2 else margin.y + size.y/2 - 250
		))
	return ret_val

func get_one_placement(manager_pos:int) -> Vector2:
	var distribution : int = (size.x - margin.x * 2) / (max_cards)
	var x_modifier : float = 0.5 * (distribution - 300) if distribution > (300) else 0.0
	var ret_vec = global_position + scale * Vector2(
			margin.x + x_modifier + distribution * manager_pos,
			margin.y + (size.y - margin.y*2)/2 - 250 if size.y > margin.y*2 else margin.y + size.y/2 - 250
		)
	return ret_vec
