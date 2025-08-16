extends Node

const SERVER_PORT = 8080
const SERVER_IP ="127.0.0.1"

var player_scene = preload("res://levels/level_1/Player/player.tscn")
var _players_spawn_node
var connected_peers_ids = []

func become_host():
	print("starting host")
	
	_players_spawn_node = get_tree().get_current_scene().get_node("Players")
	
	var server_peer = ENetMultiplayerPeer.new()
	server_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = server_peer
	
	#host player
	_add_player_to_game(1)
	
	#other players
	multiplayer.peer_connected.connect(
		func(new_peer_id):
			await get_tree().create_timer(1).timeout
			rpc("add_newly_connected_player", new_peer_id) #_add_player_to_game
			rpc_id(new_peer_id, "add_previously_connected_players", connected_peers_ids )
			_add_player_to_game(new_peer_id)
	)
	multiplayer.peer_disconnected.connect(_del_player)
	
	
	
func join_as_player():
	print("player 2 joined")
	var client_peer = ENetMultiplayerPeer.new()
	client_peer.create_client(SERVER_IP, SERVER_PORT)
	multiplayer.multiplayer_peer = client_peer
	
	
func _add_player_to_game(id: int):
	print("player"+  str(id) + " joining the game")
	connected_peers_ids.append(id)
	var player_to_add = player_scene.instantiate()
	player_to_add.set_multiplayer_authority(id)
	player_to_add.player_id = id
	#player_to_add.name = str(id)
	
	#_players_spawn_node.add_child(player_to_add, true)
	$/root/Game/GameManager.add_player(player_to_add)


func _del_player(id: int):
		print("player "+str(id)+" left the game" )


func _on_message_input_text_submitted(_new_text):
		pass

##########remote
@rpc
func add_newly_connected_player(new_peer_id):
	_add_player_to_game(new_peer_id)

@rpc
func add_previously_connected_players(peer_ids):
	for peer_id in peer_ids:
		_add_player_to_game(peer_id)
	
