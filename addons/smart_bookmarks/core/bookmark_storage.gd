# bookmark_storage.gd
# Dual-tier persistence engine for Smart Bookmarks (Project Config + Local User State).
@tool
class_name BookmarkStorage
extends RefCounted

const DEFAULT_PROJECT_CONFIG_PATH: String = "res://smart_bookmarks.cfg"
const DEFAULT_USER_CONFIG_PATH: String = "user://smart_bookmarks_user.cfg"

# Save project-wide bundles to ConfigFile
static func save_project_bundles(bundles: Array[BookmarkBundle], path: String = DEFAULT_PROJECT_CONFIG_PATH) -> Error:
	var config := ConfigFile.new()
	
	# Global metadata
	config.set_value("metadata", "version", "1.0.0")
	config.set_value("metadata", "bundle_count", bundles.size())
	config.set_value("metadata", "updated_at", Time.get_datetime_string_from_system())
	
	var bundle_ids: PackedStringArray = []
	for bundle in bundles:
		bundle_ids.append(bundle.id)
		var section := "bundle." + bundle.id
		config.set_value(section, "id", bundle.id)
		config.set_value(section, "name", bundle.name)
		config.set_value(section, "description", bundle.description)
		config.set_value(section, "color_tag", bundle.color_tag.to_html(true))
		config.set_value(section, "icon_name", bundle.icon_name)
		config.set_value(section, "tags", bundle.tags)
		config.set_value(section, "auto_group_prefix", bundle.auto_group_prefix)
		config.set_value(section, "is_default", bundle.is_default)
		
		# Serialize items
		var item_dicts: Array[Dictionary] = []
		for item in bundle.items:
			item_dicts.append(item.to_dict())
		config.set_value(section, "items", item_dicts)
		
	config.set_value("metadata", "bundle_order", bundle_ids)
	
	var err := config.save(path)
	return err

# Load project-wide bundles from ConfigFile
static func load_project_bundles(path: String = DEFAULT_PROJECT_CONFIG_PATH) -> Array[BookmarkBundle]:
	var bundles: Array[BookmarkBundle] = []
	var config := ConfigFile.new()
	var err := config.load(path)
	
	if err != OK:
		# Return default initial bundles if file doesn't exist yet
		return get_default_bundles()
		
	var bundle_order: PackedStringArray = config.get_value("metadata", "bundle_order", PackedStringArray())
	
	if bundle_order.is_empty():
		# Fallback: scan sections
		for section in config.get_sections():
			if section.begins_with("bundle."):
				var bundle_id := section.substr(7)
				bundle_order.append(bundle_id)
				
	for b_id in bundle_order:
		var section := "bundle." + b_id
		if not config.has_section(section):
			continue
			
		var data: Dictionary = {
			"id": config.get_value(section, "id", b_id),
			"name": config.get_value(section, "name", "Bundle"),
			"description": config.get_value(section, "description", ""),
			"color_tag": config.get_value(section, "color_tag", "#4fc3f7ff"),
			"icon_name": config.get_value(section, "icon_name", "Box"),
			"tags": config.get_value(section, "tags", PackedStringArray()),
			"auto_group_prefix": config.get_value(section, "auto_group_prefix", ""),
			"is_default": config.get_value(section, "is_default", false),
			"items": config.get_value(section, "items", [])
		}
		bundles.append(BookmarkBundle.from_dict(data))
		
	if bundles.is_empty():
		return get_default_bundles()
		
	return bundles

# Save user-specific state (Active bundle selection, LRU history, UI settings)
static func save_user_state(
	active_bundle_id: String,
	history: Array[BookmarkItem],
	settings: Dictionary = {},
	path: String = DEFAULT_USER_CONFIG_PATH
) -> Error:
	var config := ConfigFile.new()
	config.set_value("session", "active_bundle_id", active_bundle_id)
	config.set_value("session", "saved_at", Time.get_datetime_string_from_system())
	
	var history_dicts: Array[Dictionary] = []
	for item in history:
		history_dicts.append(item.to_dict())
	config.set_value("session", "history", history_dicts)
	
	for key in settings:
		config.set_value("settings", key, settings[key])
		
	return config.save(path)

# Load user-specific state
static func load_user_state(path: String = DEFAULT_USER_CONFIG_PATH) -> Dictionary:
	var result: Dictionary = {
		"active_bundle_id": "",
		"history": [] as Array[BookmarkItem],
		"settings": {} as Dictionary
	}
	
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		return result
		
	result["active_bundle_id"] = str(config.get_value("session", "active_bundle_id", ""))
	
	var raw_history: Array = config.get_value("session", "history", [])
	var items: Array[BookmarkItem] = []
	for item_data in raw_history:
		if item_data is Dictionary:
			items.append(BookmarkItem.from_dict(item_data))
	result["history"] = items
	
	var settings: Dictionary = {}
	if config.has_section("settings"):
		for key in config.get_section_keys("settings"):
			settings[key] = config.get_value("settings", key)
	result["settings"] = settings
	
	return result

# Default starter bundles for fresh projects
static func get_default_bundles() -> Array[BookmarkBundle]:
	var default_bundle := BookmarkBundle.new("bundle_main", "★ Quick Access", Color(0.3, 0.7, 1.0, 1.0))
	default_bundle.description = "Primary frequently-accessed files."
	default_bundle.icon_name = "Star"
	default_bundle.is_default = true
	default_bundle.tags = ["Core", "Quick"]
	
	return [default_bundle]

# JSON Export / Import helpers for sharing bundles
static func export_bundles_json(bundles: Array[BookmarkBundle]) -> String:
	var list: Array[Dictionary] = []
	for b in bundles:
		list.append(b.to_dict())
	return JSON.stringify({
		"format": "smart_bookmarks_bundle_export",
		"version": "1.0.0",
		"bundles": list
	}, "\t")

static func import_bundles_json(json_str: String) -> Array[BookmarkBundle]:
	var parsed = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		return []
	var list: Array[BookmarkBundle] = []
	var bundles_data: Array = parsed.get("bundles", [])
	for b_data in bundles_data:
		if b_data is Dictionary:
			list.append(BookmarkBundle.from_dict(b_data))
	return list
