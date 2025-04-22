extends Node

var steam_id: int = 0
var steam_username: String = ""

func _ready() -> void:
	initialize_steam()


func initialize_steam() -> void:
	var initialize_response: bool = Steam.steamInit(480)
	print("Did Steam initialize?: %s" % initialize_response)

	if initialize_response == false:
		print("Failed to initialize Steam, shutting down: %s" % initialize_response)
		get_tree().quit()

	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

func _process(_delta: float) -> void:
	Steam.run_callbacks()
