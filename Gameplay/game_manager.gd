extends Control

## This information is transferred from the Main Menu script on game initialization
var peer : ENetMultiplayerPeer

var host_id : int
## [name (string), ID (int), deck (Deck), team (int)]
const default_deck := preload("res://Resources/BasicResources/demo_deck.tres")
var current_players : Array = [ ["default_player", 1, default_deck], ["default_enemy", 2, default_deck], ["player_3", 3, default_deck]]

# Assumption: First entry is always the client player
# deck array structure: [player_id, Deck], [...], etc.

@export
var test_decks:Array[Deck]

## __ MULTIPLAYER (AND RELATED) FUNCTIONS __

func initalize_game(player_data:Array, host:int) -> void:
	current_players = player_data
	host_id = host
	assign_teams()
	initalize_cards(player_data)
	
	#load_items(decks)
	#load_gadgets(decks)
	#load_sword(decks)
	
	#start_mulligan()

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
			add_card(card, get_docker("saferoom", player[3]), player[1])

## The server should sync important information, like stats, but the more complex information - such as abilities, visual effects, etc, will rely on the client side info; if the client modifies them, only visual effects should change


func sync_card(card:Card_GUI) -> void:
	var stats : Array = card.get_stats()
	# Resource names
	var resources : Array = [card.stored_card.name, card.get_attributes(), card.get_status()]
	var other_card_data : Array = [card.unique_id, card.player_id, card.manager.id]
	recieved_card_sync.rpc(card.unique_id, stats, resources, other_card_data)

@rpc("authority", "call_remote", "reliable", 0)
func recieved_card_sync(card_id:int, stats:Array, card_resources:Array, other_card_data:Array) -> void:
	var card_instance : Card_GUI
	for card in cards:
		if card.unique_id == card_id:
			card_instance = card
	if card_instance == null:
		card_instance = add_card(Resources.find_resource("Character", card_resources[0]), get_docker_by_id(other_card_data[2]), other_card_data[1], other_card_data[0])
	card_instance.apply_stats(stats)
	## Update the statuses and abilities to the current counters - i.e., cooldown, ticks of damage left, etc etc
	#card.statuses = card_data_pointers[2]
	

#func get_cGUI_as_identifiers(cGUI:Array[Card_GUI]) -> Array[int]:
	#var return_array : Array[int] = []
	#for card in cGUI:
		#return_array.append(card.unique_id)
	#return return_array




## ^^ MULTIPLAYER FUNCTIONS ^^

#var awaiting_mulligan : bool = false
#var mulligan_selections : Array[Card_GUI] = []
### required number of characters to choose for the game opening
#const MULLIGAN_TO_SELECT : int = 3

## Displays all characters (not special characters) in a players deck and allows them to choose 3 and confirm, then deploys those cards onto the Field, notifies the other players, and puts the remaining in the safe room
#func start_mulligan() -> void:
	#$Unscalables/MulliganBG.show()
	#$Mulligan.show()
	#for player in current_players:
		#load_mulligan_cards(player[3], player[1], peer.get_unique_id() == player[1])
	#awaiting_mulligan = true
	#mulligan_selections = []
	##await $Mulligan/ConfirmMulligan.pressed
	## await update
	##$Unscalables/MulliganBG.hide()

#func confirm_mulligan_selection() -> void:
	#if mulligan_selections.size() == MULLIGAN_TO_SELECT:
		#awaiting_mulligan = false
		#$Mulligan.hide()
		#for card in mulligan_selections:
			#card.assign_manager(get_docker("field", 1))
		##client_confirm_mulligan.rpc()

#@rpc("any_peer", "call_remote", "reliable", 0)
#func client_confirm_mulligan(card_assignments) -> void:
	#pass

#func load_mulligan_cards(deck:Deck, player:int, self_controlled:bool) -> void:
	#for chara in deck.special_characters:
		#add_card(chara, get_docker("saferoom", 1 if self_controlled else 2), player)
	#for chara in deck.characters:
		#if self_controlled:
			#add_card(chara, get_docker("mulligan", -1), player)
		#else: # Put the enemy player's card inside the saferoom - we'll update and move them at the end of the mulligan phase where cards are re-synced
			#add_card(chara, get_docker("saferoom", 2), player)
	

