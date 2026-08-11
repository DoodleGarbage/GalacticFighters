extends Control

## This information is transferred from the Main Menu script on game initialization
var peer : ENetMultiplayerPeer

var game_active : bool = false

var host_id : int
## [name (string), ID (int), deck (Deck), team (int), moves (int)]
const default_deck := preload("res://Resources/BasicResources/demo_deck.tres")
var current_players : Array = []

# A pointer reference to every single card on the board
var cards : Array[Card_GUI] = [] :
	get():
		return cards

var docker_list : Array[Docker] = []

## Returns a pointer to the player's data array in current_players
func get_player_array_by_id(id:int) -> Array:
	for player in current_players:
		if player[1] == id:
			return player
	return []

## Returns the position in the current_players array of the id
func get_player_by_id(id:int) -> int:
	for player in current_players.size():
		if current_players[player][1] == id:
			return player
	return -1


# current_players and host_id are updated by the Main_menu manager
func initalize_game() -> void:
	game_active = true
	reset_playfield()
	
	initalize_dockers.rpc()
	
	if peer.get_unique_id() != host_id:
		return
	
	initalize_cards()
	
	#load_items(decks)
	#load_gadgets(decks)
	#load_sword(decks)
	
	$Unscalables/TurnTools.end_turn() ## reset display of TurnTools
	
	start_mulligan.rpc()

func reset_playfield() -> void:
	for docker in docker_list:
		docker.queue_free()
	$EndScreen/List/Vic.hide()
	$EndScreen/List/Def.hide()
	$EndScreen.hide()

@onready var field_docker_scene := preload("res://GUI/field_docker.tscn")
@onready var saferoom_docker_scene := preload("res://GUI/saferoom_docker.tscn")
@onready var item_docker_scene := preload("res://GUI/item_docker.tscn")

# Scale to apply to things
const FIELD_DOCKER_GUI_SCALE := Vector2(0.4,0.4)
const SAFEROOM_DOCKER_GUI_SCALE := Vector2(0.4,0.4)
const ITEM_DOCKER_GUI_SCALE := Vector2(1,1)
# Seperates each GUI by this much left/right
const DOCKER_GUI_SEPERATION : float = 1920

# Where to position stuff, relative to the top left corner; if on bottom, this is shifted down half a screen
const FIELD_DOCKER_GUI_POSITION := Vector2(540,230)
# (Relative to the field docker)
const SAFEROOM_DOCKER_GUI_POSITION := Vector2(835, -190)
# (Relative to the field docker)
const ITEM_DOCKER_GUI_POSITION := Vector2(0,-220)

## Where to position stuff if it's on the bottom half
#const BOT_FIELD_DOCKER_GUI_POSITION := Vector2(540,550)
## (Relative to the field docker)
#const BOT_SAFEROOM_DOCKER_GUI_POSITION := Vector2(835,50)
## (Relative to the field docker)
#const BOT_ITEM_DOCKER_GUI_POSITION := Vector2(0,310)

## These are used to determine how many fields there are
var total_upper_placements : int = 0
var total_lower_placements : int = 0

## Which field is currently being viewed (to prevent scroll away from all the fields)
var current_upper_field : int = 0
var current_lower_field : int = 0

