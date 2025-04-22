extends Control
@export var parent_menus: Menus

@onready var line_edit_ip: LineEdit = $MarginContainer/VBoxContainer/LineEdit_IP
@onready var line_edit_port: LineEdit = $MarginContainer/VBoxContainer/LineEdit_Port
@onready var btn_host: Button = $MarginContainer/VBoxContainer/Btn_Host
@onready var btn_connect: Button = $MarginContainer/VBoxContainer/Btn_Connect
@onready var btn_back: Button = $MarginContainer/VBoxContainer/Btn_Back

func _ready() -> void:
	btn_host.pressed.connect(start_host)
	btn_connect.pressed.connect(start_client)
	btn_back.pressed.connect(go_back)
	
	multiplayer.connection_failed.connect(func ():
		enable_menu()
	)
	
	multiplayer.connected_to_server.connect(func ():
		enable_menu()
		parent_menus.goto(Menus.MENU.LOBBY)
	)

func enable_menu() -> void:
	line_edit_ip.editable = true
	line_edit_port.editable = true
	btn_host.disabled = false
	btn_back.disabled = false
	btn_connect.disabled = false
	
func disable_menu() -> void: 
	line_edit_ip.editable = false
	line_edit_port.editable = false
	btn_host.disabled = true
	btn_back.disabled = true
	btn_connect.disabled = true

func start_client() -> void:
	var port: int = line_edit_port.text.to_int()
	var ip: String = line_edit_ip.text
	disable_menu()
	NetworkManager.start_client_enet(ip, port)
	pass
	
func start_host() -> void:
	var port: int = line_edit_port.text.to_int()
	var ip: String = line_edit_ip.text
	NetworkManager.start_host_enet(port)
	parent_menus.goto(Menus.MENU.LOBBY)
	pass
	
func go_back() -> void:
	parent_menus.goto(Menus.MENU.MAIN)
