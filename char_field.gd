extends Control

## Should be dynamic, as number of "nodes" changes.

@export
var player_controlled : bool = false

## Non-occupied nodes have a blank 'empty card'
var max_main_nodes : int = 3
## Holds a reference to each card current "docked" to this node.
@export
var main_nodes : Array[Control] = []
## We only account for filled token nodes
var max_token_nodes : int = 2
var token_nodes : Array[Control] = []

const empty_card_scene := preload("res://GUI/Card/empty_card.tscn")

## WE DO NOT ATTACH/REATTACH CARDS ON THE NODULAR LEVEL; THEY WILL ALWAYS BE ATTACHED TO THE PLAYFIELD
func update_nodes() -> void:
	# Update the card shadows (such as if the screen was resized)
	for shadow in card_shadows.size():
		# Note: the get_node_position is in global coordinates
		card_shadows[shadow].global_position = get_node_position(shadow)
	
	var lost_children : Array[Control] = []
	if main_nodes.size() < 1:
		# Prevents null instance error.
		# We also don't care about the tokens if all the main characters are dead
		return
	for ci in main_nodes.size():
		if main_nodes[ci].docker != self:
			lost_children.append(main_nodes[ci])
			continue
		## Check if card is currently being dragged
		if main_nodes[ci].docked == false:
			continue
		## If a card is no longer dragged, bring it back to its spot.
		main_nodes[ci].target_position = get_node_position(ci)
	if token_nodes.size() < 1:
		return
	for ti in token_nodes.size():
		if token_nodes[ti].docker != self:
			lost_children.append(token_nodes[ti])
			continue
		## Check if card is currently being dragged
		if token_nodes[ti].docked == false:
			continue
		## If a card is no longer dragged, bring it back to its spot.
		token_nodes[ti].target_position = get_node_position(main_nodes.size() + ti)
	for child in lost_children:
		var md : int = main_nodes.find(child)
		if md != -1:
			main_nodes.remove_at(md)
			continue
		var td : int = token_nodes.find(child)
		if td != -1:
			token_nodes.remove_at(td)
			continue

func get_node_position(node:int) -> Vector2:
	## Calculate the position of a node based on our divided size (Return as a global position)
	## Calc: { [ size / (total nodes) ] * node } + global position offset
	return Vector2( (size.x / (max_main_nodes + token_nodes.size()))*node, size.y*0.5) + global_position

func _process(delta: float) -> void:
	update_nodes()

var card_shadows : Array[Control] = []

func _ready() -> void:
	#if main_nodes
	#for child in main_nodes:
		#child.docker = self
	for i in max_main_nodes:
		var new_empty = empty_card_scene.instantiate()
		add_child(new_empty)
		new_empty.position = get_node_position(i)
		card_shadows.append(new_empty)

	