@rpc("authority", "call_local", "reliable", 0)
func initalize_dockers() -> void:
	docker_list = [$Mulligan]
	
	# Check the number of teams
	var total_teams : Array[int] = []
	for player in current_players:
		if not total_teams.has(player[3]):
			total_teams.append(player[3])
	var us := get_player_array_by_id(peer.get_unique_id())
	
	## used_*_placements_left = 1 if the center is filled
	var used_upper_placements_left :int= 0
	var used_upper_placements_right :int= 0
	var used_lower_placements_left :int= 1 # us, the player, is added before anything
	var used_lower_placements_right :int = 0
	
	$Mulligan.player = us[1]
	
	for player in current_players:
		## Determine where to place the dockers properly
		var upper_if_true : bool = true
		var left_if_true : bool = true
		
		## Relevant if not us:
		#if total_teams.size() <= 2:
			#if player[3] == us[3]:
				#upper_if_true = false
				#if used_lower_placements_left > used_lower_placements_right:
					#left_if_true = false
			#else:
				#upper_if_true = true
				#if used_upper_placements_left-1 > used_upper_placements_right:
					#left_if_true = false
		if us != player:
			if used_upper_placements_left + used_upper_placements_right > used_lower_placements_left + used_lower_placements_right:
				upper_if_true = false
				if used_lower_placements_left > used_lower_placements_right:
					left_if_true = false
			else:
				upper_if_true = true
				if used_upper_placements_left > used_upper_placements_right:
					left_if_true = false
			
			if upper_if_true:
				if left_if_true:
					used_upper_placements_left += 1
				else:
					used_upper_placements_right += 1
			else:
				if left_if_true:
					used_lower_placements_left += 1
				else:
					used_lower_placements_right += 1
		
		## Final determined position
		var origin : Vector2 = FIELD_DOCKER_GUI_POSITION
		#if upper_if_true:
			#origin = TOP_FIELD_DOCKER_GUI_POSITION
		#else:
			#origin = BOT_FIELD_DOCKER_GUI_POSITION
		## Horizontal offset
		var offset : float = 0
		if upper_if_true:
			offset = -(used_upper_placements_left-1) if left_if_true else used_upper_placements_right
		else:
			offset = -(used_lower_placements_left-1) if left_if_true else used_lower_placements_right
		offset *= DOCKER_GUI_SEPERATION
		
		## Feels bad to place this after doing all the processing but gotta bypass it somewhere
		if player == us:
			upper_if_true = false
			left_if_true = true
			#origin = BOT_FIELD_DOCKER_GUI_POSITION
			offset = 0
		
		
		var new_field_docker := field_docker_scene.instantiate()
		var new_saferoom_docker := saferoom_docker_scene.instantiate()
		var new_item_docker := item_docker_scene.instantiate()
		
		new_field_docker.player = player[1]
		## Unique IDs are only useful if this gets synced with the server
		#new_field_docker.id = get_unique_docker_id()
		new_saferoom_docker.player = player[1]
		#new_saferoom_docker.id = get_unique_docker_id()
		new_item_docker.player = player[1]
		#new_item_docker.id = get_unique_docker_id()
		
		docker_list.append(new_field_docker)
		docker_list.append(new_saferoom_docker)
		docker_list.append(new_item_docker)
		
		if player == us:
			new_field_docker.player_controlled = true
			new_saferoom_docker.player_controlled = true
			new_item_docker.player_controlled = true
		
		if upper_if_true:
			$UpperDockers.add_child(new_field_docker, true)
			$UpperDockers.add_child(new_saferoom_docker)
			$UpperDockers.add_child(new_item_docker)
		else:
			$LowerDockers.add_child(new_field_docker, true)
			$LowerDockers.add_child(new_saferoom_docker)
			$LowerDockers.add_child(new_item_docker)
		
		
		new_field_docker.position = origin
		new_field_docker.position.x += offset
		new_saferoom_docker.position = origin + SAFEROOM_DOCKER_GUI_POSITION
		new_saferoom_docker.position.x += offset
		new_item_docker.position = origin + ITEM_DOCKER_GUI_POSITION
		new_item_docker.position.x += offset
		
		new_field_docker.scale = FIELD_DOCKER_GUI_SCALE
		new_saferoom_docker.scale = SAFEROOM_DOCKER_GUI_SCALE
		new_item_docker.scale = ITEM_DOCKER_GUI_SCALE
	
	total_lower_placements = used_lower_placements_left-1 + used_lower_placements_right
	total_upper_placements = used_upper_placements_left-1 + used_upper_placements_right
	current_lower_field = used_lower_placements_left-1
	current_upper_field = used_upper_placements_left-1
	print("total placements: ", total_upper_placements, " current pos: ", current_upper_field)
	
	
	update_field_buttons_gui()
	return


## Used to add interaction to buttons
func move_field(upper:bool, left:bool) -> void:
	if active_interact_card != null:
		return
	if upper:
		if left:# and current_upper_field > 0:
			current_upper_field -= 1
			$UpperDockers.position.x -= DOCKER_GUI_SEPERATION
		if not left:# and current_upper_field < total_upper_placements:
			current_upper_field += 1
			$UpperDockers.position.x += DOCKER_GUI_SEPERATION
	else:
		if left:# and current_lower_field > 0:
			current_lower_field -= 1
			$LowerDockers.position.x -= DOCKER_GUI_SEPERATION
		if not left:# and current_lower_field < total_lower_placements:
			current_lower_field += 1
			$LowerDockers.position.x += DOCKER_GUI_SEPERATION
	update_field_buttons_gui()
	update_dockers()
	return

func update_field_buttons_gui() -> void:
	$SwitchFields/RightLower.show()
	$SwitchFields/RightUpper.show()
	$SwitchFields/LeftUpper.show()
	$SwitchFields/LeftLower.show()
	if current_upper_field >= total_upper_placements:
		$SwitchFields/RightUpper.hide()
	if current_upper_field <= 0 or total_upper_placements <= 1:
		$SwitchFields/LeftUpper.hide()
	if current_lower_field >= total_lower_placements:
		$SwitchFields/RightLower.hide()
	if current_lower_field <= 0 or total_lower_placements <= 1:
		$SwitchFields/LeftLower.hide()
	


## Clients send actions, the server executes them and sends the results back - while clients wait, they can 'predict' what happens and play their visual effects before the server responds, then update/correct their stats when the server informs them what happened

