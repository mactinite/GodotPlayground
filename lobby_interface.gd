extends Control

@export var parent_menus: Menus
@onready var lobby_members: VBoxContainer = $Lobby_Members
@onready var start: Button = $Start


func _ready() -> void:
	NetworkManager.on_player_connected.connect(list_players)
	NetworkManager.on_player_disconnected.connect(list_players)
	list_players()
	

func list_players() -> void:
	for child in lobby_members.get_children():
		child.queue_free()
	for id in GameState.players:
		var label = Label.new()
		label.text = GameState.players[id].name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lobby_members.add_child(label)

func _on_visibility_changed() -> void:
	list_players()
	if multiplayer.is_server():
		start.disabled = false
	pass # Replace with function body.


func _on_start_pressed() -> void:
	send_game_start.rpc()

@rpc("authority", "call_local")
func send_game_start()->void:
	GameManager.start_game()
	parent_menus.close()
