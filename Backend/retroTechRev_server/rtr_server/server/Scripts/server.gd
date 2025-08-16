extends Node

#create server
var peer = ENetMultiplayerPeer.new()

func _ready():
	# --- Creating a server ---
	var port = 7777 # Choose a port
	var max_clients = 32 # Maximum number of clients

	var err = peer.create_server(port, max_clients)
	if err != OK:
		printerr("Failed to create server: ", err)
		return
	multiplayer.multiplayer_peer = peer
	print("Server started on port ", port)
	
	if multiplayer.is_server():
		print_once_per_client.rpc()

@rpc
func print_once_per_client():
	print("I will be printed to the console once per each connected client.")

func _on_peer_connected(id):
	print("Peer connected: ", id)

func _on_peer_disconnected(id):
	print("Peer disconnected: ", id)

# --- Disconnecting ---
func _exit_tree():
	print("shutting down")
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_DISCONNECTED:
		peer.close()
	multiplayer.multiplayer_peer = null # Very important to clear the peer!
