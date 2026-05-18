extends Node

# low key just copying my previous multiplayer networking setup :pray:
## MULTIPLAYER & NETWORKING

var our_name : String = "PLAYERNAME"
## [name, ID, is host? (bool), deck]
var current_lobby_players : Array = []


var opponent_names : Array[String] = [""]

var our_ready : bool = false
var opponent_readies : Array[bool] = [false]

func _ready() -> void:
	## Networking
	multiplayer.connected_to_server.connect(join_connected)
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.server_disconnected.connect(_disconnect)
	multiplayer.peer_disconnected.connect(_disconnect)
	
	## Resource Management
	# Load Order: Images, Pscripts, Attributes, SpecialChars
	for internal in [true,false]:
		load_images(internal)
		load_resource("Pscript", internal)
		load_resource("Attribute", internal)
		load_resource("SpecialCharacter", internal)

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
	
	current_lobby_players.append([our_name, peer.get_unique_id(), false, prepared_deck.to_text()])
	
	hide_all()
	$Lobby.show()
	load_lobby_gui()
	var upnp = UPNP.new()
	upnp.discover()
	upnp.add_port_mapping(port)
	$Lobby/IPS/IP.text = str(upnp.query_external_address()) + ":" + str(port)

## TODO: Make this happen asynchronously so the whole game doesn't freeze

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

const plgui := preload("res://GUI/playerlobby_deck.tscn")
func load_lobby_gui() -> void:
	$Lobby.show()
	var title : Label = Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.text = "Players (" + str(current_lobby_players.size()) + "/2)"
	$Lobby/PlayerList.add_child(title)
	for player in current_lobby_players:
		var new_play := plgui.instantiate()
		var txt : String = player[0] if player[2] else player[0] + " (Host)"
		new_play.player = txt
		var their_deck = string_to_deck(player[3])
		new_play.load_deck(their_deck)
		$Lobby/PlayerList.add_child(new_play)
	pass


## MODIFY TO DISPLAY A LOBBY W/OTHER PLAYERS DECK SHOWN (+Ready status) & READY-UP BUTTON
# Called when we join a server
func join_connected(_id:int=0) -> void:
	$Waiting.hide()
	$Lobby.show()
	## Going to Server
	lobby_joined.rpc(our_name, peer.get_unique_id(), true, prepared_deck.to_text())

# Sent from Server to update everyone when someone joins the lobby
@rpc("authority", "call_remote", "reliable", 0)
func join_lobby(lobby:Array) -> void:
	print("Join was recieved!")
	current_lobby_players = lobby
	reset_lobby()

## Called from Client to Server
@rpc("any_peer", "call_remote", "reliable", 0)
func lobby_joined(player_name:String, p_ID:int, isplayer:bool, deck:Array[String]) -> void:
	print("Player wants to join")
	current_lobby_players.append([player_name, p_ID, isplayer, deck])
	reset_lobby()
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
func _disconnect(_whoid:int=0) -> void:
	if joining_lobby:
		return_to_menu()
		return
	# Temp; should update lobby visuals (if host) other wise return to menu if peer/connecting
	for pla in current_lobby_players.size():
		if current_lobby_players[pla][1] == _whoid:
			current_lobby_players.remove_at(pla)
			break
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

func string_to_deck(deck:Array[String]) -> Deck:
	var zombie : Deck = Deck.new()
	for card in deck:
		var split := card.split(":", 1)
		match(split[0]):
			"SpecialCharacter":
				var chara = find_resource(split[0], split[1])
				if chara != null:
					zombie.special_characters.append(chara)
	return zombie


## RESOURCE MANAGEMENT

#func _ready() -> void:
	#pass

## Loaded Resources

var attributes : Array[Attribute] = []
var pscripts : Array = []
var specialcharacters : Array[Card] = []
var images : Array[Texture] = []

