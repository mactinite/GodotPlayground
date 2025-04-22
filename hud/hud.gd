extends Control

@onready var reticle: TextureRect = $Reticle
@onready var interaction_raycast: RayCast3D = $"../interaction_raycast"

@export var cursormap: Dictionary = {
	"Default": preload("res://kenney_cursor-pixel-pack/Tiles/tile_0057.png"),
	"Grab": preload("res://kenney_cursor-pixel-pack/Tiles/tile_0138.png"),
	"Loot": preload("res://kenney_cursor-pixel-pack/Tiles/tile_0135.png")
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if is_multiplayer_authority():
		if interaction_raycast.is_colliding() && \
		interaction_raycast.get_collider():
			var verb = interaction_raycast.get_collider().get_meta("verb")
			
			if cursormap.has(verb):
				reticle.set_texture(cursormap[verb])
		else:
			reticle.set_texture(cursormap["Default"])