## TODO: Currently just does a FFA - need to allow setting an option in the lobby to choose team picking method, then main_menu.gd will pass that info as arguments when it calls the assign_teams() function
func assign_teams() -> void:
	for player in current_players.size():
		current_players[player].append(player)
		## We append a second empty value to all players here (to prevent invalid position errors) - this is their # of moves, to be tracked by the host
		current_players[player].append(0)

func initalize_cards() -> void:
	for player in current_players:
		print(player)
		var deck : Deck = player[2]
		var shadow_docker : Docker = get_docker("field", player[1])
		for i in shadow_docker.max_cards:
			add_shadow_card(shadow_docker, i, player[1])
		for card in deck.characters:
			var new_card : Card_GUI = add_card(card, get_docker("saferoom", player[1]), player[1])
			#sync_card(new_card, true)
	sync_all_cards(true)

##--------------------------------------------------------------------------------------------------
##                                    MULLIGAN and GAME START CODE
##--------------------------------------------------------------------------------------------------

## required number of characters to choose for the game opening
const MULLIGAN_TO_SELECT : int = 3

# Displays all characters (not special characters) in a players deck and allows them to choose 3 and confirm, then deploys those cards onto the Field, notifies the other players, and puts the remaining in the safe room
@rpc("authority", "call_local", "reliable", 0)
func start_mulligan() -> void:
	#$Unscalables/MulliganBG.show()
	$Mulligan.show()
	for card in cards:
		if card.input_metadata != "":
			continue
		if card.player_id == peer.get_unique_id() and card.stored_card.type == 1: # note: 0 is Special Character, 1 is units (per the rules, can only start with units)
			valid_cards.append(card)
			## ID 5 is the mulligan docker
			card.assign_manager(get_docker("mulligan", card.player_id))
			#if peer.get_unique_id() == host_id:
				#sync_card(card, true)
	update_dockers()
	selecting_cards = true
	selecting_mulligan = true
	max_selections = MULLIGAN_TO_SELECT ## The number of cards we can start with
	selected_cards = []
	players_finished_mulligan = []

func submit_mulligan() -> void:
	if selected_cards.size() != max_selections:
		return
	selecting_cards = false
	selecting_mulligan = false
	$Mulligan/ConfirmMulligan.hide()
	for card in cards:
		if card.input_metadata != "":
			continue
		card.assign_manager(get_docker("saferoom", peer.get_unique_id()))
	for card in selected_cards:
		card.assign_manager(get_docker("field", peer.get_unique_id()))
		card.set_selection(false)
	update_dockers()
	var cg_as_id : Array[int] = card_to_id_array(selected_cards)
	send_mulligan_selection.rpc(cg_as_id, peer.get_unique_id())


# List of Arrays; first item in array is player id, the rest are the unique id for all cards they are mulliganning with - See End_Mulligan array processing
var players_finished_mulligan : Array = []

## Sent from client to server, gives the server the player - needs to be call_local so the server can send this to itself.
@rpc("any_peer", "call_local", "reliable", 0)
func send_mulligan_selection(selections:Array[int], player_id:int) -> void:
	if host_id != peer.get_unique_id():
		return
	for player in players_finished_mulligan:
		if player[0] == player_id: # Prevent people from submitting their mulligan more than once
			return
	var append_array = [player_id]
	append_array.append_array(selections)
	players_finished_mulligan.append(append_array)
	if players_finished_mulligan.size() == current_players.size():
		end_mulligan.rpc(players_finished_mulligan)

@rpc("authority", "call_local", "reliable", 0)
func end_mulligan(player_mulligans:Array) -> void:
	$Mulligan.hide()
	for card in cards:
		if card.input_metadata != "":
			continue
		card.set_selection(false)
		card.assign_manager(get_docker("saferoom", get_player_array_by_id(card.player_id)[1]))
	for player in player_mulligans:
		var dupe : Array[int] = []
		dupe.assign(player)
		var player_data : Array = get_player_array_by_id(dupe[0])
		dupe.pop_front()
		var as_card : Array[Card_GUI] = id_to_card_array(dupe)
		
		var tar_docker : Docker = get_docker("field", player_data[1])
		for card in as_card.size():
			as_card[card].assign_manager(tar_docker, card)
	if host_id == peer.get_unique_id():
		print("We're ready to start the game!!!")
		for card in cards:
			sync_card(card, true)
		start_game()

func start_game() -> void:
	current_players.shuffle() ## Puts them in a random order, instead of making the order based on who joined the server first - also gives us a random starting player
	update_turn.rpc(current_players[0][1])

##-----------------------------------------------
##             GAMEPLAY CODE
##-----------------------------------------------

var current_turn_id : int = -1

