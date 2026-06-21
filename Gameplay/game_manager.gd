extends Control

## This information is transferred from the Main Menu script on game initialization
var peer : ENetMultiplayerPeer

var host_id : int
## [name (string), ID (int), deck (Deck), team (int)]
const default_deck := preload("res://Resources/BasicResources/demo_deck.tres")
var current_players : Array = [ ["default_player", 1, default_deck], ["default_enemy", 2, default_deck], ["player_3", 3, default_deck]]

func get_player_by_id(id:int) -> Array:
	for player in current_players:
		if player[1] == id:
			return player
	return []



@export
var test_decks:Array[Deck]

## __ MULTIPLAYER (AND RELATED) FUNCTIONS __

# current_players and host_id are updated by the Main_menu manager
func initalize_game() -> void:
	initalize_cards(current_players)
	
	#load_items(decks)
	#load_gadgets(decks)
	#load_sword(decks)
	
	start_mulligan.rpc()

## Clients send actions, the server executes them and sends the results back - while clients wait, they can 'predict' what happens and play their visual effects before the server responds, then update/correct their stats when the server informs them what happened

## This currently only supports 2 players. This code will need to be revised to allow for multiple players in the future.
func assign_teams() -> void:
	for player in current_players.size():
		if current_players[player][1] == peer.get_unique_id():
			current_players[player].append(1)
		else:
			current_players[player].append(2)

func initalize_cards(players:Array) -> void:
	for player in players:
		var deck : Deck = player[2]
		for card in deck.characters:
			var new_card : Card_GUI = add_card(card, get_docker("saferoom", player[3]), player[1])
			sync_card(new_card, true)

## The server should sync important information, like stats, but the more complex information - such as abilities, visual effects, etc, will rely on the client side info; if the client modifies them, only visual effects should change




func sync_card(card:Card_GUI, upd_docker : bool = true) -> void:
	var stats : Array = card.get_stats()
	# Resource names
	var card_resource : String = card.stored_card.name
	var card_ids : Array = [card.unique_id, card.player_id]
	var manager_identifier : String = card.manager.identifier
	var script_data : Array = card.get_script_data()
	var attributes : Array = card.get_attributes()
	_update_individual_docker(card.manager)
	recieved_card_sync.rpc(stats, card_resource, card_ids, manager_identifier, script_data, attributes, upd_docker)

@rpc("authority", "call_remote", "reliable", 0)
func recieved_card_sync(stats:Array, card_name:String, card_ids:Array, manager_id : String, script_data : Array, attribute_data : Array, do_docker_update : bool) -> void:
	var card_instance : Card_GUI
	## Team is relative - need to get dockers by the docker identifier and the relative team
	var current_docker := get_docker(manager_id, get_player_by_id(card_ids[1])[3])
	for card in cards:
		if card.unique_id == card_ids[0]:
			card_instance = card
	if card_instance == null:
		card_instance = add_card(Resources.find_resource("Character", card_name), current_docker, card_ids[1], card_ids[0])
	card_instance.apply_stats(stats)
	card_instance.assign_manager(current_docker)
	card_instance.load_attributes(attribute_data)
	card_instance.update_scripts(script_data)
	if do_docker_update:
		_update_individual_docker(card_instance.manager)



var awaiting_mulligan : bool = false
var mulligan_selections : Array[Card_GUI] = []
var possible_mulligans : Array[Card_GUI] = []
## required number of characters to choose for the game opening
const MULLIGAN_TO_SELECT : int = 3

# Displays all characters (not special characters) in a players deck and allows them to choose 3 and confirm, then deploys those cards onto the Field, notifies the other players, and puts the remaining in the safe room
@rpc("authority", "call_local", "reliable", 0)
func start_mulligan() -> void:
	#$Unscalables/MulliganBG.show()
	$Mulligan.show()
	for card in cards:
		if card.player_id == peer.get_unique_id() and card.stored_card.type == 1:
			possible_mulligans.append(card)
			## ID 5 is the mulligan docker
			card.assign_manager(get_docker_by_id(5))
			if peer.get_unique_id() == host_id:
				sync_card(card, true)
	update_dockers(true)
	awaiting_mulligan = true
	mulligan_selections = []
	players_finished_mulligan = []

func submit_mulligan() -> void:
	if mulligan_selections.size() != MULLIGAN_TO_SELECT:
		return
	awaiting_mulligan = false
	$Mulligan/ConfirmMulligan.hide()
	var cg_as_id : Array[int] = get_card_array_as_id(mulligan_selections)
	send_mulligan_selection.rpc(cg_as_id, peer.get_unique_id())


