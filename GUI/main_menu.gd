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
#var holepunch_id : String = "" #str(randi()) #OS.get_unique_id() 
## Switch holepunch_id to OS when not performing local testing
@export var signaling_server_ipv4 : String = "73.25.210.98"
@export var signaling_server_ipv6 : String = ""
@export var holepunch_port : int = 7777

const mod_display_scene := preload("res://GUI/mod_display.tscn")

#var hole_puncher

func _ready() -> void:
	
	#holepunch_id = str(randf())
	
	## Load Mod List Display
	load_mod_list()
	
	## Networking
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_server_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)

var hosting : bool = false

## Using HolePunch Addon
func nat_traversal(is_host:bool, game_code:String="", ipv4:bool=true) -> void:
	var hole_puncher = HolePuncher.new()
	
	if ipv4:
		hole_puncher.signaling_address = signaling_server_ipv4
	else:
		hole_puncher.signaling_address = signaling_server_ipv6
	hole_puncher.signaling_port = holepunch_port
	var lo_port : int = $MainMenu/Waiting/debugdisplay/list/Port/LocalPort.text.to_int()
	if lo_port < 1024 or lo_port > 65535:
		lo_port = 9999
	hole_puncher.local_port = lo_port
	add_child(hole_puncher)
	hosting = is_host
	hole_puncher.hole_punched.connect(hole_punched)
	hole_puncher.session_registered.connect(nat_session_registered)
	var player_host = "host" if is_host else "client"
	print("Starting hole-punch as %s" % player_host)
	var holepunch_id = "%s_%s" % [OS.get_unique_id(), player_host]
	hole_puncher.our_id = holepunch_id
	var game_id : String = game_code
	if game_code == "":
		game_id = generate_game_code()
		print("Created game with code: ", game_id)
		$MainMenu/Waiting/VBoxContainer/Join/GameID.text = game_id
	if not ipv4:
		hole_puncher.ipv6_failed.connect(_ipv6_failed.bind(game_id))
	hole_puncher.start_traversal(game_id, is_host, holepunch_id, ipv4)

func hole_punched(my_port, hosts_port, hosts_address) -> void:
	print("Hole-punch successful!")
	peer = ENetMultiplayerPeer.new()
	if hosting:
		peer.create_server(my_port, 1)
		multiplayer.multiplayer_peer = peer
		current_lobby_players.append([our_name, peer.get_unique_id(), Deck.to_str(prepared_deck), false])
		hide_all()
		$MainMenu/Lobby.show()
		reset_lobby()
		#get_tree().set_multiplayer(peer)
		return
	peer.create_client(hosts_address, hosts_port, 0, 0, 0, my_port)
	multiplayer.multiplayer_peer = peer

func nat_session_registered(is_ipv4:bool) -> void:
	print("We've connected with the signaling server.")
	if is_ipv4:
		$MainMenu/Waiting/debugdisplay/list/ipv4/status.text = "Connected"
	else:
		$MainMenu/Waiting/debugdisplay/list/ipv6/status.text = "Connected"

## Host a lobby
func _attempt_host() -> void:
	print("Beginning to attempt host")
	current_lobby_players = []
	our_name = $MainMenu/Waiting/VBoxContainer/Name/PlayerName.text
	#hosting = true
	## Begin Hole Punching
	var game_id : String = $MainMenu/Waiting/VBoxContainer/Join/GameID.text
	#$MainMenu/Waiting/VBoxContainer/Join/GameID.editable = false
	nat_traversal(true, game_id, false)


## Join a lobby
func _attempt_join() -> void:
	print("Attempting to join a game")
	current_lobby_players = []
	our_name = $MainMenu/Waiting/VBoxContainer/Name/PlayerName.text
	#hosting = false
	
	## Begin hole-punching
	var game_code = $MainMenu/Waiting/VBoxContainer/Join/GameID.text
	if game_code == "":
		push_warning("Tried to join without entering a game code.")
		return
	nat_traversal(false, game_code)

func _ipv6_failed(game_id:String) -> void:
	nat_traversal(hosting, game_id, true)


func generate_game_code() -> String:
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var length = 4
	var result = ''
	for _char in length:
		var ascii = rng.randi_range(0, 25) + 65
		result += '%c' % ascii
	return result



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
	$MainMenu/Waiting/VBoxContainer/Join/GameID.editable = true
	$ModList.hide()
	$MainMenu/Menu.hide()
	$DeckBuilder.hide()
	$MainMenu/BattleSelect.hide()
	$MainMenu/Waiting.hide()
	$MainMenu/Lobby.hide()
	
	$Gameplay.hide()

func _on_deck_pressed() -> void:
	hide_all()
	$MainMenu.hide()
	$DeckBuilder/Deck.load_cards()
	$DeckBuilder.show()

func return_to_menu() -> void:
	hide_all()
	$MainMenu.show()
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
	$MainMenu/Waiting/debugdisplay/list/ipv4/status.text = "Waiting"
	$MainMenu/Waiting/debugdisplay/list/ipv6/status.text = "Waiting"

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

var ip_copy_text : String = ""
func _on_ip_copy_pressed() -> void:
	DisplayServer.clipboard_set(ip_copy_text)


func _on_m_pdebug_pressed() -> void:
	$MainMenu/Waiting/debugdisplay.visible = not $MainMenu/Waiting/debugdisplay.visible
