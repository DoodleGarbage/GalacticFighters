extends Node
class_name HolePuncher

## Debug Variables
var our_id : String = ""






#Signal is emitted when holepunch is complete. Connect this signal to your network manager
#Once your network manager received the signal they can host or join a game on the host port
signal hole_punched(my_port, hosts_port, hosts_address)

#This signal is emitted when the server has acknowledged your client registration, but before the
#address and port of the other client have arrived.
signal session_registered

#Signal is emitted if the ipv6 timeout triggers before successfully connecting to the signaling server over ipv6
signal ipv6_failed

var server_udp = PacketPeerUDP.new()
var peer_udp = PacketPeerUDP.new()

#Set the address to the IP address of your third party signaling server
@export var signaling_address = "" 
#Set the port of your third party signaling server
@export var signaling_port : int = 0
#Set the internal local port to connect to the signaling server with
@export var local_port : int = 4000
#This is the range of ports you will search if you hear no response from the first port tried
@export var port_cascade_range = 1000
#The amount of messages of the same type you will send before cascading or giving up
@export var response_window = 20

var is_ipv4 : bool = true


var found_server = false
var recieved_peer_info = false
var recieved_peer_greet = false
var recieved_peer_confirm = false
var recieved_peer_go = false

var is_host = false

var own_port
var peer = {}
var host_address = ""
var host_port = 0
var client_name
var p_timer
var session_id

var ports_tried = 0
var greets_sent = 0
var gos_sent = 0

var delay_timer : float = 0.0
var keep_alive_timer : float = 0.0
var ipv6_timer : float = 0.0
var ipv6_tries : int = 0

const REGISTER_SESSION = "rs:"
const REGISTER_CLIENT = "rc:"
const EXCHANGE_PEERS = "ep:"
const CHECKOUT_CLIENT = "cc:"
const PEER_GREET = "greet"
const PEER_CONFIRM = "confirm"
const PEER_GO = "go"
const SERVER_OK = "ok"
const SERVER_INFO = "peers"

const MAX_PLAYER_COUNT = 2

# Time in seconds between each attempt to connect to peer.
const PEER_CONNECTION_TIME : float = 0.3
# Time in seconds to keep-alive the hole-punch with server.
const KEEP_ALIVE_TIME : float = 15
# Time in seconds before ipv6 timesout and gives up and switches to ipv4
const IPV6_TIMEOUT : float = 20
const IPV6_REATTEMPT : float = 2

# warning-ignore:unused_argument
func _process(delta):
	delay_timer += delta
	keep_alive_timer += delta
	ipv6_timer += delta
	
	if server_udp.get_available_packet_count() <= 0 and not found_server and ipv6_timer > IPV6_TIMEOUT:
		server_udp.close()
		ipv6_failed.emit()
		set_process(false)
		return
	
	#if server_udp.get_available_packet_count() <= 0 and not found_server and ipv6_timer > (IPV6_REATTEMPT * ipv6_tries):
		#ipv6_tries += 1
		#print("Re-trying connection to signaling server over ", "ipv4" if is_ipv4 else "ipv6")
		#if is_host:
			#_send_host_to_server()
		#else:
			#_send_client_to_server()
	
	if server_udp.get_available_packet_count() <= 0 and not recieved_peer_info and found_server and keep_alive_timer > KEEP_ALIVE_TIME:
		print("Sending keep-alive packet.")
		keep_alive_timer = 0
		var buffer = PackedByteArray()
		buffer.append_array(("alive:"+client_name+":"+str(own_port)).to_utf8_buffer())
		server_udp.put_packet(buffer)
	
	if peer_udp.get_available_packet_count() > 0:
		var array_bytes = peer_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		print("Peer packet recieved: ", packet_string)
		if not recieved_peer_greet:
			if packet_string.begins_with(PEER_GREET):
				var m = packet_string.split(":")
				_handle_greet_message(m[1], int(m[2]), int(m[3]))
		if not recieved_peer_confirm:
			if packet_string.begins_with(PEER_CONFIRM):
				var m = packet_string.split(":")
				_handle_confirm_message(m[2], m[1], m[4], m[3])

		elif not recieved_peer_go:
			if packet_string.begins_with(PEER_GO):
				var m = packet_string.split(":")
				_handle_go_message(m[1])

	if server_udp.get_available_packet_count() > 0:
		var array_bytes = server_udp.get_packet()
		var packet_string = array_bytes.get_string_from_ascii()
		print("Server packet recieved: ", packet_string)
		if packet_string.begins_with(SERVER_OK):
			var m = packet_string.split(":")
			own_port = int( m[1] )
			session_registered.emit(is_ipv4)
			if is_host:
				if !found_server:
					_send_client_to_server(true)
			print("Found Server = true")
			found_server=true

		if not recieved_peer_info:
			if packet_string.begins_with(SERVER_INFO):
				server_udp.close()
				#packet_string = packet_string.right(6)
				
				if packet_string.length() > 2:
					var m = packet_string.split(":",true,2)
					var addr = m[2].rsplit(":",true,1)
					print("Registering with port: ", addr[1], " and address: ", addr[0])
					#peer[m[0]] = {"port":m[3], "address":m[2]}
					var peer_name = m[1]
					var peer_address = addr[0]
					var peer_port = addr[1]
					
					peer[peer_name] = {"port":peer_port, "address":peer_address}
					print(peer_name, " ", peer[peer_name])
					recieved_peer_info = true
					start_peer_contact()


