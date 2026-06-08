extends Control

## This information is transferred from the Main Menu script on game initialization
var peer : ENetMultiplayerPeer
var current_players : Array

func initalize_game() -> void:
	load_items()
	load_gadgets()
	load_sword()
	
	start_mulligan()


## Displays all characters (not special characters) in a players deck and allows them to choose 3 and confirm, then deploys those cards onto the Field, notifies the other players, and puts the remaining in the safe room
func start_mulligan() -> void:
	pass

func load_items() -> void:
	pass

func load_gadgets() -> void:
	pass

func load_sword() -> void:
	pass
