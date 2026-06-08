extends Node

# low key just copying my previous multiplayer networking setup :pray:
## MULTIPLAYER & NETWORKING

var our_name : String = "PLAYERNAME"
## [name (string), ID (int), is host? (bool), deck (array[string]), ready_status (bool)]
var current_lobby_players : Array = []

@export
var save_to_file_Decks : Array[Deck] = []

var opponent_names : Array[String] = [""]

var our_ready : bool = false
var opponent_readies : Array[bool] = [false]

func _ready() -> void:
	var deck_txt : Array[Array] = []
	for deck in save_to_file_Decks:
		deck_txt.append(deck_to_string(deck))
	print(JSON.stringify(deck_txt), "\t")
	
	## Networking
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)
	
	load_saved_decks()

var peer : ENetMultiplayerPeer
## Host a lobby
func _attempt_host() -> void:
	current_lobby_players = []
	our_name = $MainMenu/Waiting/VBoxContainer/Name/PlayerName.text
	peer = ENetMultiplayerPeer.new()
	var port : int = int($MainMenu/Waiting/VBoxContainer/Host/HostIP.text)
	if port < 1024 or port > 65535: # Checks the validity of the port. Below 1024 is privleged (not doable) stuff
		port = 7777
	peer.create_server(port,32)
	multiplayer.multiplayer_peer = peer
	
	current_lobby_players.append([our_name, peer.get_unique_id(), true, deck_to_string(prepared_deck), false])
	
	hide_all()
	$MainMenu/Lobby.show()
	load_lobby_gui()
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	$MainMenu/Lobby/corner/IPS/IP.text = str(upnp.query_external_address()) + ":" + str(port)

## TODO: Make this happen asynchronously so the whole game doesn't freeze

## Join a lobby
func _attempt_join() -> void:
	joining_lobby = true
	our_name = $MainMenu/Waiting/VBoxContainer/Name/PlayerName.text
	var IP_address : String = $MainMenu/Waiting/VBoxContainer/Join/JoinInput.text
	if IP_address == "":
		IP_address = "127.0.0.1:7777"
	peer = ENetMultiplayerPeer.new()
	var seperate := IP_address.split(":")
	if seperate.size() != 2:
		push_error("Tried to join a game, but the IP address was formatted incorrectly!")
		return
	var ip : String = seperate[0]
	var port : int = int(seperate[1])
	var error := peer.create_client(ip, port)
	if error != OK:
		push_error("There was an issue connecting! Error code: ", error)
	$MainMenu/Lobby/corner/IPS/IP.text = ip + ":" + str(port)
	multiplayer.multiplayer_peer = peer
	print("Should be joining...")

const plgui := preload("res://GUI/playerlobby_deck.tscn")
func load_lobby_gui() -> void:
	$MainMenu/Lobby.show()
	var title : Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "Players (" + str(current_lobby_players.size()) + "/2)"
	$MainMenu/Lobby/PlayerList.add_child(title)
	for player in current_lobby_players:
		var new_play := plgui.instantiate()
		
		new_play.player = get_lobby_label(player)
		var their_deck = string_to_deck(player[3])
		new_play.load_deck(their_deck)
		$MainMenu/Lobby/PlayerList.add_child(new_play)

func get_lobby_label(player:Array) -> String:
	var txt : String = player[0]
	if player[2]:
		txt += " (Host)"
	if player[4]:
		txt += " Ready!"
	return txt

# Called when we join a server
func join_connected(_id:int=0) -> void:
	$MainMenu/Waiting.hide()
	$MainMenu/Lobby.show()
	## Going to Server
	lobby_joined.rpc(our_name, peer.get_unique_id(), deck_to_string(prepared_deck))

# Sent from Server to update everyone when someone joins the lobby
@rpc("authority", "call_remote", "reliable", 0)
func join_lobby(lobby:Array) -> void:
	print("Join was recieved!")
	current_lobby_players = lobby
	reset_lobby()

## Called from Client to Server
@rpc("any_peer", "call_remote", "reliable", 0)
func lobby_joined(player_name:String, p_ID:int, deck:Array[String]) -> void:
	print("Player wants to join")
	current_lobby_players.append([player_name, p_ID, false, deck, false])
	reset_lobby()
	## Going from Server to Client
	join_lobby.rpc(current_lobby_players)

## ADD SYNC CODE / COMMUNICATE GAMEPLAY

## Called when anyone joins the lobby
func peer_connected(_id:int=0) -> void:
	for user in current_lobby_players:
		user[4] = false

