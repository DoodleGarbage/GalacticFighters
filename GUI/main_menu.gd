extends Node

# low key just copying my previous multiplayer networking setup :pray:
## MULTIPLAYER & NETWORKING

var our_name : String = "PLAYERNAME"
var opponent_names : Array[String] = [""]

var our_ready : bool = false
var opponent_readies : Array[bool] = [false]

func _ready() -> void:
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)


## Host a lobby
func _attempt_host() -> void:
	player_name = $GUI/Join/Lobby/SetName.text
	var peer = ENetMultiplayerPeer.new()
	var port : int = int($GUI/Join/Lobby/Port.text)
	if port < 1024 or port > 65535: # Checks the validity of the port. Below 1024 is privleged (not doable) stuff
		port = 7777
	peer.create_server(port,1)
	multiplayer.multiplayer_peer = peer
	$GUI/Join/Lobby.hide()
	$GUI/Join/Game.show()
	$GUI/Join/Game.made_lobby(player_name)
	## TODO: Use upnp to auto-port forward
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	$GUI/Data/IP.text = "IP: " + str(upnp.query_external_address()) + ":" + str(port)

## Join a lobby
func _attempt_join() -> void:
	our_name = $Waiting/VBoxContainer/Name/PlayerName.text
	var IP_address : String = $Waiting/VBoxContainer/Join/JoinInput.text
	if IP_address == "":
		IP_address = "127.0.0.1:4444"
	var peer = ENetMultiplayerPeer.new()
	var seperate := IP_address.split(":")
	if seperate.size() != 2:
		push_error("Tried to join a game, but the IP address was formatted incorrectly!")
		return
	var ip : String = seperate[0]
	var port : int = int(seperate[1])
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer

## MODIFY 'WAITING' NODE TO DISPLAY A LOBBY W/OTHER PLAYERS DECK SHOWN (+Ready status) & READY-UP BUTTON
func join_connected(_id:int=0) -> void:
	$Waiting/VBoxContainer/Join.hide()
	$Waiting/VBoxContainer/Host.hide()
	## Going to Server
	lobby_joined.rpc(player_name)

## Called from Server to Client from gui_manager.gd to sync the lobbies
func join_lob(joiner:String) -> void:
	## Going to Server from Client
	join_lobby.rpc(joiner, player_name)

@rpc("any_peer", "call_remote", "reliable", 0)
func join_lobby(player_name:String, host_player_name : String) -> void:
	reset_lobby()
	$Player1/PlayerData.text = host_player_name
	$Player2/PlayerData.text = player_name
	$Player2/Select.show()
	$Player2/WeaponSelection.show()
	$Player2/Confirm.show()

## Called from Client to Server
@rpc("any_peer", "call_remote", "reliable", 0)
func lobby_joined(player_joined:String) -> void:
	## Going from Server to Client
	join_lob(player_joined)
	#join_lobby(player_joined, get_parent().player_name)
	$Player2/PlayerData.text = player_joined

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

## Un-ready ourselves when a client joins our lobby.
func peer_connected(_id:int=0) -> void:
	our_ready = false
	#TODO: UPDATE VISUALS


func _disconnect() -> void:
	# Temp; should update lobby visuals (if host) other wise return to menu if peer/connecting
	return_to_menu()

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