func _handle_greet_message(peer_name, peer_port, my_port):
	#if own_port != my_port:
		#own_port = my_port
		#peer_udp.close()
		#var addr : String = "::"
		#if is_ipv4:
			#addr = "*"
		#peer_udp.bind(own_port, addr)
	recieved_peer_greet = true


func _handle_confirm_message(peer_name, peer_port, my_port, is_host):
	if peer[peer_name].port != peer_port:
		peer[peer_name].port = peer_port

	peer[peer_name].is_host = is_host
	if is_host:
		host_address = peer[peer_name].address
		host_port = peer[peer_name].port
	peer_udp.close()
	var addr : String = "::"
	if is_ipv4:
		addr = "*"
	peer_udp.bind(local_port, addr)
	recieved_peer_confirm = true


func _handle_go_message(peer_name):
	recieved_peer_go = true
	peer_udp.close()
	server_udp.close()
	hole_punched.emit(int(local_port), int(host_port),host_address)
	p_timer.stop()
	set_process(false)


func _cascade_peer(add, peer_port):
	for i in range(peer_port - port_cascade_range, peer_port + port_cascade_range):
		peer_udp.set_dest_address(add, i)
		var buffer = PackedByteArray()
		buffer.append_array(("greet:"+client_name+":"+str(own_port)+":"+str(i)).to_utf8_buffer())
		peer_udp.put_packet(buffer)
		ports_tried += 1


func _ping_peer():
	
	if not recieved_peer_confirm and greets_sent < response_window:
		print("Pinging peers.")
		for p in peer.keys():
			peer_udp.set_dest_address(peer[p].address, int(peer[p].port))
			print("Sending ping to address: ", peer[p].address, ":", int(peer[p].port))
			var buffer = PackedByteArray()
			buffer.append_array(("greet:"+client_name+":"+str(own_port)+":"+peer[p].port).to_utf8_buffer())
			peer_udp.put_packet(buffer)
			greets_sent+=1
			if greets_sent == response_window:
				print("Receiving no confirm. Starting port cascade")
				
				#if the other player hasn't responded we should try more ports

	if not recieved_peer_confirm and greets_sent == response_window:
		print("triggered port cascade")
		for p in peer.keys():
			_cascade_peer(peer[p].address, int(peer[p].port))
		greets_sent += 1

	if recieved_peer_greet and not recieved_peer_go:
		for p in peer.keys():
			peer_udp.set_dest_address(peer[p].address, int(peer[p].port))
			var buffer = PackedByteArray()
			buffer.append_array(("confirm:"+str(own_port)+":"+client_name+":"+str(is_host)+":"+peer[p].port).to_utf8_buffer())
			peer_udp.put_packet(buffer)

	if  recieved_peer_confirm:#and delay_timer > PEER_CONNECTION_TIME:
		#delay_timer = 0
		for p in peer.keys():
			peer_udp.set_dest_address(peer[p].address, int(peer[p].port))
			var buffer = PackedByteArray()
			buffer.append_array(("go:"+client_name).to_utf8_buffer())
			peer_udp.put_packet(buffer)
		gos_sent += 1

		if gos_sent >= response_window: #the other player has confirmed and is probably waiting
			peer_udp.close()
			server_udp.close()
			hole_punched.emit(int(own_port), int(host_port),host_address)
			p_timer.stop()
			set_process(false)


