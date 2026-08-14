extends Node

@export var base_hash : String = ""
@export var version : String = "0.1.0a"



# low key just copying my previous multiplayer networking setup :pray:
## MULTIPLAYER & NETWORKING

var peer : ENetMultiplayerPeer

var our_name : String = "PLAYERNAME"
## [name (string), ID (int), deck (array[string]), ready_status (bool)]
var current_lobby_players : Array = []

var host_id : int

const mod_display_scene := preload("res://GUI/mod_display.tscn")

func _ready() -> void:
	
	## Load Mod List Display
	load_mod_list()
	
	## Networking
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_server_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)
	

## Host a lobby
func _attempt_host() -> void:
	current_lobby_players = []
	our_name = $MainMenu/Waiting/VBoxContainer/Name/PlayerName.text
	peer = ENetMultiplayerPeer.new()
	var port : int = int($MainMenu/Waiting/VBoxContainer/Host/HostIP.text)
	if port < 1024 or port > 65535: # Checks the validity of the port. Below 1024 is privileged (not doable) stuff
		port = 7777 ## TODO: Make this error instead of defaulting to this port
	var err = peer.create_server(port,32)
	if err != 0:
		push_error("Failed to create an ENet host - canceling server hosting")
		return
	multiplayer.multiplayer_peer = peer
	
	current_lobby_players.append([our_name, peer.get_unique_id(), Deck.to_str(prepared_deck), false])
	
	hide_all()
	$MainMenu/Lobby.show()
	reset_lobby()
	var upnp = UPNP.new()
	var success : int = upnp.discover(1000) # 1000 is timeout in milliseconds
	if success == 0:
		upnp.add_port_mapping(port)
		$MainMenu/Lobby/corner/IPS/IP.text = str(upnp.query_external_address()) + ":" + str(port)
	else:
		$MainMenu/Lobby/corner/IPS/IP.text = "Port (IP unknown/not online): " + str(port)
	host_id = peer.get_unique_id()

## TODO: Make this happen asynchronously so the whole game doesn't freeze - however you do that

## Join a lobby
func _attempt_join() -> void:
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
		var their_deck = Deck.from_str(player[2])
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
	## Going to Server
	lobby_joined.rpc(our_name, peer.get_unique_id(), Resources.loaded_hash, Deck.to_str(prepared_deck))

# Sent from Server to update everyone when someone joins the lobby
@rpc("authority", "call_remote", "reliable", 0)
func join_lobby(lobby:Array, host:int) -> void:
	print("Join was recieved!")
	current_lobby_players = lobby
	host_id = host
	reset_lobby()

## Called from Client to Server
@rpc("any_peer", "call_remote", "reliable", 0)
func lobby_joined(player_name:String, p_ID:int, p_hash:PackedByteArray, deck:Array[String]) -> void:
	print("Player wants to join")
	if p_hash != Resources.loaded_hash:
		incorrect_hash.rpc_id(p_ID, Resources.loaded_hash)
		peer.disconnect_peer(p_ID, false)
		print("Player refuted for bad hash, here's the lobby: ", current_lobby_players)
		return
	current_lobby_players.append([player_name, p_ID, deck, false])
	reset_lobby()
	## Going from Server to Client
	push_warning("Our peer ID is: ", peer.get_unique_id())
	join_confirmed.rpc_id(p_ID)
	join_lobby.rpc(current_lobby_players, host_id)

@rpc("authority", "call_remote", "reliable", 0)
func join_confirmed() -> void:
	print("We are verified and joined the lobby!")
	$MainMenu/Waiting.hide()
	$MainMenu/Lobby.show()

@rpc("authority", "call_remote", "reliable", 0)
func incorrect_hash(lob_hash:PackedByteArray) -> void:
	push_error("Tried to join a lobby, but had a mismatching hash! Correct Hash: %s" % lob_hash.hex_encode())
	_quit_lobby()

## Called when anyone joins the lobby
func peer_connected(_id:int=0) -> void:
	for user in current_lobby_players:
		user[3] = false

## Triggers when someone disconnects from us
var joining_lobby : bool :
	get():
		return peer.get_connection_status() == 1
func _disconnect(_whoid:int=0) -> void:
	if (joining_lobby and _whoid == peer.get_unique_id()) or current_lobby_players.size() < 1:
		return_to_menu()
		return
	if joining_lobby:
		return
	var player = get_player(_whoid)
	if player > -1:
		current_lobby_players.remove_at(player) 
	# When someone leaves or joins, reset everybody's ready status
	for user in current_lobby_players:
		user[3] = false
	$MainMenu/Lobby/corner/ready.show()
	reset_lobby()

## Triggers when we disconnect from the server
func _server_disconnect(_whoid:int=0) -> void:
	return_to_menu()

