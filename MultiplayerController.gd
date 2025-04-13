extends Control
@export var address = "127.0.0.1"
@export var port = 8910

@onready var start: Button = $VBoxContainer/Start

@onready var label: Label = $Label
@onready var members: Label = $Members
@onready var create_lobby: Button = $VBoxContainer/TabContainer/Steam/create_lobby
@onready var invite_friends: Button = $"VBoxContainer/TabContainer/Steam/LobbyView/Invite Friends"

@onready var lobby_view: HFlowContainer = $VBoxContainer/TabContainer/Steam/LobbyView
@onready var lobbies_list: VBoxContainer = $LobbiesPanel/ScrollContainer/LobbiesList
@onready var lobbies_panel: Panel = $LobbiesPanel

@onready var enet_host_button: Button = $VBoxContainer/TabContainer/LAN/Host
@onready var address_input: LineEdit = $VBoxContainer/TabContainer/LAN/ip
@onready var port_input: LineEdit = $VBoxContainer/TabContainer/LAN/port

var peer
var lobbiesListOpen = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(connected_to_server)
	multiplayer.connection_failed.connect(connection_failed)

	label.text = Steamworks.steam_username
	
	Lobby.lobby_created.connect(func(connect: int, lobby_id: int):
		lobby_view.show()
		pass
	)
	
	Lobby.lobby_invite.connect(func(inviter: int, lobby: int, game: int):
		pass
	)
	
	Lobby.lobby_joined.connect(func (lobby: int, permissions: int, locked: bool, response: int):
		if Steam.getLobbyOwner(lobby) != Steamworks.steam_id:
			connect_steam_socket(Steam.getLobbyOwner(lobby))
		pass
	)
	
	Lobby.lobby_match_list.connect(func(lobby_list):
		for lobby in lobby_list:
			var button = Button.new()
			var owner = Steam.getLobbyOwner(lobby)
			var name = Steam.getLobbyData(lobby, "name")

			button.text = str(name) + " : "+ str(owner)
			
			lobbies_list.add_child(button)
			button.connect("pressed", Callable(Lobby, "join_lobby").bind(lobby))
	)



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
#called on server and clients
func _peer_connected(id):
	print("Player Connected " + str(id))
	pass

#called on server and clients
func _peer_disconnected(id):
	print("Player Disconnected " + str(id))
	pass
	
#called only on clients
func connected_to_server():
	print("Connected to server")
	send_player_info.rpc_id(1, Steamworks.steam_username, multiplayer.get_unique_id())
	pass
	
func connection_failed():
	print("Connection failed!")
	pass

# --- RPCs

@rpc("any_peer", "call_local")
func start_game():
	var scene = load("res://World.tscn").instantiate()
	get_tree().root.add_child(scene)
	self.hide()


@rpc("any_peer")
func send_player_info(username: String, id: int):
	if !GameManager.players.has(id):
		GameManager.players[id] = {
			"name": username,
			"id": id,
			"score": 0
		}
	list_members()
	if multiplayer.is_server():
		for i in GameManager.players:
			send_player_info.rpc(GameManager.players[i].name, i)

func list_members():
	members.text = ""
	for id in GameManager.players:
		members.text = members.text + GameManager.players[id].name + "\n"
		

func connect_steam_socket(steam_id: int):
	create_lobby.hide()
	peer = SteamMultiplayerPeer.new()
	peer.create_client(steam_id, 0)
	multiplayer.multiplayer_peer = peer
	print("Waiting for host")
	pass
	
func create_steam_socket():
	create_lobby.hide()
	start.disabled = false
	peer = SteamMultiplayerPeer.new()
	peer.create_host(0)
	multiplayer.multiplayer_peer = peer
	send_player_info(Steamworks.steam_username, multiplayer.get_unique_id())
	Lobby.create_lobby()
	print("Waiting for players")
	
func host_enet():
	enet_host_button.hide()
	$VBoxContainer/TabContainer/LAN/ip.editable = false
	$VBoxContainer/TabContainer/LAN/port.editable = false
	$VBoxContainer/TabContainer/LAN/connect.hide()
	start.disabled = false
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port_input.text.to_int())
	multiplayer.multiplayer_peer = peer
	send_player_info(Steamworks.steam_username, multiplayer.get_unique_id())
	print("Waiting for players")
	
func join_enet():
	enet_host_button.hide()
	peer = ENetMultiplayerPeer.new()
	address = address_input.text
	port = port_input.text.to_int()
	peer.create_client(address,port)
	multiplayer.multiplayer_peer = peer
	print("Waiting for host")
	
func _on_start_button_down():
	start_game.rpc()
	pass
	
func _on_friends_button_pressed():
	Steam.activateGameOverlayInviteDialog(Steamworks.steam_id)
pass

func _on_show_lobbies_pressed():
	if !lobbiesListOpen:
		for n in lobbies_list.get_children():
			lobbies_list.remove_child(n)
			n.queue_free()
			
		Lobby._on_open_lobby_list_pressed()
		lobbies_panel.show()
		lobbiesListOpen = true
	else:
		lobbies_panel.hide()
		lobbiesListOpen = false
	pass
