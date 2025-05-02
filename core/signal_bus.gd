extends Node

signal on_game_start()
signal on_player_inventory_update(InventoryData)
signal on_player_inventory_toggle(Node3D)
signal on_external_inventory_update(InventoryData)
signal on_external_inventory_toggle()
signal on_player_spawned(player: Node)
