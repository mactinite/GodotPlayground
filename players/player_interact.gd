extends RayCast3D


func check_interactable() -> bool:
	return is_colliding() && get_collider().has_method("interact")
	

func _physics_process(delta: float) -> void:
	if check_interactable() && Input.is_action_just_pressed("interact"):
		get_collider().interact()
