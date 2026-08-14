extends Control 
class_name DockerChild

## These values are set when the card is generated on the playfield
var unique_id : int = 0 # a unique identifier for synchronization/communication
var player_id : int = 0 # who is the 'owner' of this card

## Skips this card when syncing across clients
@export var dont_sync : bool = false

## Used by the _input code to allow selecting empty positions (with the right targeting flags)
@export var input_metadata : String = ""

## Whether or not this card belongs to the current client/is controllable (aka, could be switched off under the "controlled" status effect)
var controlled : bool = false

## Used to determine input-selection priority
@export var priority : int = 0

var manager : Docker
var manager_position : int = -1

func assign_manager(new_manager:Docker, pos:int=-1, force:bool=false) -> void:
	if new_manager == null or (new_manager == manager and pos == manager_position):
		return
	var check : int = get_true_manager_position()
	if check > -1:
		manager.assigned_cards.pop_at(check)
	z_index += new_manager.z_index - manager.z_index if manager != null else new_manager.z_index
	manager = new_manager
	var occupied_positions : Array[int] = []
	for card in manager.assigned_cards:
		occupied_positions.append(card.manager_position)
	#print("Assigning Manager; Name: ", manager.identifier, " Team: ", manager.player)
	if pos > -1 and (not occupied_positions.has(pos) or force):
		manager_position = pos
		#print("assigned pos: ", pos)
	else:
		#manager.get_unused_position()
		var smallest_unoccupied : int = 0
		while occupied_positions.has(smallest_unoccupied):
			smallest_unoccupied += 1
		manager_position = smallest_unoccupied
		#print("unoccupied pos: ", smallest_unoccupied)
	manager.assigned_cards.append(self)


## Returns our actual index in the manager's assigned card array
## -1 means it either wasn't assigned as a card (which should not be happening) or no manager exists
func get_true_manager_position() -> int:
	return manager.assigned_cards.find(self) if manager != null else -1

func remove_manager() -> void:
	var us : int = get_true_manager_position()
	if us > -1:
		manager.assigned_cards.pop_at(us)
		manager_position = -1

func set_selection(mode:bool) -> void:
	return