@rpc("authority", "call_local", "reliable", 0)
func update_turn(player_id:int) -> void:
	_end_turn() # Note: only ends for the player we're switching away from
	current_turn_id = player_id
	_start_turn() # Note: only triggers for the player we're switching to
	
	if peer.get_unique_id() == host_id:
		for pl in current_players:
			pl[4] = 0
		var player : Array = get_player_array_by_id(player_id)
		player[4] = 2
		sync_all_cards(true)
	
	## Display some visual thing to notify of a turn change
	if peer.get_unique_id() != player_id:
		$Unscalables/TurnTools.moves = 0
		return
	$Unscalables/TurnTools.moves = 2
	


## Called when the turn tools button is pressed
func signal_turn_end() -> void:
	if current_turn_id == peer.get_unique_id():
		send_end_turn_notice.rpc(peer.get_unique_id())

@rpc("any_peer", "call_local", "reliable", 0)
func send_end_turn_notice(player_id:int) -> void:
	if peer.get_unique_id() != host_id or player_id != current_turn_id:
		return
	# TODO: Apply a status to all characters w/ duration 1 turn that adds 1 defense for each unused move
	var next_player : int = get_player_by_id(current_turn_id) + 1
	if next_player >= current_players.size():
		next_player -= current_players.size()
	update_turn.rpc(current_players[next_player][1])

## Trigger all start_turn effects in powerscripts & decrement the duration of any statuses
## Only triggers on an individual person's turn, rather than the round.
func _start_turn() -> void:
	if peer.get_unique_id() == current_turn_id:
		$Unscalables/TurnTools.begin_turn() # Turn vfx
	for card in cards:
		if card.player_id == current_turn_id:
			for script in card.attribute_scripts:
				script._turnstart()
	
	return

## Trigger all end_turn effects in powerscripts
## Only triggers on an individual person's turn, rather than the round.
@rpc("authority", "call_local", "reliable", 0)
func _end_turn() -> void:
	print("calling turn end for player: ", current_turn_id)
	if peer.get_unique_id() == current_turn_id:
		$Unscalables/TurnTools.end_turn() # Turn vfx
	for card in cards:
		var finished_attributes : Array[int] = []
		if card.player_id == current_turn_id:
			for script in card.attribute_scripts.size():
				card.attribute_scripts[script]._turnend()
				if card.attribute_scripts[script].duration_tracker > -1:
					print("decrementing attribute! attr: ", card.attributes[script].name)
					print("old duration: ", card.attribute_scripts[script].duration_tracker	)
					card.attribute_scripts[script].duration_tracker -= 1
					print("new duration: ", card.attribute_scripts[script].duration_tracker)
					if card.attribute_scripts[script].duration_tracker == 0:
						finished_attributes.append(script)
			finished_attributes.reverse() # so that we we can remove the right moving to the left, so the array indexes stay the same as we remove them
			for attr in finished_attributes:
				card.attributes.remove_at(attr)
				card.attribute_scripts.remove_at(attr)
	return


##-----------------------------------------------
##            CARD AND SYNCING CODE
##-----------------------------------------------

const card_ui_scene := preload("res://GUI/Card/card.tscn")
const empty_card_scene := preload("res://GUI/Card/empty_card.tscn")

func add_card(card : Card, docker : Docker, player_id:int, unique_id : int = -1) -> Card_GUI:
	var new_card := card_ui_scene.instantiate()
	new_card.player_id = player_id
	new_card.unique_id = get_unique_card_id() if unique_id == -1 else unique_id
	new_card.controlled = player_id == peer.get_unique_id()
	new_card.ability_triggered.connect(trigger_ability)
	add_child(new_card)
	new_card.load_card(card)
	new_card.dead.connect(dead_card.bind(new_card))
	#new_card.stopped_dragging.connect(update_dockers)
	new_card.assign_manager(docker)
	cards.append(new_card)
	
	return new_card

## Adds an Empty card for targeting - used for the fields
func add_shadow_card(docker : Docker, manager_pos : int, player_id:int, unique_id : int = -1) -> void:
	var new_shadow := empty_card_scene.instantiate()
	if unique_id != -1:
		new_shadow.unique_id = get_unique_card_id()
	else:
		new_shadow.unique_id = unique_id
	docker.add_child(new_shadow)
	cards.append(new_shadow)
	new_shadow.player_id = player_id
	new_shadow.manager = docker
	new_shadow.manager_position = manager_pos
	new_shadow.global_position = docker.get_one_placement(manager_pos)
	if peer.get_unique_id() != host_id:
		return
	print("syncing shadow cards")
	#var docker = get_docker("field", player)
	sync_shadow_card.rpc(docker.player, manager_pos, new_shadow.unique_id, new_shadow.player_id)

@rpc("authority", "call_remote", "reliable", 0)
func sync_shadow_card(docker_player:int, manager_pos:int, unique_id:int, player_id:int) -> void:
	var docker : Docker = get_docker("field", docker_player)
	add_shadow_card(docker, manager_pos, player_id, unique_id)

