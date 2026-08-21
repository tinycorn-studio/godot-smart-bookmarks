# bookmark_item.gd
# Represents a single bookmarked or history-tracked file in the Godot project.
@tool
class_name BookmarkItem
extends RefCounted

var path: String = ""
var title: String = ""
var resource_type: String = "File"
var icon_name: String = "File"
var custom_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var last_opened_time: int = 0
var access_count: int = 0
var is_pinned: bool = false
var notes: String = ""

func _init(p_path: String = "", p_title: String = "") -> void:
	path = p_path
	title = p_title if not p_title.is_empty() else (p_path.get_file() if not p_path.is_empty() else "Untitled")
	last_opened_time = int(Time.get_unix_time_from_system())
	access_count = 1
	_detect_resource_type()

func _detect_resource_type() -> void:
	if path.is_empty():
		resource_type = "File"
		icon_name = "File"
		return
		
	var ext: String = path.get_extension().to_lower()
	match ext:
		"tscn", "scn":
			resource_type = "PackedScene"
			icon_name = "PackedScene"
		"gd":
			resource_type = "GDScript"
			icon_name = "GDScript"
		"cs":
			resource_type = "CSharpScript"
			icon_name = "CSharpScript"
		"gdshader", "shader":
			resource_type = "Shader"
			icon_name = "Shader"
		"tres", "res":
			resource_type = "Resource"
			icon_name = "Resource"
		"material":
			resource_type = "Material"
			icon_name = "Material"
		"wav", "mp3", "ogg":
			resource_type = "AudioStream"
			icon_name = "AudioStreamPlayer"
		"png", "jpg", "jpeg", "webp", "svg":
			resource_type = "Texture2D"
			icon_name = "Texture2D"
		"json", "cfg", "ini", "txt", "md", "csv":
			resource_type = "TextFile"
			icon_name = "TextFile"
		_:
			resource_type = "File"
			icon_name = "File"

func get_extension() -> String:
	return path.get_extension().to_lower()

func get_directory() -> String:
	return path.get_base_dir()

func get_stem() -> String:
	return path.get_file().get_basename()

func record_access() -> void:
	last_opened_time = int(Time.get_unix_time_from_system())
	access_count += 1

func matches_query(query: String) -> bool:
	if query.is_empty():
		return true
	var q: String = query.to_lower().strip_edges()
	if title.to_lower().contains(q):
		return true
	if path.to_lower().contains(q):
		return true
	if resource_type.to_lower().contains(q):
		return true
	if notes.to_lower().contains(q):
		return true
	return false

func get_relative_time_string() -> String:
	if last_opened_time <= 0:
		return "Never"
	var current_time: int = int(Time.get_unix_time_from_system())
	var diff: int = maxi(0, current_time - last_opened_time)
	
	if diff < 10:
		return "Just now"
	elif diff < 60:
		return "%ds ago" % diff
	elif diff < 3600:
		var mins: int = diff / 60
		return "%dm ago" % mins
	elif diff < 86400:
		var hours: int = diff / 3600
		return "%dh ago" % hours
	else:
		var days: int = diff / 86400
		return "%dd ago" % days

func to_dict() -> Dictionary:
	return {
		"path": path,
		"title": title,
		"resource_type": resource_type,
		"icon_name": icon_name,
		"custom_color": custom_color.to_html(true),
		"last_opened_time": last_opened_time,
		"access_count": access_count,
		"is_pinned": is_pinned,
		"notes": notes
	}

static func from_dict(data: Dictionary) -> BookmarkItem:
	var p: String = data.get("path", "")
	var t: String = data.get("title", "")
	var item: BookmarkItem = BookmarkItem.new(p, t)
	
	if data.has("resource_type") and not str(data["resource_type"]).is_empty():
		item.resource_type = str(data["resource_type"])
	if data.has("icon_name") and not str(data["icon_name"]).is_empty():
		item.icon_name = str(data["icon_name"])
	if data.has("custom_color"):
		var color_str: String = str(data["custom_color"])
		item.custom_color = Color.from_string(color_str, Color.WHITE)
	if data.has("last_opened_time"):
		item.last_opened_time = int(data["last_opened_time"])
	if data.has("access_count"):
		item.access_count = int(data["access_count"])
	if data.has("is_pinned"):
		item.is_pinned = bool(data["is_pinned"])
	if data.has("notes"):
		item.notes = str(data["notes"])
		
	return item

func duplicate_item() -> BookmarkItem:
	var copy: BookmarkItem = BookmarkItem.new(path, title)
	copy.resource_type = resource_type
	copy.icon_name = icon_name
	copy.custom_color = custom_color
	copy.last_opened_time = last_opened_time
	copy.access_count = access_count
	copy.is_pinned = is_pinned
	copy.notes = notes
	return copy
