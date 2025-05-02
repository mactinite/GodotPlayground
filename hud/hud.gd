extends Control

@onready var reticle: TextureRect = $Reticle
@onready var interaction_raycast: RayCast3D = null
@onready var player_controller: CharacterBody3D = null

@export var cursormap: Dictionary = {
	"Default": preload("res://kenney_cursor-pixel-pack/Tiles/tile_0057.png"),
	"Grab": preload("res://kenney_cursor-pixel-pack/Tiles/tile_0138.png"),
	"Loot": preload("res://kenney_cursor-pixel-pack/Tiles/tile_0135.png")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_reticle("Default")
	reticle.visible = false
	SignalBus.on_player_spawned.connect(_on_player_spawned)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if interaction_raycast and interaction_raycast.is_colliding():
		var collider = interaction_raycast.get_collider()
		if collider.has_meta("Verb"):
			var verb = collider.get_meta("Verb")
			update_reticle(verb)
		else:
			update_reticle("Default")
	else:
		update_reticle("Default")

# Updates the reticle texture based on the interaction type.
func update_reticle(cursor_type: String) -> void:
	if cursormap.has(cursor_type):
		reticle.texture = cursormap[cursor_type]
	else:
		reticle.texture = cursormap["Default"]


func _on_interaction_changed(verb: String) -> void:
	update_reticle(verb)

func _on_player_spawned(player: Node) -> void:
	player_controller = player
	if player_controller:
		interaction_raycast = player_controller.interaction_raycast
		if interaction_raycast:
			interaction_raycast.interaction_changed.connect(_on_interaction_changed)
			reticle.visible = true
		