## Returns an ID not shared by all other cards
func get_unique_card_id() -> int:
	var invalid_id : bool = true
	var new_id : int = 0
	while invalid_id:
		new_id = randi()
		invalid_id = false
		for card in cards:
			if card.unique_id == new_id:
				invalid_id = true
	return new_id

func get_unique_docker_id() -> int:
	var invalid_id : bool = true
	var new_id : int = 0
	while invalid_id:
		new_id = randi()
		invalid_id = false
		for dock in docker_list:
			if dock.id == new_id:
				invalid_id = true
	return new_id

## The server should sync important information, like stats, but the more complex information - such as abilities, visual effects, etc, will rely on the client side info; if the client modifies them, only visual effects should change, since only the server's modifications to the board items (like stats) are permanent
func sync_card(card:Card_GUI, upd_docker : bool = true) -> void:
	if card.dont_sync:
		return
	var stats : Array = card.get_stats()
	# Resource names
	var card_resource : String = card.stored_card.name
	var card_ids : Array = [card.unique_id, card.player_id]
	var manager_identifier : String = card.manager.identifier
	var script_data : Array = card.get_script_data()
	var attributes : Array = card.get_attributes()
	var manager_position : int = card.manager_position
	card.update_ability_buttons()
	_update_individual_docker(card.manager, true)
	recieved_card_sync.rpc(stats, card_resource, card_ids, manager_identifier, manager_position, script_data, attributes, upd_docker)

func sync_all_cards(upd_docker:bool = true) -> void:
	for card in cards:
		sync_card(card, upd_docker)

@rpc("authority", "call_remote", "reliable", 1)
func recieved_card_sync(stats:Array, card_name:String, card_ids:Array, manager_id : String, manager_pos :int, script_data : Array, attribute_data : Array, do_docker_update : bool) -> void:
	var card_instance : Card_GUI
	## Team is relative - need to get dockers by the docker identifier and the player id
	var current_docker := get_docker(manager_id, get_player_array_by_id(card_ids[1])[1])
	for card in cards:
		if card.unique_id == card_ids[0]:
			card_instance = card
	if card_instance == null:
		card_instance = add_card(Resources.find_resource("Character", card_name), current_docker, card_ids[1], card_ids[0])
	card_instance.apply_stats(stats)
	card_instance.assign_manager(current_docker, manager_pos, true)
	card_instance.load_attributes(attribute_data)
	card_instance.update_scripts(script_data)
	card_instance.update_ability_buttons()
	if do_docker_update:
		_update_individual_docker(card_instance.manager, true)


func dead_card(card:Card_GUI) -> void:
	# Only do something if we're the host, so clients don't get prematurely trigger happy
	if peer.get_unique_id() == host_id:
		dead_server_card.rpc(card.unique_id)


@rpc("authority", "call_local", "reliable", 0)
func dead_server_card(card:int) -> void:
	var gui_card : Card_GUI = id_to_card(card)
	if gui_card == null or gui_card.flagged_for_death:
		return
	gui_card.flagged_for_death = true
	var index : int = cards.find(gui_card)
	cards.remove_at(index) # This makes the card officially not a part of the game, from the perspective of the game
	gui_card.remove_manager()
	# ^ We can now safely queue_free the card at any time.
	# Display death vfx and then delete once the effect expires
	var new_fx : Node2D = gui_card.stored_card.VFX_death.instantiate()
	new_fx.finished.connect(gui_card.queue_free)
	gui_card.add_child(new_fx)
	new_fx.position = Vector2(150, 250)
	new_fx.emitting = true
	
	if host_id != peer.get_unique_id():
		return
	
	var who_has_living_cards : Array[int] = []
	print("checking if anyone died")
	for in_play in cards:
		if not in_play.dont_sync and not who_has_living_cards.has(in_play.player_id):
			who_has_living_cards.append(in_play.player_id)
	for player in current_players:
		if not who_has_living_cards.has(player[1]):
			end_game.rpc(player[1])
			break
	print("Results: ", who_has_living_cards)

@rpc("authority", "call_local", "reliable", 0)
func end_game(victor_id:int) -> void:
	peer.close() ## Exit multiplayer
	$EndScreen.show()
	if peer.get_unique_id() == victor_id:
		$EndScreen/List/Vic.show()
	else:
		$EndScreen/List/Def.show()
	return

signal return_to_lobby
func _on_exit_pressed() -> void:
	game_active = false
	return_to_lobby.emit()

## Updates all dockers in the scene
func update_dockers() -> void:
	for docker in get_dockers():
		_update_individual_docker(docker)
	return

## Updates all cards assigned to a docker and updates their position accoridng to the docker
func _update_individual_docker(docker:Docker, update_interact:bool=true) -> void:
	if not docker.ordering_matters: #This will compress the cards to the smallest arrangment if false;
		for card in docker.assigned_cards:
			card.assign_manager(docker)
	
	var positions := docker.get_placements()
	for card in docker.assigned_cards.size():
		docker.assigned_cards[card].position = positions[card]
		docker.assigned_cards[card].scale = docker.scale
	if not update_interact and active_interact_card != null:
		open_interaction_menu(active_interact_card)
	return

