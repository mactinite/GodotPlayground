extends RayCast3D

signal interaction_changed(verb: String)

func check_interactable() -> bool:
	return is_colliding() && get_collider().has_meta("Verb")
	

func _physics_process(delta: float) -> void:
	if check_interactable():
		var verb = get_collider().get_meta("Verb")
		interaction_changed.emit(verb)
	else:
		interaction_changed.emit("Default")
