extends Node

const major_version : int = 0
const minor_version : int = 1
const revision : int = 0



# low key just copying my previous multiplayer networking setup :pray:
## MULTIPLAYER & NETWORKING

var peer : ENetMultiplayerPeer

var our_name : String = "PLAYERNAME"
## [name (string), ID (int), deck (array[string]), ready_status (bool)]
var current_lobby_players : Array = []

var host_id : int

func _ready() -> void:
	
	## Networking
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_server_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)
	
	generate_version_hash()

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
	
	current_lobby_players.append([our_name, peer.get_unique_id(), deck_to_string(prepared_deck), false])
	
	hide_all()
	$MainMenu/Lobby.show()
	reset_lobby()
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	$MainMenu/Lobby/corner/IPS/IP.text = str(upnp.query_external_address()) + ":" + str(port)
	host_id = peer.get_unique_id()

## TODO: Make this happen asynchronously so the whole game doesn't freeze - however you do that

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
	var title : Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "Players (" + str(current_lobby_players.size()) + "/2)"
	$MainMenu/Lobby/PlayerList.add_child(title)
	for player in current_lobby_players:
		var new_play := plgui.instantiate()
		
		new_play.player = get_lobby_label(player)
		var their_deck = string_to_deck(player[2])
		new_play.load_deck(their_deck)
		$MainMenu/Lobby/PlayerList.add_child(new_play)

func get_lobby_label(player:Array) -> String:
	var txt : String = player[0]
	if player[1] == host_id:
		txt += " (Host)"
	if player[3]:
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
func join_lobby(lobby:Array, host:int) -> void:
	print("Join was recieved!")
	current_lobby_players = lobby
	host_id = host
	reset_lobby()

## Called from Client to Server
@rpc("any_peer", "call_remote", "reliable", 0)
func lobby_joined(player_name:String, p_ID:int, deck:Array[String]) -> void:
	print("Player wants to join")
	current_lobby_players.append([player_name, p_ID, deck, false])
	reset_lobby()
	## Going from Server to Client
	join_lobby.rpc(current_lobby_players, host_id)

## ADD SYNC CODE / COMMUNICATE GAMEPLAY

## Called when anyone joins the lobby
func peer_connected(_id:int=0) -> void:
	for user in current_lobby_players:
		user[3] = false

## Triggers when someone disconnects from us
var joining_lobby : bool = false
func _disconnect(_whoid:int=0) -> void:
	if (joining_lobby and _whoid == peer.get_unique_id()) or current_lobby_players.size() < 1:
		return_to_menu()
		return # ^ Not sure if this code needs to be here. - may only be used in the server disconnect code
	var player = get_player(_whoid)
	if current_lobby_players[player][1] == host_id: # If host disconnects, everyone should return to menu.
		return_to_menu()
		return
	current_lobby_players.remove_at(player) # When someone leaves or joins, reset everybody's ready status
	for user in current_lobby_players:
		user[3] = false
	$MainMenu/Lobby/corner/ready.show()
	joining_lobby = false
	reset_lobby()

## Triggers when we disconnect from the server
func _server_disconnect(_whoid:int=0) -> void:
	return_to_menu()

func _quit_lobby() -> void:
	current_lobby_players = []
	peer.close()
	return_to_menu()

## Clears and resets the lobby
func reset_lobby() -> void:
	for child in $MainMenu/Lobby/PlayerList.get_children():
		child.queue_free()
	#$MainMenu/Lobby/corner/ready.show()
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
	
	current_lobby_players[who][3] = true
	#if current_lobby_players[who][1] == peer.get_unique_id():
		#$MainMenu/Lobby/corner/ready.hide()
	# check if this is host
	if peer.get_unique_id() == host_id:
		var should_start : bool = true
		for player in current_lobby_players:
			# the 'true' prevents two unreadied players from flipping should_start back to true
			should_start = should_start && player[3] && true
		if current_lobby_players.size() > 2:
			push_error("Can't start game! Currently only supports 2 players.")
			should_start = false
		if should_start:
			print("All players ready! Starting!")
			switch_to_game.rpc()
			$Gameplay/Playfield.initalize_game()
	reset_lobby()

@rpc("authority", "call_local", "reliable", 0)
func switch_to_game() -> void:
	$MainMenu.hide()
	$Gameplay.show()
	$Gameplay/Playfield.peer = peer
	$Gameplay/Playfield.host_id = host_id
	var lobby_with_proper_resources : Array = []
	for player in current_lobby_players:
		var get_deck : Deck = string_to_deck(player[2])
		var fixed_player : Array = []
		fixed_player.assign(player)
		fixed_player.pop_back() # Remove the 'Ready' entry from the lobby
		fixed_player[2] = get_deck # Turn the Deck into a proper Deck resource
		lobby_with_proper_resources.append(fixed_player)
	$Gameplay/Playfield.current_players = lobby_with_proper_resources
	$Gameplay/Playfield.assign_teams()

## ^ MULTIPLAYER & NETWORKING

func generate_version_hash() -> void:
	#var hash_array : Array = []
	#hash_array.append(Resources.attributes.hash())
	#hash_array.append(Resources.characters.hash())
	#var final_hash : int = hash_array.hash()
	$MainMenu/Version.text = "Version: " + str(major_version) + "." + str(minor_version) + "." + str(revision)# + " (checksum: " + str(final_hash) + ")"
	## Note: using Array.hash() can generate completely different hashes for identical data

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
			"Character":
				var chara = Resources.find_resource(split[0], split[1])
				if chara != null:
					zombie.characters.append(chara)
	return zombie

func deck_to_string(deck:Deck) -> Array[String]:
	var string : Array[String] = []
	for chara in deck.characters:
		string.append("Character:" + chara.name)
	for gadg in deck.gadgets:
		string.append("Gadget:" + gadg.name)
	for item in deck.items:
		string.append("Item:"+item.name)
	if deck.sword != null:
		string.append("Sword:"+deck.sword.name)
	return string

## RESOURCE MANAGEMENT
