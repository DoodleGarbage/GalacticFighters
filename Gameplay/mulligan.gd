extends Docker

@export var seperation : float = 0.0

func get_placements(_number_of_cards:int=-1) -> Array[Vector2]:
	var tot_cards : int = _number_of_cards
	if tot_cards < 0:
		tot_cards = assigned_cards.size()
	var center : Vector2 = position + size / 2
	var total_width : float = 300 * tot_cards + seperation * (tot_cards - 1)
	var start_pos : Vector2 = Vector2(center.x - 0.5 * total_width, center.y - 250)
	
	var return_pos : Array[Vector2] = []
	
	for pos in range(0,tot_cards):
		return_pos.append(start_pos + Vector2(300+seperation,0) * pos)
	
	return return_pos