var players_finished_mulligan : Array[int] = []

## Sent from client to server, gives the server the player - needs to be call_local so the server can send this to itself.
@rpc("any_peer", "call_local", "reliable", 0)
func send_mulligan_selection(selections:Array[int], player_id:int) -> void:
	if host_id != peer.get_unique_id():
		return
	if players_finished_mulligan.has(player_id):
		return
	var player_team :int = get_player_by_id(player_id)[3]
	for selected in selections:
		var as_GUI : Card_GUI = get_card_by_id(selected)
		as_GUI.assign_manager(get_docker("field", player_team))
	players_finished_mulligan.append(player_id)
	if players_finished_mulligan.size() == current_players.size():
		end_mulligan.rpc()

@rpc("authority", "call_local", "reliable", 0)
func end_mulligan() -> void:
	$Mulligan.hide()
	for card in cards:
		card.set_selection(false)
	if host_id == peer.get_unique_id():
		print("We're ready to start the game!!!")
		for card in cards:
			sync_card(card, true)
		#start_game()

var cards : Array[Card_GUI] = []

## Gets every docker in the scene
func get_dockers() -> Array[Docker]:
	var retr : Array[Docker] = []
	for child in get_children():
		if child is Docker:
			retr.append(child)
	return retr


const ui_scale = 0.5

const card_ui_scene := preload("res://GUI/Card/card.tscn")

func _ready() -> void:
	update_dockers()


func add_card(card : Card, docker : Docker, player_id:int, unique_id : int = -1) -> Card_GUI:
	var new_card := card_ui_scene.instantiate()
	new_card.player_id = player_id
	new_card.unique_id = get_unique_card_id() if unique_id == -1 else unique_id
	new_card.controlled = player_id == peer.get_unique_id()
	new_card.interaction.connect(card_clicked.bind(new_card))
	new_card.ability_triggered.connect(trigger_ability)
	add_child(new_card)
	new_card.load_card(card)
	new_card.stopped_dragging.connect(update_dockers)
	new_card.assign_manager(docker)
	cards.append(new_card)
	
	return new_card



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

func get_card_array_as_id(input:Array[Card_GUI]) -> Array[int]:
	var ret_arr : Array[int] = []
	for card in input:
		ret_arr.append(card.unique_id)
	return ret_arr


func get_docker(which:String, team:int) -> Docker:
	for docker in get_dockers():
		if docker.identifier == which and (docker.player == team or team < 0 or docker.player < 0):
			return docker
	return

func get_docker_by_id(id:int) -> Docker:
	for docker in get_dockers():
		if docker.id == id:
			return docker
	return

func get_card_by_id(id:int) -> Card_GUI:
	for card in cards:
		if card.unique_id == id:
			return card
	return

func get_card_array_by_id(ids:Array[int]) -> Array[Card_GUI]:
	var ret_arr : Array[Card_GUI] = []
	for id in ids:
		ret_arr.append(get_card_by_id(id))
	return ret_arr

var menu_open : bool = false
var active_interact_card : Card_GUI
var allow_drag : bool = true

# Called when a card is clicked with the interaction menu key/mouse
# note - the Card_GUI already culls and only emits if the event is mouse button
func card_clicked(event: InputEvent, who:Card_GUI) -> void:
	var area := Rect2(Vector2(0,0), self.size)
	if area.has_point(get_local_mouse_position()):
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if selecting_cards and valid_cards.has(who):
				var ind : int = selected_cards.find(who)
				if ind != -1:
					who.set_selection(false)
					selected_cards.pop_at(ind)
					update_target_display()
					return
				# When clicking while at max, replace the last-clicked target
				if not selected_cards.size() < max_selections:
					selected_cards[-1].set_selection(false)
					selected_cards.pop_back()
				who.set_selection(true)
				selected_cards.append(who)
				update_target_display()
				if selected_cards.size() == max_selections:
					tar_conf.emit(true, "selection")
				return
			if awaiting_mulligan and possible_mulligans.has(who):
				var exists : int = mulligan_selections.find(who)
				if exists != -1:
					who.set_selection(false)
					mulligan_selections.pop_at(exists)
					return
				mulligan_selections.append(who)
				who.set_selection(true)
				return
		if event.button_mask & MOUSE_BUTTON_MASK_RIGHT and not menu_open and not selected_cards:
			active_interact_card = who
			open_interaction_menu()
			who.open_interaction_menu()
	return

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not selecting_cards:
		if menu_open and event.is_action_pressed("card_interact"):
			close_interaction_menu()
			accept_event()


