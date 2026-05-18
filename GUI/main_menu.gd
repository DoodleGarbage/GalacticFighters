extends Node

# low key just copying my previous multiplayer networking setup :pray:
## MULTIPLAYER & NETWORKING

var our_name : String = "PLAYERNAME"
## [name, ID, is host? (bool)]
var current_lobby_players : Array = []


var opponent_names : Array[String] = [""]

var our_ready : bool = false
var opponent_readies : Array[bool] = [false]

func _ready() -> void:
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)

var peer : ENetMultiplayerPeer
## Host a lobby
func _attempt_host() -> void:
	current_lobby_players = []
	our_name = $Waiting/VBoxContainer/Name/PlayerName.text
	peer = ENetMultiplayerPeer.new()
	var port : int = int($Waiting/VBoxContainer/Host/HostIP.text)
	if port < 1024 or port > 65535: # Checks the validity of the port. Below 1024 is privleged (not doable) stuff
		port = 7777
	peer.create_server(port,1)
	multiplayer.multiplayer_peer = peer
	
	current_lobby_players.append([our_name, peer.get_unique_id(), false])
	
	hide_all()
	$Lobby.show()
	load_lobby_gui()
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	$Lobby/IPS/IP.text = str(upnp.query_external_address()) + ":" + str(port)

## Join a lobby
func _attempt_join() -> void:
	joining_lobby = true
	our_name = $Waiting/VBoxContainer/Name/PlayerName.text
	var IP_address : String = $Waiting/VBoxContainer/Join/JoinInput.text
	if IP_address == "":
		IP_address = "127.0.0.1:7777"
	peer = ENetMultiplayerPeer.new()
	var seperate := IP_address.split(":")
	if seperate.size() != 2:
		push_error("Tried to join a game, but the IP address was formatted incorrectly!")
		return
	var ip : String = seperate[0]
	var port : int = int(seperate[1])
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	print("Should be joining...")

func load_lobby_gui() -> void:
	$Lobby.show()
	var title : Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "Players (" + str(current_lobby_players.size()) + "/2)"
	$Lobby/PlayerList.add_child(title)
	for player in current_lobby_players:
		var new_label : Label = Label.new()
		new_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var txt : String = player[0] if player[2] else player[0] + " (Host)"
		new_label.text = txt
		$Lobby/PlayerList.add_child(new_label)
	pass


## MODIFY TO DISPLAY A LOBBY W/OTHER PLAYERS DECK SHOWN (+Ready status) & READY-UP BUTTON
# Called when we join a server
func join_connected(_id:int=0) -> void:
	$Waiting.hide()
	$Lobby.show()
	## Going to Server
	lobby_joined.rpc(our_name, peer.get_unique_id(), true)

# Sent from Server to update everyone when someone joins the lobby
@rpc("authority", "call_remote", "reliable", 0)
func join_lobby(lobby:Array) -> void:
	print("Join was recieved!")
	current_lobby_players = lobby
	reset_lobby()

## Called from Client to Server
@rpc("any_peer", "call_remote", "reliable", 0)
func lobby_joined(player_name:String, p_ID:int, isplayer:bool) -> void:
	print("Player wants to join")
	current_lobby_players.append([player_name, p_ID, isplayer])
	## Going from Server to Client
	join_lobby.rpc(current_lobby_players)

#func ready_up() -> void:
	#is_ready.rpc()
	#if multiplayer.is_server():
		#$GUI/Join/Game.is_ready(1)
		#player_1_ready = true
	#else:
		#$GUI/Join/Game.is_ready(2)
		#player_2_ready = true
	#if player_1_ready and player_2_ready and multiplayer.is_server():
		#start_game.rpc()
#
### This calls on the other client, so we always know it was the other person that readied when this code runs.
#@rpc("any_peer", "call_remote", "reliable", 0)
#func is_ready() -> void:
	#if multiplayer.is_server():
		#$GUI/Join/Game.is_ready(2)
		#player_2_ready = true
	#else:
		#$GUI/Join/Game.is_ready(1)
		#player_1_ready = true
	#if player_1_ready and player_2_ready and multiplayer.is_server():
		#start_game.rpc()

# Host calls this (which also calls it on itself) which will cause everyone to load the playfield
#@rpc("authority", "call_local", "reliable", 0)
#func start_game() -> void:
	#$GUI/Join.hide()
	## Initialize Characters

## ADD SYNC CODE / COMMUNICATE GAMEPLAY

## Called when anyone joins the lobby
func peer_connected(_id:int=0) -> void:
	#our_ready = false
	pass
	#TODO: UPDATE VISUALS

var joining_lobby : bool = false
func _disconnect() -> void:
	# Temp; should update lobby visuals (if host) other wise return to menu if peer/connecting
	if joining_lobby:
		return_to_menu()
	else:
		reset_lobby()

## Clears and resets the lobby
func reset_lobby() -> void:
	for child in $Lobby/PlayerList.get_children():
		child.queue_free()
	load_lobby_gui()

## ^ MULTIPLAYER & NETWORKING

func _start_pressed() -> void:
	$Menu/VBoxContainer/Start.hide()
	#$VBoxContainer/MenuSpacer.hide()
	$Menu/VBoxContainer/AccessedMenu.show()

func hide_all() -> void:
	$Menu.hide()
	$Deck.hide()
	$BattleSelect.hide()
	$Playfield.hide()
	$Waiting.hide()
	$Lobby.hide()

func _on_deck_pressed() -> void:
	hide_all()
	$Deck.show()

func return_to_menu() -> void:
	hide_all()
	$Menu.show()

func prepare_battle() -> void:
	hide_all()
	$BattleSelect.show()

var prepared_deck : Deck
func ready_for_battle(deck:Deck) -> void:
	hide_all()
	# Show "Waiting on other player. Your Deck: DECK"
	# Multiplayer stuff
	prepared_deck = deck
	#local_peer_send "I am ready" message
	$Waiting/VBoxContainer/MiniDeck.load_deck(deck)
	$Waiting.show()