## Sorts an array of Card_GUI, by variable property. (The property must be an int)
func sort_card_gui_array(array:Array[Card_GUI], property:String, inverse:bool=false) -> Array[Card_GUI]:
	
	var re_sorted_positions : Array[Card_GUI] = array.duplicate()
	var final_array : Array[Card_GUI] = []
	while re_sorted_positions.size() > 0:
		var get_lowest : int = get_min(re_sorted_positions, property, inverse)
		final_array.append(re_sorted_positions[get_lowest])
		re_sorted_positions.remove_at(get_lowest)
	#print("We sorted a card_gui array, here are the %s values (in order)" % property)
	for elem in final_array:
		print(str(elem.get(property)))
	return final_array

## Returns the index of the lowest in the array - Note: Property must be an int
func get_min(array:Array[Card_GUI], property:String, inverse:bool=false) -> int:
	var lowest : int = 0
	var farthest_value : int = array[0].get(property)
	for i in array.size():
		if ( not inverse and array[i].get(property) < farthest_value) or (inverse and array[i].get(property) > farthest_value):
			lowest = i
			farthest_value = array[i].get(property)
	return lowest

## Gets every docker in the scene
func get_dockers() -> Array[Docker]:
	return docker_list
	
	#var retr : Array[Docker] = []
	#for child in get_children():
		#if child is Docker:
			#retr.append(child)
	#return retr

func get_docker(which:String, player:int) -> Docker:
	for docker in docker_list:
		if docker.identifier == which and (docker.player == player):
			return docker
	return

#func id_to_docker(id:int) -> Docker:
	#for docker in get_dockers():
		#if docker.id == id:
			#return docker
	#return


## To get the ID of a card, just grab it's .unique_id property
## This retrives a card's node reference from ID
func id_to_card(id:int) -> Card_GUI:
	for card in cards:
		if card.unique_id == id:
			return card
	return

## This retrieves all card node references from an array of IDs
func id_to_card_array(ids:Array[int]) -> Array[Card_GUI]:
	var ret_arr : Array[Card_GUI] = []
	for id in ids:
		ret_arr.append(id_to_card(id))
	return ret_arr

## This converts an array of card node references to an array of IDs
func card_to_id_array(input:Array[Card_GUI]) -> Array[int]:
	var ret_arr : Array[int] = []
	for card in input:
		ret_arr.append(card.unique_id)
	return ret_arr


##------------------------------------------
##          INTERACTION CODE
##------------------------------------------

# Interaction Priority:
# Right Click:
#  -- Close Menu (anywhere) > Open Menu (Highest z_index hovered card)
# Left Click:
# -- Select (selecting_cards, awaiting_mulligan) (if valid card, hovered, prioritizing the highest z_index)

var menu_open : bool = false
var active_interact_card : Card_GUI
var allow_drag : bool = true

## Input handling for cards - manages selecting cards and opening/closing interaction menu
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if menu_open and event.is_action_pressed("card_interact"):
			close_interaction_menu()
			return
		## Get all cards being hovered during this button click:
		var hovered_cards : Array[Card_GUI] = []
		# Reminder that the card shadows are inside the cards array
		for card in cards:
			var rect : Rect2 = Rect2(card.global_position, card.size * card.scale)
			if rect.has_point(get_global_mouse_position()):
				hovered_cards.append(card)
		## Highest z_index card is [0] - may be non-deterministic for same z_indexes
		var sorted_hovered_cards : Array[Card_GUI] = sort_card_gui_array(hovered_cards, "priority", true)
		if not menu_open and event.is_action_pressed("card_interact"):
			for card in sorted_hovered_cards:
				if card.input_metadata != "":
					continue
				open_interaction_menu(card)
			return
		if selecting_cards and event.is_action_pressed("card_select"):
			## Start with the highest z_index card, then work down list to find a valid selection target
			for card in sorted_hovered_cards:
				if valid_cards.has(card):
					print("valid card found, name: ", card.name)
					var already_selected = selected_cards.find(card)
					if already_selected > -1:
						selected_cards[already_selected].set_selection(false)
						selected_cards.remove_at(already_selected)
						break
					if selected_cards.size() >= max_selections:
						selected_cards[-1].set_selection(false)
						selected_cards.pop_back()
					selected_cards.append(card)
					card.set_selection(true)
					break
			if selected_cards.size() == max_selections and max_selections == 1:
				selection_complete.emit()
			update_input_displays()
			return

signal selection_complete() ## Emitted when the maximum (1) number of cards seeking selection are picked