# Open the interaction menu!
func open_interaction_menu() -> void:
	menu_open = true
	allow_drag = false
	active_interact_card.scale = Vector2(1.0,1.0)
	active_interact_card.position = get_viewport_rect().size * 0.5 - active_interact_card.size * 0.5
	active_interact_card.target_position = get_viewport_rect().size * 0.5 - active_interact_card.size * 0.5
	$Dimmer.show()
# Close it!
func close_interaction_menu() -> void:
	if active_interact_card != null and not active_interact_card.is_queued_for_deletion():
		active_interact_card.close_interaction_menu()
	menu_open = false
	allow_drag = true
	update_dockers(true)
	$Dimmer.hide()
	reset_card_indexes()


func update_dockers(force_movement:bool=true) -> void:
	for docker in get_dockers():
		_update_individual_docker(docker, force_movement)
	return


func _update_individual_docker(docker:Docker, force_movement:bool = true) -> void:
	var positions := docker.get_placements()
	for card in docker.assigned_cards.size():
		if force_movement:
			docker.assigned_cards[card].position = positions[card]
		docker.assigned_cards[card].target_position = positions[card]
		docker.assigned_cards[card].scale = docker.scale
	return


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

## ABILITY TARGETING & TRIGGERS

## The ability int refers to the position of the array in the Card_GUI's attributes. 
func trigger_ability(ability:int, card:Card_GUI) -> void:
	print("An ability was triggered!")
	if $Unscalables/TurnTools.moves < 1:
		print("not enough moves! Cancelling!")
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
	var targets_to_id : Array[int] = get_card_array_as_id(targeting)
	trigger_ability_client.rpc(ability, card.unique_id, burst_amnt, targets_to_id)
	

## card [int] is the unique ID of the Card_GUI that is the source
@rpc("any_peer", "call_local", "reliable", 0)
func trigger_ability_client(ability:int, card:int, burst_amnt:int, targets:Array[int]) -> void:
	# Runs the pscript's interaction effect
	var card_as_gui : Card_GUI = get_card_by_id(card)
	var target_guis : Array[Card_GUI] = get_card_array_by_id(targets)
	
	for i in range(0, 1+burst_amnt):
		card_as_gui.attribute_scripts[ability]._interaction(target_guis)
	update_dockers()
	
	if peer.get_unique_id() == host_id:
		for unit in cards:
			sync_card(unit, true)
		# Change the move counter, etc.
	return





var selecting_cards : bool = false
var max_selections : int = 0
var selected_cards : Array[Card_GUI] = []
var valid_cards : Array[Card_GUI] = []

func get_targets(user:Card_GUI, ability:Attribute) -> Array[Card_GUI]:
	print("tar type: ", ability.target_type, " amnt: ", ability.targets, " ability name: ", ability.name)
	if ability.targets == 0:
		return []
	selected_cards = []
	valid_cards = []
	$TargetingGUI/Options/Burst/BurstSelect.value = 0
	if ability.allow_burst and user.burst > 0:
		$TargetingGUI/Options/Burst.show()
		$TargetingGUI/Options/Burst/BurstSelect.max_value = user.burst
		$TargetingGUI/Options/Burst/BurstAvailable.text = str(user.burst)
	# Target Validation Logic
	for card in cards:
		## For the sake of readability and debugging, these are nested if statements.
		if card.player_id == user.player_id:
			if card.manager.identifier == "saferoom" and ability.target_type & 0b0100:
				valid_cards.append(card)
			elif card.manager.identifier != "saferoom" and ability.target_type & 0b0001:
				valid_cards.append(card)
		else:
			if card.manager.identifier == "saferoom" and ability.target_type & 0b1000:
				valid_cards.append(card)
			elif card.manager.identifier != "saferoom" and ability.target_type & 0b0010:
				valid_cards.append(card)
	if valid_cards == []:
		print("no valid cards, selecting self")
		valid_cards = [user]
	## Note: Don't auto-trigger if the user has burst available to use
	if ability.targets < 0 or valid_cards.size() <= ability.targets:
		return valid_cards
	$Dimmer.show()
	$TargetingGUI.show()
	update_target_display()
	selecting_cards = true
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

signal tar_conf(is_confirmed:bool)
func target_confirmation() -> void:
	tar_conf.emit(true, "button")

func cancel_targeting() -> void:
	tar_conf.emit(false, "button")


func _turn_ended() -> void:
	$Unscalables/TurnTools.moves = 2
