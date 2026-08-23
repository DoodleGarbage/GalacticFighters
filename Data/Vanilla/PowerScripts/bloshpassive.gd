extends PowerScript

@export var heal : int = 2

## Triggered when the associated ability or move triggers a targeting request.
func _interaction(_targets:Array[Card_GUI]) -> void:
	pass

## Called at the start of the game turn
func _turnstart() -> void:
	var field = Resources.GameManager
	var docker_list : Array[Docker] = field.get_dockers()
	var total : int = 0
	for docker in docker_list:
		if docker.identifier == "field" and field.get_player_array_by_id(source.player_id)[3] != field.get_player_array_by_id(docker.player)[3]:
			total += docker.assigned_cards.size()
	source.heal(ability, total * heal)

## Called when the turn ends.
func _turnend() -> void:
	pass