func load_images(internal:bool = true) -> void:
	var dir_path : String = "res://Data/Image/" if internal else "user://Image/"
	var dir = DirAccess.open(dir_path)
	if !dir:
		push_error("No folders was found for Images!")
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	while current_file != "":
		if dir.current_is_dir():
			pass
		elif current_file.ends_with(".png") or current_file.ends_with(".jpg") or current_file.ends_with(".jpeg"):
			if internal: ## We need special loading handling if we're loading in res://, as load_from_file will not work on export.
				var new_text : Texture = load(dir_path + current_file)
				new_text.resource_name = current_file.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
				images.append(new_text)
				current_file = dir.get_next()
				continue
			var new_image : Image = Image.load_from_file(dir_path + current_file)
			if new_image == null:
				push_error("Found image, but couldn't load it as an image!")
				current_file = dir.get_next()
				continue
			var as_texture = ImageTexture.create_from_image(new_image)
			as_texture.resource_name = current_file.trim_suffix(".png").trim_suffix(".jpg").trim_suffix(".jpeg")
			images.append(as_texture)
		current_file= dir.get_next()
	return


func load_resource(resource_name:String, internal:bool=true) -> void:
	var tar_dir : String = "res://Data/" if internal else "user://"
	var dir = DirAccess.open(tar_dir + resource_name)
	if !dir:
		push_error("No folder was found for %s!" % resource_name)
		return
	dir.list_dir_begin()
	var current_file : String = dir.get_next()
	## current_file will equal "" if there are no files to be processed left.
	while current_file != "":
		if dir.current_is_dir():
			pass
			#print("Directory \"%s\" found inside %s folder." % [current_file, resource_name])
		else:
			if current_file.ends_with(".json"):
				load_resource_from_file(current_file, resource_name)
		current_file = dir.get_next()

func load_resource_from_file(file:String, resource_name:String) -> void:
	var JSONData = JSON.new()
	var File := FileAccess.open("res://Data/" + resource_name + "/" + file, FileAccess.READ)
	## This should never happen.
	if not (FileAccess.file_exists("res://Data/" + resource_name + "/" + file)):
		push_error("File \"%s\" was not found!" % ["res://Data/" + resource_name + "/" + file])
		return
	var fileJSON : String = File.get_as_text()
	var error = JSONData.parse(fileJSON)
	if error:
		push_error("JSON Parsing Error in file %s: " % file, JSONData.get_error_message(), " at line ", JSONData.get_error_line(), "\nWhile loading resource %s." % resource_name)
		return
	var data = JSONData.data
	if typeof(data) == TYPE_ARRAY:
		for resource in data:
			match(resource_name):
				"Attribute": ## Must be loaded: Images, Pscripts
					var new_attr : Attribute = Attribute.new()
					new_attr.name = resource["Name"]
					new_attr.icon = find_image(resource["Icon"])
					#new_attr.pscript = find_resource("Pscript", resource["Pscript"])
					new_attr.type = resource["Type"]
					new_attr.desc = resource["Desc"]
					attributes.append(new_attr)
				"Pscript":
					## Power scripts must be uniquely loaded due to their nature as scripts
					pass
				"SpecialCharacter": ## Must be loaded: Attributes, Images
					var new_char : Card = Card.new()
					new_char.name = resource["Name"]
					new_char.full_profile = find_image(resource["FullProfile"])
					new_char.mini_profile = find_image(resource["MiniProfile"])
					new_char.max_health = resource["Health"]
					new_char.defense = resource["Defense"]
					new_char.attack = resource["Attack"]
					new_char.burst = resource["Burst"]
					new_char.heal = resource["Heal"]
					new_char.armor_pierce = resource["ArmorPierce"]
					for atrru in resource["Attributes"]:
						var atri = find_resource("Attribute", atrru)
						if atri != null:
							new_char.attributes.append(atri)
					specialcharacters.append(new_char)


func find_resource(resource_type:String, resource_name:String) -> Variant:
	var search_array : Array = []
	match(resource_type):
		"Attribute": search_array = attributes
		"SpecialCharacter": search_array = specialcharacters
		"String":
			return resource_name
		"Images": ## Just an extra way to search for images (redundancy!)
			return find_image(resource_name)
		_: push_error("Resource array for resource type %s does not exist!" % resource_type); return
	for resource in search_array:
		if resource.name == resource_name:
			return resource
	push_error("Could not find resource of type %s for name \"%s\"!" % [resource_type, resource_name])
	return null

func find_image(imagename:String) -> Texture:
	for image : Texture in images:
		if image.resource_name == imagename:
			return image
	return null