## Open the interaction menu! Displays information about a card and allows using its abilities
func open_interaction_menu(card:Card_GUI) -> void:
	if card == null:
		push_warning("Tried to open the interaction menu for a null card!")
		return
	active_interact_card = card
	menu_open = true
	allow_drag = false
	card.scale = Vector2(1.0,1.0)
	card.position = get_viewport_rect().size * 0.5 - card.size * 0.5
	card.target_position = get_viewport_rect().size * 0.5 - card.size * 0.5
	card.open_interaction_menu()
	$Dimmer.show()

## Close the interaction menu
func close_interaction_menu() -> void:
	if active_interact_card != null and not active_interact_card.is_queued_for_deletion():
		active_interact_card.close_interaction_menu()
	active_interact_card = null
	menu_open = false
	allow_drag = true
	update_dockers()
	$Dimmer.hide()
	reset_card_indexes()







func update_input_displays() -> void:
	if selecting_ability:
		update_target_display()
	if selecting_mulligan:
		if selected_cards.size() == max_selections:
			$Mulligan/ConfirmMulligan.show()
		else:
			$Mulligan/ConfirmMulligan.hide()

## Updates information on the 
func update_target_display() -> void:
	$TargetingGUI/Options/Target/TarAmntToSel.text = str(max_selections - selected_cards.size())
	$TargetingGUI/Options/Target/TarConfirm.show()
	if selected_cards.size() > 1:
		$TargetingGUI/Options/Target/TarConfirm.text = tr("CONFIRM_TARGETS")
	elif selected_cards.size() == 1:
		$TargetingGUI/Options/Target/TarConfirm.text = tr("CONFIRM_TARGET")
	else:
		$TargetingGUI/Options/Target/TarConfirm.hide()

func reset_card_indexes() -> void:
	for card in cards:
		card.z_index = 0 + card.manager.z_index
		if card.input_metadata == "empty":
			card.z_index -= 3


##
## ABILITY TARGETING & TRIGGERS ##
##

## The ability int refers to the position of the array in the Card_GUI's attributes. 
func trigger_ability(ability:int, card:Card_GUI) -> void:
	print("An ability was triggered!")
	if $Unscalables/TurnTools.moves < 1:
		print("not enough moves! Cancelling!")
		return
	if current_turn_id != peer.get_unique_id():
		print("Tried to perform an action while it isn't our turn!")
		return
	close_interaction_menu() # Abilities are often triggered when this is open
	allow_drag = false # Prevent dragging during the ability trigger
	var targeting : Array[Card_GUI] = await get_targets(card, card.attributes[ability])
	if targeting == []:
		print("Targeting cancelled or failed")
		allow_drag = true
		return
	allow_drag = true # Restore drag
	print("We selected cards to target!: ", targeting)
	
	var burst_amnt : int = 0
	if card.attributes[ability].allow_burst:
		burst_amnt = $TargetingGUI/Options/Burst/BurstSelect.value
	var targets_to_id : Array[int] = card_to_id_array(targeting)
	print("Triggering an ability. Our ID: ", get_player_array_by_id(peer.get_unique_id())[1])
	trigger_ability_client.rpc_id(host_id,peer.get_unique_id(),ability, card.unique_id, burst_amnt, targets_to_id)
	

## card [int] is the unique ID of the Card_GUI that is the source
@rpc("any_peer", "call_remote", "reliable", 0)
func trigger_ability_client(peer_id:int, ability:int, card:int, burst_amnt:int, targets:Array[int]) -> void:
	print("Ability Triggered on client: ", get_player_array_by_id(peer.get_unique_id())[1])
	var who : int = get_player_by_id(current_turn_id)
	if peer.get_unique_id() == host_id:
		if current_players[who][4] < 1:
			print("A client tried to take an action when they shouldn't be able to (Not enough moves remaining)!")
			return
	
	# Runs the pscript's interaction effect
	var card_as_gui : Card_GUI = id_to_card(card)
	var target_guis : Array[Card_GUI] = id_to_card_array(targets)
	
	for i in range(0, 1+burst_amnt):
		card_as_gui.attribute_scripts[ability]._interaction(target_guis)
	update_dockers()
	
	# Change the move counter, etc.
	current_players[who][4] -= 1
	sync_all_cards(true)
	
	update_turn_counter.rpc_id(peer_id,current_players[who][4])
	ability_trigger_server_notif.rpc(ability, card, burst_amnt, targets, who)
	return

@rpc("authority", "call_remote", "reliable", 1)
func update_turn_counter(moves:int) -> void:
	$Unscalables/TurnTools.moves = moves