func start_peer_contact():
	print("Notifying signaling server we're contacting client.")
	server_udp.put_packet("goodbye".to_utf8_buffer())
	server_udp.close()
	if peer_udp.is_bound():
		peer_udp.close()
	print("Opening peer UDP")
	var err 
	if is_ipv4:
		err = peer_udp.bind(local_port, "*")
	else:
		err = peer_udp.bind(local_port, "::")
	if err != OK:
		print("Error listening on port: " + str(local_port) +" Error: " + str(err))
	p_timer.start()


#this function can be called to the server if you want to end the holepunch before the server closes the session
func finalize_peers(id):
	var buffer = PackedByteArray()
	buffer.append_array((EXCHANGE_PEERS+str(id)).to_utf8_buffer())
	server_udp.set_dest_address(signaling_address, signaling_port)
	server_udp.put_packet(buffer)


# remove a client from the server
func checkout():
	var buffer = PackedByteArray()
	buffer.append_array((CHECKOUT_CLIENT+client_name).to_utf8_buffer())
	server_udp.set_dest_address(signaling_address, signaling_port)
	server_udp.put_packet(buffer)


#Call this function when you want to start the holepunch process
func start_traversal(id, is_player_host, player_name, ipv4:bool=true):
	if server_udp.is_bound():
		print("Closing already bound server")
		server_udp.close()
	is_ipv4 = ipv4
	
	#own_port = local_port
	
	var err : Error
	if ipv4:
		err = server_udp.bind(local_port,"*")
	else:
		err = server_udp.bind(local_port,"::")
	if err != OK:
		print("Error listening on port: " + str(local_port) + " to server: " + signaling_address, " Error Code: ", err)
	is_host = is_player_host
	client_name = player_name
	found_server = false
	recieved_peer_info = false
	recieved_peer_greet = false
	recieved_peer_confirm = false
	recieved_peer_go = false
	peer = {}

	ports_tried = 0
	greets_sent = 0
	gos_sent = 0
	session_id = id
	
	delay_timer = 0
	ipv6_timer = 0
	keep_alive_timer = 0
	
	if (is_host):
		print("Sending game init message")
		_send_host_to_server()
	else:
		_send_client_to_server()


#Register a client with the server
func _send_client_to_server(wait:bool=false):
	print("Sending client to server")
	if wait:
		await get_tree().create_timer(2.0).timeout
	var buffer = PackedByteArray()
	buffer.append_array((REGISTER_CLIENT+client_name+":"+session_id).to_utf8_buffer())
	server_udp.close()
	server_udp.set_dest_address(signaling_address, signaling_port)
	server_udp.put_packet(buffer)

func _send_host_to_server():
	var buffer = PackedByteArray()
	buffer.append_array((REGISTER_SESSION+session_id+":"+str(MAX_PLAYER_COUNT)).to_utf8_buffer())
	server_udp.close()
	server_udp.set_dest_address(signaling_address, signaling_port)
	server_udp.put_packet(buffer)


func _exit_tree():
	server_udp.close()


func _ready():
	p_timer = Timer.new()
	get_node("/root/").call_deferred("add_child", p_timer)
	p_timer.timeout.connect(_ping_peer)
	p_timer.wait_time = 0.1