func load_items(decks:Array) -> void:
	pass

func load_gadgets(decks:Array) -> void:
	pass

func load_sword(decks:Array) -> void:
	$Unscalables/SwordUI.icon = decks[0][1].sword.icon



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
	#load_deck(current_players[0], 1)
	#load_deck(current_players[1], 2)
	update_dockers()

# Destination could also be the saferoom.
#func load_deck(info:Array, team:int) -> void:
	#for card in info[3].special_characters:
		#add_card(card, get_docker("field", team), info[1])
	#for card in info[3].characters:
		#add_card(card, get_docker("saferoom", team), info[1])


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

func request_server_for_id() -> void:
	pass

func get_docker(which:String, team:int) -> Docker:
	for docker in get_dockers():
		if docker.identifier == which and (docker.player == team or team < 0):
			return docker
	return

func get_docker_by_id(id:int) -> Docker:
	for docker in get_dockers():
		if docker.id == id:
			return docker
	return

var menu_open : bool = false
var active_interact_card : Card_GUI
var allow_drag : bool = true

# Called when a card is clicked with the interaction menu key/mouse
# note - the Card_GUI already culls and only emits if the event is mouse button
func card_clicked(event: InputEvent, who:Card_GUI) -> void:
	var area := Rect2(Vector2(0,0), self.size)
	if area.has_point(get_local_mouse_position()):
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and selecting_cards and valid_cards.has(who):
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

func update_dockers(force_movement:bool=false) -> void:
	for docker in get_dockers():
		var positions := docker.get_placements()
		for card in docker.assigned_cards.size():
			if force_movement:
				docker.assigned_cards[card].position = positions[card]
			docker.assigned_cards[card].target_position = positions[card]
			docker.assigned_cards[card].scale = docker.scale
	return

#func update_scale(target:Node=self, ignore_restrictions:bool = false) -> void:
	#for child:Control in target.get_children():
		#if child is Card_GUI or ignore_restrictions:
			#child.scale = Vector2(ui_scale, ui_scale)

func update_target_display() -> void:
	## This code will display the name of the selected targets
	## Currently disabled, in favor of Card_GUI having a Currently Selected effect
	#for child in $TargetingGUI/HBoxContainer/tar_amnt.get_children():
		#child.queue_free()
	#for card in selected_cards:
		#var new_label : Label = Label.new()
		#new_label.text = card.stored_card.name
		#$TargetingGUI/HBoxContainer/tar_amnt.add_child(new_label)
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
		card.z_index = 0

## ABILITY TARGETING & TRIGGERS


func trigger_ability(ability:Attribute, card:Card_GUI) -> void:
	print("An ability was triggered!")
	if $Unscalables/TurnTools.moves < 1:
		print("not enough moves! Cancelling!")
		return
	close_interaction_menu() # Abilities are often triggered when this is open
	allow_drag = false # Prevent dragging during the ability trigger
	var targeting : Array[Card_GUI] = await get_targets(card, ability)
	if targeting == []:
		print("Targeting cancelled or failed")
		allow_drag = true
		return
	print("We selected cards to target!: ", targeting)
	
	# Runs the pscript's interaction effect
	if not ability.pscript == null:
		var script_instance = ability.pscript.new([card])
		var burst_amnt : int = 0
		if ability.allow_burst:
			burst_amnt = $TargetingGUI/Options/Burst/BurstSelect.value
		for i in range(0, 1+burst_amnt):
			script_instance._interaction(targeting)
	update_dockers()
	allow_drag = true # Restore drag
	$Unscalables/TurnTools.moves -= 1
	return


var selecting_cards : bool = false
var max_selections : int = 0
var selected_cards : Array[Card_GUI] = []
var valid_cards : Array[Card_GUI] = []

func get_targets(user:Card_GUI, ability:Attribute) -> Array[Card_GUI]:
	print("tar type: ", ability.target_type, " amnt: ", ability.targets)
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
		vc.z_index = 5
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
