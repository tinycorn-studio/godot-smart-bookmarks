# inventory.gd
# Mock inventory controller script.
class_name MockInventory
extends Control

@export var max_slots: int = 24
var items: Array[String] = ["Potion", "Iron Sword", "Magic Wand", "Shield"]

func add_item(item_name: String) -> bool:
	if items.size() < max_slots:
		items.append(item_name)
		return true
	return false
