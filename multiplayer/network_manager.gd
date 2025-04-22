extends Node

signal on_player_connected()
signal on_player_disconnected()
# Manage the state of the multiplayer client
var peer: MultiplayerPeer

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)

# Called on clients when they lose connection to the server
func server_disconnected() -> void:
	# cleanup
	pass
	
#called on server and clients
func _peer_connected(id):
	print("Player Connected " + str(id))
	pass

#called on server and clients
func _peer_disconnected(id):
	print("Player Disconnected " + str(id))
	GameManager._remove_player(id)
	pass
	
#called only on clients
func connected_to_server():
	print("Connected to server")
	send_player_info.rpc_id(1, Steamworks.steam_username, multiplayer.get_unique_id())
	pass
	
func connection_failed():
	print("Connection failed!")
	pass

#region ENetMultiplayerPeer
func start_host_enet(port: int) -> void:
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	send_player_info(Steamworks.steam_username, multiplayer.get_unique_id())
	print("Waiting for players")

func start_client_enet(address: String, port: int):
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_client(address,port)
	multiplayer.multiplayer_peer = peer
	print("Waiting for host")
#endregion

#region SteamMultiplayerPeer
func start_client_steam(steam_id: int):
	peer = SteamMultiplayerPeer.new()
	peer.create_client(steam_id, 0)
	multiplayer.multiplayer_peer = peer
	print("Waiting for host")
	pass
	
func start_host_steam():
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	send_player_info(Steamworks.steam_username, multiplayer.get_unique_id())
	Lobby.create_lobby()
	print("Waiting for players")
#endregion

@rpc("any_peer")
func send_player_info(username: String, id: int) -> void:
	if !GameState.players.has(id):
		GameState.players[id] = {
			"name": username,
			"id": id,
			"player_node": null
		}
		on_player_connected.emit()
		
	if multiplayer.is_server():
		for player_id in GameState.players:
			send_player_info.rpc_id(id, \
			GameState.players[player_id].name,\
		 	GameState.players[player_id].id)
		if GameState.game_started:
			send_game_start.rpc_id(id)
			GameManager.main.player_spawner.spawn_players()
			
@rpc("authority", "call_local")
func send_game_start()->void:
	GameManager.start_game()
	GameManager.main.menus.close()
