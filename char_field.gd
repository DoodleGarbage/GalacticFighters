extends Control

## Should be dynamic, as number of "nodes" changes.



## Non-occupied nodes have a blank 'empty card'
var max_main_nodes : int = 3
## Holds a reference to each card current "docked" to this node.
@export
var main_nodes : Array[Control] = []
## We only account for filled token nodes
var max_token_nodes : int = 2
var token_nodes : Array[Control] = []

## WE DO NOT ATTACH/REATTACH CARDS ON THE NODULAR LEVEL; THEY WILL ALWAYS BE ATTACHED TO THE PLAYFIELD

func update_nodes() -> void:
	var lost_children : Array[Control] = []
	for ci in main_nodes.size():
		if main_nodes[ci].docker != self:
			lost_children.append(main_nodes[ci])
			continue
		## Check if card is currently being dragged
		if main_nodes[ci].docked == false:
			continue
		## If a card is no longer dragged, bring it back to its spot.
		main_nodes[ci].target_position = get_node_position(1)
	for ti in token_nodes.size():
		if token_nodes[ti].docker != self:
			lost_children.append(token_nodes[ti])
			continue
		## Check if card is currently being dragged
		if token_nodes[ti].docked == false:
			continue
		## If a card is no longer dragged, bring it back to its spot.
		token_nodes[ti].target_position = get_node_position(main_nodes.size() + ti)

func get_node_position(node:int) -> Vector2:
	## Calculate the position of a node based on our divided size (Return as a global position)
	## Calc: { [ size / (total nodes) ] * node } + global position offset
	return Vector2( (size.x / (max_main_nodes + token_nodes.size()))*node, size.y*0.5) + global_position

func _process(delta: float) -> void:
	update_nodes()

func _ready() -> void:
	for child in main_nodes:
		child.docker = self