@rpc("authority", "call_local", "reliable", 0)
func ability_trigger_server_notif(ability:int, card:int, burst_amnt:int, targets:Array[int], turn_used:int) -> void:
	# Runs the pscript's interaction visuals
	var card_as_gui : Card_GUI = id_to_card(card)
	var target_guis : Array[Card_GUI] = id_to_card_array(targets)
	
	
	if card_as_gui == null: 
		return
	for target in target_guis:
		if not is_instance_valid(target):
			continue
		var apply_vfx : Node2D = card_as_gui.attributes[ability].VFX_target.instantiate()
		apply_vfx.finished.connect(apply_vfx.queue_free)
		target.add_child(apply_vfx)
		apply_vfx.position = Vector2(150, 250)
		apply_vfx.emitting = true
	return


var selecting_ability : bool = false ## Used to check if we need to update the Target GUI
var selecting_mulligan : bool = false ## Used to check if we need to show/hide the Confirm Mulligan button

var selecting_cards : bool = false
var max_selections : int = 0
var selected_cards : Array[Card_GUI] = []
var valid_cards : Array[Card_GUI] = []
## Currently just used for allowing targeting empty positions on the field
var valid_metadata : Array[String] = []

func get_targets(user:Card_GUI, ability:Attribute) -> Array[Card_GUI]:
	print("tar type: ", ability.target_type, " amnt: ", ability.targets, " ability name: ", ability.name)
	if ability.targets <= 0 or ability.target_type == 0b0:
		return []
	selected_cards = []
	valid_metadata = [""]
	valid_cards = []
	if ability.allowed_metadata & 0b1:
		valid_metadata.append("empty")
	$TargetingGUI/Options/Burst/BurstSelect.value = 0
	if ability.allow_burst and user.burst > 0:
		$TargetingGUI/Options/Burst.show()
		$TargetingGUI/Options/Burst/BurstSelect.max_value = user.burst
		$TargetingGUI/Options/Burst/BurstAvailable.text = str(user.burst)
	# Target Validation Logic
	for card in cards:
		## For the sake of readability and debugging, these are nested if statements.
		if not valid_metadata.has(card.input_metadata):
			continue
		## So far, the "empty" metadata is only used for the Move targeting, and generally any other use cases I can think of will want to NOT target empty if there's something above it
		if card.input_metadata == "empty" and not card.manager.check_if_position_is_valid(card.manager_position):
			continue
		if card.player_id == user.player_id:
			if card.manager.identifier == "saferoom" and ability.target_type & 0b01000:
				valid_cards.append(card)
			elif card.manager.identifier != "saferoom" and ability.target_type & 0b00010:
				valid_cards.append(card)
		else:
			if card.manager.identifier == "saferoom" and ability.target_type & 0b10000:
				valid_cards.append(card)
			elif card.manager.identifier != "saferoom" and ability.target_type & 0b00100:
				valid_cards.append(card)
	if valid_cards == []:
		print("no valid cards found")
	
	if not ability.allowed_metadata & 0b1:
		print("metadata (if empty not allowed): ", valid_metadata)
	
	## NOTE: Don't auto-trigger if the user has burst available to use
	if (ability.targets < 0 or valid_cards.size() <= ability.targets) and user.burst < 1:
		return valid_cards
	$Dimmer.show()
	$TargetingGUI.show()
	update_target_display()
	selecting_cards = true
	selecting_ability = true
	max_selections = ability.targets
	for vc in valid_cards:
		vc.z_index = 5 + vc.manager.z_index
	var bypass_selection_requirements : bool = false
	if valid_cards.size() <= ability.targets and not ability.allow_burst:
		return valid_cards
	elif valid_cards.size() <= ability.targets and user.burst > 0:
		selected_cards = valid_cards
		bypass_selection_requirements = true
		for card in valid_cards:
			card.set_selection(true)
	while true:
		var confirmation : Array = await tar_conf
		if not confirmation[0] and confirmation[1] == "button":
			selecting_cards = false
			reset_card_indexes()
			$TargetingGUI.hide()
			$Dimmer.hide()
			return []
		if selected_cards.size() == ability.targets and confirmation[1] == "selection" and ( (user.burst < 1 and ability.allow_burst) or not ability.allow_burst ):
			break
		if confirmation[1] == "button" and (selected_cards.size() == ability.targets or bypass_selection_requirements):
			break
	selecting_cards = false
	selecting_ability = false
	reset_card_indexes()
	$Dimmer.hide()
	$TargetingGUI.hide()
	$TargetingGUI/Options/Burst.hide()
	var ret_value : Array[Card_GUI] = []
	ret_value.assign(selected_cards)
	for card in ret_value:
		card.set_selection(false)
	selected_cards = [] # Clears the selection for next time
	valid_cards = []
	max_selections = 0
	return ret_value

## This is connected to the selection_complete signal emitted from _input (in editor)
func selection_confirmation() -> void:
	print("called")
	if selecting_ability:
		#print("also called")
		tar_conf.emit(true, "selection")

signal tar_conf(is_confirmed:bool, source:String)
func target_confirmation() -> void:
	tar_conf.emit(true, "button")

func cancel_targeting() -> void:
	tar_conf.emit(false, "button")