func _quit_lobby() -> void:
	current_lobby_players = []
	if peer != null:
		peer.close()
		multiplayer.multiplayer_peer = null
		peer = null
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
	if current_lobby_players.size() < 2:
		return
	var who : int = get_player(id)
	if who == -1:
		push_error("A player that has left or couldn't be found tried to ready up!")
		return
	
	## allows them to de-ready
	current_lobby_players[who][3] = not current_lobby_players[who][3]
	#if current_lobby_players[who][1] == peer.get_unique_id():
		#$MainMenu/Lobby/corner/ready.hide()
	# check if this is host
	if peer.get_unique_id() == host_id:
		var should_start : bool = true
		for player in current_lobby_players:
			# the 'true' prevents two unreadied players from flipping should_start back to true
			should_start = should_start && player[3] && true
		if should_start:
			print("All players ready! Allowing host to start!")
			$MainMenu/Lobby/corner/gamestarter.show()
		else:
			$MainMenu/Lobby/corner/gamestarter.hide()
	reset_lobby()

func button_start_game() -> void:
	print("Host has started the game!")
	switch_to_game.rpc()
	$Gameplay/Playfield.initalize_game()

@rpc("authority", "call_local", "reliable", 0)
func switch_to_game() -> void:
	$MainMenu.hide()
	$Gameplay.show()
	$Gameplay/Playfield.peer = peer
	$Gameplay/Playfield.host_id = host_id
	var lobby_with_proper_resources : Array = []
	for player in current_lobby_players:
		var get_deck : Deck = Deck.from_str(player[2])
		var fixed_player : Array = []
		fixed_player.assign(player)
		fixed_player.pop_back() # Remove the 'Ready' entry from the lobby
		fixed_player[2] = get_deck # Turn the Deck into a proper Deck resource
		lobby_with_proper_resources.append(fixed_player)
	$Gameplay/Playfield.current_players = lobby_with_proper_resources
	$Gameplay/Playfield.assign_teams()

## ^ MULTIPLAYER & NETWORKING

const HASH_MISMATCH_COLOR := Color(0.951, 0.633, 0.0, 1.0)
const HASH_CORRECT_COLOR := Color(0.0, 0.0, 0.0, 1.0)

func load_version_hash() -> void:
	var hash_shrinker : PackedByteArray = [0,0]
	for i in Resources.loaded_hash.size():
		if i%2 == 0:
			hash_shrinker[0] += Resources.loaded_hash[i]
		else:
			hash_shrinker[1] += Resources.loaded_hash[i]
	$MainMenu/CornerInfo/VerCheck/Num.text = version
	$MainMenu/CornerInfo/VerCheck/Hash.text = hash_shrinker.hex_encode()
	$MainMenu/CornerInfo/VerCheck/Hash/Copy.tooltip_text = "Checksum: " + Resources.loaded_hash.hex_encode() + " (Click to Copy)"
	
	if Resources.loaded_hash.hex_encode() != base_hash:
		#$MainMenu/CornerInfo/VerCheck/Hash.add_theme_color_override("font_color", HASH_MISMATCH_COLOR)
		$MainMenu/CornerInfo/VerCheck.theme.set_color("font_color", "Label", HASH_MISMATCH_COLOR)
	else:
		#$MainMenu/CornerInfo/VerCheck/Hash.add_theme_color_override("font_color", HASH_CORRECT_COLOR)
		$MainMenu/CornerInfo/VerCheck.theme.set_color("font_color", "Label", HASH_CORRECT_COLOR)

func _start_pressed() -> void:
	$MainMenu/Menu/VBoxContainer/Start.hide()
	#$MainMenu/VBoxContainer/MenuSpacer.hide()
	$MainMenu/Menu/VBoxContainer/AccessedMenu.show()

func hide_all() -> void:
	$ModList.hide()
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

## Called by Signal
func prepare_battle() -> void:
	hide_all()
	$MainMenu/BattleSelect.show()

## Called by signal
func ready_for_battle(deck:Deck) -> void:
	hide_all()
	prepared_deck = deck
	$MainMenu/Waiting/VBoxContainer/MiniDeck.load_deck(deck)
	$MainMenu/Waiting.show()

var prepared_deck : Deck







func _on_mods_pressed() -> void:
	$ModList.show()


func _on_reload_scene() -> void:
	load_mod_list()
	_quit_lobby()

func load_mod_list() -> void:
	for child in $ModList/BG/List/Scroll/ModList.get_children():
		child.queue_free()
	for mod in Resources.loaded_mods:
		var new_mod_disp := mod_display_scene.instantiate()
		$ModList/BG/List/Scroll/ModList.add_child(new_mod_disp)
		new_mod_disp.mod = mod
		new_mod_disp.mod_toggled.connect($ModList._on_mod_toggled)
	$MainMenu/BattleSelect.load_decks()
	load_version_hash()


func _on_hash_checksum_copy_pressed() -> void:
	DisplayServer.clipboard_set(Resources.loaded_hash.hex_encode())
