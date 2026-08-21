# recent_history_tracker.gd
# LRU file access history ring buffer with frequency tracking and search.
@tool
class_name RecentHistoryTracker
extends RefCounted

signal history_updated
signal entry_recorded(item: BookmarkItem)

var max_capacity: int = 30
var entries: Array[BookmarkItem] = []

func _init(p_capacity: int = 30) -> void:
	max_capacity = maxi(5, p_capacity)

func record_access(path: String, title: String = "") -> BookmarkItem:
	if path.is_empty():
		return null
		
	# Check if already exists in history
	var existing_item: BookmarkItem = null
	var existing_index: int = -1
	
	for i in range(entries.size()):
		if entries[i].path == path:
			existing_item = entries[i]
			existing_index = i
			break
			
	if existing_item != null:
		existing_item.record_access()
		if not title.is_empty():
			existing_item.title = title
		# Move to front (LRU)
		if existing_index > 0:
			entries.remove_at(existing_index)
			entries.insert(0, existing_item)
		history_updated.emit()
		entry_recorded.emit(existing_item)
		return existing_item
	else:
		var new_item := BookmarkItem.new(path, title)
		entries.insert(0, new_item)
		# Enforce capacity
		while entries.size() > max_capacity:
			entries.pop_back()
		history_updated.emit()
		entry_recorded.emit(new_item)
		return new_item

func remove_entry(path: String) -> bool:
	for i in range(entries.size() - 1, -1, -1):
		if entries[i].path == path:
			entries.remove_at(i)
			history_updated.emit()
			return true
	return false

func clear_history() -> void:
	if entries.is_empty():
		return
	entries.clear()
	history_updated.emit()

func get_entries() -> Array[BookmarkItem]:
	return entries

func get_entry_count() -> int:
	return entries.size()

func get_entry(path: String) -> BookmarkItem:
	for item in entries:
		if item.path == path:
			return item
	return null

func get_frequent_entries(limit: int = 5) -> Array[BookmarkItem]:
	var copy: Array[BookmarkItem] = entries.duplicate()
	copy.sort_custom(func(a: BookmarkItem, b: BookmarkItem) -> bool:
		return a.access_count > b.access_count
	)
	if copy.size() > limit:
		copy.resize(limit)
	return copy

func search_history(query: String) -> Array[BookmarkItem]:
	if query.is_empty():
		return entries
	var results: Array[BookmarkItem] = []
	for item in entries:
		if item.matches_query(query):
			results.append(item)
	return results

func to_array() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in entries:
		result.append(item.to_dict())
	return result

func from_array(data: Array) -> void:
	entries.clear()
	for item_data in data:
		if item_data is Dictionary:
			var item: BookmarkItem = BookmarkItem.from_dict(item_data)
			if entries.size() < max_capacity:
				entries.append(item)
	history_updated.emit()
