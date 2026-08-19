from twisted.internet.protocol import DatagramProtocol
from twisted.internet import reactor
from multiprocessing import Process, shared_memory
import pickle
import time


import sys



def address_to_string(address):
	ip, port = address
	return ':'.join([ip, str(port)])


class ClientTimeout():

	def __init__(self, shmname):
		print("running")
		#self.lock = locker
		self.shm = shared_memory.SharedMemory(shmname)
		#self.buffer = self.shm.buf
		#print("subprocess client list: ", self.get_rc())
		self.p = Process(target=self.rn, args=[self.shm])
		print("bah")
		self.p.start()

	def rn(self, sh):
		print("Beginning time-out script")
		self.shm = sh
		self.buffer = self.shm.buf
		while True:
			try:
				#print("Waking up to check for dead connections")
				time.sleep(1)
				tmp_rc = self.get_rc()
				mod_rc = tmp_rc.copy()
				#with lock:
				# print("running locked, registered clients: ", tmp_rc)
				for client in tmp_rc.keys():
					print("Client time: ", tmp_rc[client].last_update, " our time: ", time.time())
					if time.time() - tmp_rc[client].last_update >= 60:
						try:
							del mod_rc[client]
						except KeyError:
							print("Tried to checkout unregistered client")
				self.set_rc(mod_rc)
			except KeyboardInterrupt:
				print("Exiting")
				self.stop()

	def set_rc(self, val):
		pckl = pickle.dumps(val)
		l = len(pckl)
		self.buffer[0] = l
		self.buffer[1:(l+1)] = pckl

	def get_rc(self):
		l = self.shm.buf[0]
		return pickle.loads(bytes(self.buffer[1:(l+1)]))

class ServerProtocol(DatagramProtocol):

	def __init__(self):
		self.shm = shared_memory.SharedMemory(create=True, size=10000)
		self.buffer = self.shm.buf
		self.active_sessions = {}
		self.set_registered_clients({})
		#self.registered_clients = {}
		#self.shm.buf = pickle.dumps(self.registered_clients)
		#self.lock = Lock()
		self.p = ClientTimeout(self.shm.name)
		#self.p = Process(target=self.rn, args=(self.lock, self.registered_clients))
		#self.p.start()
		#self.p.join()

	def name_is_registered(self, name):
		return name in self.get_registered_clients()

	def create_session(self, s_id, client_list):
		if s_id in self.active_sessions:
			print("Tried to create existing session")
			return

		self.active_sessions[s_id] = Session(s_id, client_list, self)

	def set_registered_clients(self, val):
		pckl = pickle.dumps(val)
		l = len(pckl)
		self.buffer[0] = l
		self.buffer[1:(l+1)] = pckl

	def get_registered_clients(self):
		l = self.buffer[0]
		return pickle.loads(bytes(self.buffer[1:(l+1)]))

	def remove_session(self, s_id):
		try:
			del self.active_sessions[s_id]
		except KeyError:
			print("Tried to terminate non-existing session")


	def register_client(self, c_name, c_session, c_ip, c_port):
		if self.name_is_registered(c_name):
			print("Client %s is already registered." % [c_name])
			return
		if not c_session in self.active_sessions:
			print("Client registered for non-existing session")
		else:
			print("Registered client")
			new_client = Client(c_name, c_session, c_ip, c_port)
			tmp_dct = self.get_registered_clients()
			tmp_dct[c_name] = new_client
			self.set_registered_clients(tmp_dct)
			self.active_sessions[c_session].client_registered(new_client)


	def exchange_info(self, c_session):
		if not c_session in self.active_sessions:
			return
		self.active_sessions[c_session].exchange_peer_info()

	def client_checkout(self, name):
		tmp_dct = self.get_registered_clients()
		try:
			del tmp_dct[name]
		except KeyError:
			print("Tried to checkout unregistered client")
		set_registered_clients(tmp_dct)

	def datagramReceived(self, datagram, address):
		"""Handle incoming datagram messages."""
		print(datagram)
		print("Recieved address is: ", address)
		data_string = datagram.decode("utf-8")
		msg_type = data_string[:2]
		print("Message type: ", msg_type)

		if msg_type == "rs":
			# register session
			c_ip, c_port = address
			self.transport.write(bytes('ok:'+str(c_port),"utf-8"), address)
			split = data_string.split(":")
			session = split[1]
			max_clients = split[2]
			self.create_session(session, max_clients)

		elif msg_type == "rc":
			# register client
			print("Registering client, data is: ", data_string)
			split = data_string.split(":")
			c_name = split[1]
			c_session = split[2]
			c_ip, c_port = address
			print("Sent message " + 'ok:'+str(c_port) + " to address: " + str(c_ip) + ":" + str(c_port))
			self.transport.write(bytes('ok:'+str(c_port),"utf-8"), address)
			self.register_client(c_name, c_session, c_ip, c_port)

		elif msg_type == "ep":
			# exchange peers
			split = data_string.split(":")
			c_session = split[1]
			self.exchange_info(c_session)

		elif msg_type == "cc":
			# checkout client
			split = data_string.split(":")
			c_name = split[1]
			self.client_checkout(c_name)
		elif msg_type == "al":
			# Keep hole-punch alive
			split = data_string.split(":")
			c_ip, c_port = address
			print("Recieved keep-alive message from client: ", c_ip, ":", c_port)
			self.transport.write(bytes('recieved:'+str(c_port),"utf-8"), address)
			tmp_dct = self.get_registered_clients()
			tmp_dct[split[1]].last_update = time.time()
			self.set_registered_clients(tmp_dct)



class Session:

	def __init__(self, session_id, max_clients, server):
		self.id = session_id
		self.client_max = max_clients
		self.server = server
		self.registered_clients = []


	def client_registered(self, client):
		if client in self.registered_clients: return
		# print("Client %c registered for Session %s" % client.name, self.id)
		self.registered_clients.append(client)
		if len(self.registered_clients) == int(self.client_max):
			sleep(5)
			print("waited for OK message to send, sending out info to peers")
			self.exchange_peer_info()

	def exchange_peer_info(self):
		for addressed_client in self.registered_clients:
			address_list = []
			for client in self.registered_clients:
				if not client.name == addressed_client.name:
					address_list.append(client.name + ":" + address_to_string((client.ip, client.port)))
			for i in range(2):
				address_string = ",".join(address_list)
				print("We sent message: " + "peers:" + address_string)
				message = bytes( "peers:" + address_string, "utf-8")
				self.server.transport.write(message, (addressed_client.ip, addressed_client.port))

		print("Peer info has been sent. Terminating Session")
		for client in self.registered_clients:
			self.server.client_checkout(client.name)
		self.server.remove_session(self.id)


class Client:

	def confirmation_received(self):
		self.received_peer_info = True

	def __init__(self, c_name, c_session, c_ip, c_port):
		self.name = c_name
		self.session_id = c_session
		self.ip = c_ip
		self.port = c_port
		self.received_peer_info = False
		self.last_update = time.time()





if __name__ == '__main__':
	if len(sys.argv) < 3:
		print("Usage: ./server.py ADDR PORT")
		sys.exit(1)

	port = int(sys.argv[2])
	addr = sys.argv[1]

	reactor.listenUDP(port, ServerProtocol(), addr)
	print('Listening on %s:%d' % (addr, port))
	reactor.run()
