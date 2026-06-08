extends Docker


const empty_card_scene := preload("res://GUI/Card/empty_card.tscn")


func get_placements(number_of_cards : int=-1) -> Array[Vector2]:
	var ret_val : Array[Vector2] = []
	var pos_to_get : int = number_of_cards
	if pos_to_get < 0:
		pos_to_get = assigned_cards.size()
	for i in assigned_cards.size():
		ret_val.append(get_node_position(i))
	return ret_val

func get_node_position(node:int) -> Vector2:
	## Calculate the position of a node based on our divided size (Return as a global position)
	## Calc: { [ size / (total nodes) ] * node } + global position offset
	return Vector2( (size.x / (max_cards))*node, size.y*0.5) + global_position


var card_shadows : Array[Control] = []

func _ready() -> void:
	max_cards = 3
	for i in max_cards:
		var new_empty = empty_card_scene.instantiate()
		add_child(new_empty)
		new_empty.global_position = get_node_position(i)
		card_shadows.append(new_empty)
	resize_children.emit(self, true)

signal resize_children(who_is_us:Node, affect_non_cards:bool)
