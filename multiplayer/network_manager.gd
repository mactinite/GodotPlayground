extends Node

signal on_player_connected()
signal on_player_disconnected()
signal on_server_disconnected()
# Manage the state of the multiplayer client
var peer: MultiplayerPeer

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connection_failed.connect(connection_failed)
	multiplayer.server_disconnected.connect(server_disconnected)

# Called on clients when they lose connection to the server
func server_disconnected() -> void:
	# cleanup
	Inventory.player_inventory = InventoryData.new()
	Inventory.on_player_inventory_update.emit(Inventory.player_inventory)
	on_server_disconnected.emit()
	pass
	
#called on server and clients
func _peer_connected(id):
	print("Player Connected " + str(id) + ":" + "HOST" if multiplayer.is_server() else "CLIENT")
	pass

#called on server and clients
func _peer_disconnected(id):
	print("Player Disconnected " + str(id))
	GameManager._remove_player(id)
	pass
		
func connection_failed():
	print("Connection failed!")
	pass

#region ENetMultiplayerPeer
func start_host_enet(port: int) -> void:
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_server(port)
	multiplayer.multiplayer_peer = peer
	GameState.players[1] = {
		"name": GameManager.lan_user_name,
		"id": 1,
		"user_id": GameManager.lan_user_name.hash(),
		"player_node": null
	}
	
	Inventory.set_player_inventory(1, GameManager.lan_user_name.hash())
	print("Waiting for players")

func start_client_enet(address: String, port: int):
	peer = ENetMultiplayerPeer.new()
	var status = peer.create_client(address,port)
	multiplayer.multiplayer_peer = peer
	print("Waiting for host")
	
	multiplayer.connected_to_server.connect(func():
		print("Connected to server: ENET")
		send_player_info.rpc_id(1, GameManager.lan_user_name, GameManager.lan_user_name.hash())
	)
	
	
#endregion

#region SteamMultiplayerPeer
func start_client_steam(steam_id: int):
	peer = SteamMultiplayerPeer.new()
	peer.create_client(steam_id, 0)
	multiplayer.multiplayer_peer = peer
	print("Waiting for host")
	
	multiplayer.connected_to_server.connect(func():
		print("Connected to server: STEAM")
	
		send_player_info.rpc_id(1, Steamworks.steam_username, Steamworks.steam_id)
	)
	pass
	
func start_host_steam():
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	GameState.players[1] = {
		"name": Steamworks.steam_username,
		"id": 1,
		"user_id": Steamworks.steam_id,
		"player_node": null
	}
	Inventory.set_player_inventory(1, Steamworks.steam_id)
	Lobby.create_lobby()
	print("Waiting for players")
#endregion

@rpc("any_peer")
func send_player_info(username: String, user_id: int) -> void:
	var id:int = multiplayer.get_remote_sender_id()

	if !GameState.players.has(id):
		GameState.players[id] = {
			"name": username,
			"id": id,
			"user_id": user_id,
			"player_node": null
		}
		on_player_connected.emit()
		
	if multiplayer.is_server():
		#create server side inventory
		Inventory.set_player_inventory(id, user_id)
		
		for player_id in GameState.players:
			#broadcast players to everyone
			send_player_info.rpc(GameState.players[player_id].name,	GameState.players[player_id].id)
		if GameState.game_started:
			send_game_start.rpc_id(id)
			GameManager.main.player_spawner.spawn_players()
			
@rpc("authority", "call_local")
func send_game_start()->void:
	GameManager.start_game()
	GameManager.main.menus.close()