var joining_lobby : bool = false
func _disconnect(_whoid:int=0) -> void:
	if joining_lobby and _whoid == peer.get_unique_id():
		return_to_menu()
		return
	# Temp; should update lobby visuals (if host) other wise return to menu if peer/connecting
	var player = get_player(_whoid)
	current_lobby_players.remove_at(player) # When someone leaves or joins, reset everybody's ready status
	for user in current_lobby_players:
		user[4] = false
	joining_lobby = false
	reset_lobby()

## Clears and resets the lobby
func reset_lobby() -> void:
	for child in $MainMenu/Lobby/PlayerList.get_children():
		child.queue_free()
	load_lobby_gui()

## Gets a player's index in the lobby by their id or name.
func get_player(who:Variant) -> int:
	var search : int = 0
	match(typeof(who)):
		TYPE_STRING, TYPE_STRING_NAME:
			search = 0
		TYPE_INT:
			search = 1
	for player in current_lobby_players.size():
		if current_lobby_players[player][search] == who:
			return player
	return -1

func ready_button_pressed() -> void:
	print("readying up!")
	rpc("ready_up", peer.get_unique_id())

@rpc("any_peer", "call_local", "reliable", 1)
func ready_up(id:int) -> void:
	print("I got a ready up!")
	var who : int = get_player(id)
	if who == -1:
		push_error("A player that has left or couldn't be found tried to ready up!")
		return
	current_lobby_players[who][4] = true
	
	if current_lobby_players[get_player(peer.get_unique_id())][2]:
		var should_start : bool = true
		for player in current_lobby_players:
			should_start = should_start && player[4] && true
		if current_lobby_players.size() > 2:
			push_error("Can't start game! Currently only supports 2 players.")
			should_start = false
		if should_start:
			pass
			#start_game()
	
	reset_lobby()


## ^ MULTIPLAYER & NETWORKING

func _start_pressed() -> void:
	$MainMenu/Menu/VBoxContainer/Start.hide()
	#$MainMenu/VBoxContainer/MenuSpacer.hide()
	$MainMenu/Menu/VBoxContainer/AccessedMenu.show()

func hide_all() -> void:
	$MainMenu/Menu.hide()
	$MainMenu/Deck.hide()
	$MainMenu/BattleSelect.hide()
	$MainMenu/Waiting.hide()
	$MainMenu/Lobby.hide()
	
	$Gameplay.hide()

func _on_deck_pressed() -> void:
	hide_all()
	$MainMenu/Deck.show()

func return_to_menu() -> void:
	hide_all()
	$MainMenu/Menu.show()

func prepare_battle() -> void:
	hide_all()
	$MainMenu/BattleSelect.show()

var prepared_deck : Deck
func ready_for_battle(deck:Deck) -> void:
	hide_all()
	# Show "Waiting on other player. Your Deck: DECK"
	# Multiplayer stuff
	prepared_deck = deck
	#local_peer_send "I am ready" message
	$MainMenu/Waiting/VBoxContainer/MiniDeck.load_deck(deck)
	$MainMenu/Waiting.show()

func string_to_deck(deck:Array[String]) -> Deck:
	var zombie : Deck = Deck.new()
	for card in deck:
		var split := card.split(":", 1)
		match(split[0]):
			"SpecialCharacter":
				var chara = Resources.find_resource(split[0], split[1])
				if chara != null:
					zombie.special_characters.append(chara)
	return zombie

func deck_to_string(deck:Deck) -> Array[String]:
	var string : Array[String] = []
	for spechar in deck.special_characters:
		string.append("SpecialCharacter:" + spechar.name)
	return string

## RESOURCE MANAGEMENT














## TODO: save decks to user:// and load them from there
func load_saved_decks() -> void:
	var decks : Array[Deck] = []
	var JSONData := JSON.new()
	if not (FileAccess.file_exists("res://Data/Decks/defaults.json")):
		push_error("Couldn't load decks because no defaults.json file was found!")
		return
	var file := FileAccess.open("res://Data/Decks/defaults.json", FileAccess.READ)
	var fileJSON : String = file.get_as_text()
	var error = JSONData.parse(fileJSON)
	if error:
		push_error("JSON Parsing Error in decks default.json: ", JSONData.get_error_message(), " at line ", JSONData.get_error_line())
		return
	var data = JSONData.data
	if typeof(data) == TYPE_ARRAY:
		for deck in data:
			## string_to_deck expects Array[String] but data is an untyped Array[]
			var type_cast : Array[String]
			type_cast.assign(deck["deck"]) # this is so weird and unintuitive
			var as_resource : Deck = string_to_deck(type_cast)
			as_resource.name = deck["name"]
			decks.append(as_resource)
	print("decks: ", decks)
	$MainMenu/BattleSelect.deck_list = decks
	return
