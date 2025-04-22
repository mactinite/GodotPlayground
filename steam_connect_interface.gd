extends Control

@export var parentMenus: Menus

@onready var lobbies_panel: Panel = $LobbiesPanel
@onready var lobbies_list: VBoxContainer = $LobbiesPanel/ScrollContainer/LobbiesList

var lobbiesListOpen: bool = false


func _ready():
	Lobby.lobby_match_list.connect(func(lobby_list):
		for lobby in lobby_list:
			var button = Button.new()
			var owner = Steam.getLobbyOwner(lobby)
			var name = Steam.getLobbyData(lobby, "name")

			button.text = str(name) + " : "+ str(owner)
			
			lobbies_list.add_child(button)
			button.connect("pressed", Callable(self, "join_lobby").bind(lobby))
	)
	Lobby.lobby_joined.connect(func(lobby: int, permissions: int, locked: bool, response: int):
		if Steam.getLobbyOwner(lobby) != Steamworks.steam_id:
			parentMenus.goto(Menus.MENU.LOBBY)
			NetworkManager.start_client_steam(Steam.getLobbyOwner(lobby))
	)

func _on_create_lobby_pressed():
	NetworkManager.start_host_steam()

	parentMenus.goto(Menus.MENU.LOBBY)
	
func join_lobby (lobby_data) -> void:
	_on_show_lobbies_pressed()
	Lobby.join_lobby(lobby_data)

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


func _on_back_pressed() -> void:
	parentMenus.goto(Menus.MENU.MAIN)
