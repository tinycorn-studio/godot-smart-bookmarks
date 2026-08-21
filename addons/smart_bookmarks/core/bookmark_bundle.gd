# bookmark_bundle.gd
# Represents a logical bundle/group of related files (e.g. Player scene, script, and resources).
@tool
class_name BookmarkBundle
extends Resource

signal bundle_changed

@export var id: String = ""
@export var name: String = "New Bundle"
@export var description: String = ""
@export var color_tag: Color = Color(0.3, 0.65, 0.95, 1.0)
@export var icon_name: String = "Box"
@export var tags: PackedStringArray = []
@export var auto_group_prefix: String = ""
@export var is_default: bool = false

var items: Array[BookmarkItem] = []

func _init(p_id: String = "", p_name: String = "New Bundle", p_color: Color = Color(0.3, 0.65, 0.95, 1.0)) -> void:
	id = p_id if not p_id.is_empty() else ("bundle_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000))
	name = p_name
	color_tag = p_color

func add_item(item: BookmarkItem) -> bool:
	if item == null or item.path.is_empty():
		return false
	for existing in items:
		if existing.path == item.path:
			return false
	items.append(item)
	bundle_changed.emit()
	emit_changed()
	return true

func add_path(path: String, title: String = "") -> bool:
	if path.is_empty() or has_item(path):
		return false
	var item := BookmarkItem.new(path, title)
	return add_item(item)

func remove_item_by_path(path: String) -> bool:
	for i in range(items.size() - 1, -1, -1):
		if items[i].path == path:
			items.remove_at(i)
			bundle_changed.emit()
			emit_changed()
			return true
	return false

func remove_item_at(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	items.remove_at(index)
	bundle_changed.emit()
	emit_changed()
	return true

func has_item(path: String) -> bool:
	for item in items:
		if item.path == path:
			return true
	return false

func get_item(path: String) -> BookmarkItem:
	for item in items:
		if item.path == path:
			return item
	return null

func get_item_at(index: int) -> BookmarkItem:
	if index >= 0 and index < items.size():
		return items[index]
	return null

func reorder_item(from_index: int, to_index: int) -> bool:
	if from_index < 0 or from_index >= items.size():
		return false
	if to_index < 0 or to_index >= items.size():
		return false
	if from_index == to_index:
		return true
		
	var item := items[from_index]
	items.remove_at(from_index)
	items.insert(to_index, item)
	bundle_changed.emit()
	emit_changed()
	return true

func move_item_up(index: int) -> bool:
	if index <= 0 or index >= items.size():
		return false
	return reorder_item(index, index - 1)

func move_item_down(index: int) -> bool:
	if index < 0 or index >= items.size() - 1:
		return false
	return reorder_item(index, index + 1)

func clear_items() -> void:
	if items.is_empty():
		return
	items.clear()
	bundle_changed.emit()
	emit_changed()

func get_item_count() -> int:
	return items.size()

func matches_query(query: String) -> bool:
	if query.is_empty():
		return true
	var q := query.to_lower().strip_edges()
	if name.to_lower().contains(q):
		return true
	if description.to_lower().contains(q):
		return true
	for tag in tags:
		if tag.to_lower().contains(q):
			return true
	for item in items:
		if item.matches_query(q):
			return true
	return false

func to_dict() -> Dictionary:
	var items_data: Array[Dictionary] = []
	for item in items:
		items_data.append(item.to_dict())
		
	return {
		"id": id,
		"name": name,
		"description": description,
		"color_tag": color_tag.to_html(true),
		"icon_name": icon_name,
		"tags": Array(tags),
		"auto_group_prefix": auto_group_prefix,
		"is_default": is_default,
		"items": items_data
	}

static func from_dict(data: Dictionary) -> BookmarkBundle:
	var bundle_id: String = str(data.get("id", ""))
	var bundle_name: String = str(data.get("name", "Unnamed Bundle"))
	var color_str: String = str(data.get("color_tag", "#4fc3f7ff"))
	var color: Color = Color.from_string(color_str, Color(0.3, 0.65, 0.95, 1.0))
	
	var bundle := BookmarkBundle.new(bundle_id, bundle_name, color)
	bundle.description = str(data.get("description", ""))
	bundle.icon_name = str(data.get("icon_name", "Box"))
	bundle.auto_group_prefix = str(data.get("auto_group_prefix", ""))
	bundle.is_default = bool(data.get("is_default", false))
	
	var raw_tags: Array = data.get("tags", [])
	var parsed_tags: PackedStringArray = PackedStringArray()
	for t in raw_tags:
		parsed_tags.append(str(t))
	bundle.tags = parsed_tags
	
	var raw_items: Array = data.get("items", [])
	for item_data in raw_items:
		if item_data is Dictionary:
			var item: BookmarkItem = BookmarkItem.from_dict(item_data)
			bundle.items.append(item)
			
	return bundle

func duplicate_bundle() -> BookmarkBundle:
	var dup := BookmarkBundle.new(id + "_copy", name + " (Copy)", color_tag)
	dup.description = description
	dup.icon_name = icon_name
	dup.tags = tags.duplicate()
	dup.auto_group_prefix = auto_group_prefix
	dup.is_default = false
	for item in items:
		dup.items.append(item.duplicate_item())
	return dup
