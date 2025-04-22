extends Control
class_name Menus
@export var current_menu: MENU = MENU.MAIN

enum MENU {
	MAIN = 0,
	LAN = 1,
	STEAM = 2,
	LOBBY = 3,
}

func _ready() -> void:
	get_child(current_menu).show()
	pass
	
func goto(menu_name: MENU) -> void:
	self.visible = true
	get_child(current_menu).hide()
	get_child(menu_name).show()
	current_menu = menu_name
	pass
	
func close() -> void:
	for child in get_children():
		child.visible = false
	self.visible = false
	
func _on_lan_button_down() -> void:
	goto(MENU.LAN)
	pass # Replace with function body.

func _on_steam_button_down() -> void:
	goto(MENU.STEAM)
	pass # Replace with function body.

func _on_exit_button_down() -> void:
	get_tree().quit()
	pass # Replace with function body.
