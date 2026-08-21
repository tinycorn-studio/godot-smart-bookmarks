# bookmark_manager.gd
# Central state, business logic, and coordination engine for Smart Bookmarks.
@tool
class_name BookmarkManager
extends RefCounted

signal bundle_list_changed
signal active_bundle_changed(bundle: BookmarkBundle)
signal bookmarks_updated
signal file_open_requested(path: String, resource_type: String)
signal history_updated

var editor_interface: Object = null
var project_config_path: String = BookmarkStorage.DEFAULT_PROJECT_CONFIG_PATH
var user_config_path: String = BookmarkStorage.DEFAULT_USER_CONFIG_PATH

var bundles: Array[BookmarkBundle] = []
var active_bundle: BookmarkBundle = null
var history_tracker: RecentHistoryTracker = null

func _init() -> void:
	history_tracker = RecentHistoryTracker.new(30)
	history_tracker.history_updated.connect(func(): history_updated.emit())

func initialize(
	p_editor_interface: Object = null,
	p_project_config: String = "",
	p_user_config: String = ""
) -> void:
	editor_interface = p_editor_interface
	if not p_project_config.is_empty():
		project_config_path = p_project_config
	if not p_user_config.is_empty():
		user_config_path = p_user_config
		
	load_all()

func load_all() -> void:
	# 1. Load project bundles
	bundles = BookmarkStorage.load_project_bundles(project_config_path)
	
	# 2. Connect change signals for all bundles
	for bundle in bundles:
		_connect_bundle_signals(bundle)
		
	# 3. Load user state
	var user_state := BookmarkStorage.load_user_state(user_config_path)
	var active_id: String = str(user_state.get("active_bundle_id", ""))
	var saved_history: Array[BookmarkItem] = user_state.get("history", [])
	
	if not saved_history.is_empty():
		var history_dicts: Array[Dictionary] = []
		for item in saved_history:
			history_dicts.append(item.to_dict())
		history_tracker.from_array(history_dicts)
		
	# 4. Set active bundle
	if not set_active_bundle(active_id):
		if not bundles.is_empty():
			set_active_bundle(bundles[0].id)
			
	bundle_list_changed.emit()

func save_all() -> void:
	BookmarkStorage.save_project_bundles(bundles, project_config_path)
	var active_id := active_bundle.id if active_bundle != null else ""
	BookmarkStorage.save_user_state(active_id, history_tracker.get_entries(), {}, user_config_path)

func _connect_bundle_signals(bundle: BookmarkBundle) -> void:
	if not bundle.bundle_changed.is_connected(_on_bundle_contents_changed):
		bundle.bundle_changed.connect(_on_bundle_contents_changed)

func _on_bundle_contents_changed() -> void:
	bookmarks_updated.emit()
	save_all()

func get_all_bundles() -> Array[BookmarkBundle]:
	return bundles

func get_active_bundle() -> BookmarkBundle:
	return active_bundle

func get_bundle_by_id(bundle_id: String) -> BookmarkBundle:
	for b in bundles:
		if b.id == bundle_id:
			return b
	return null

func create_bundle(
	p_name: String,
	p_color: Color = Color(0.3, 0.65, 0.95, 1.0),
	p_icon: String = "Box",
	p_tags: PackedStringArray = []
) -> BookmarkBundle:
	var id := "bundle_" + p_name.to_lower().replace(" ", "_") + "_" + str(Time.get_ticks_msec())
	var new_bundle := BookmarkBundle.new(id, p_name, p_color)
	new_bundle.icon_name = p_icon
	new_bundle.tags = p_tags
	
	bundles.append(new_bundle)
	_connect_bundle_signals(new_bundle)
	set_active_bundle(id)
	
	bundle_list_changed.emit()
	save_all()
	return new_bundle

func remove_bundle(bundle_id: String) -> bool:
	if bundles.size() <= 1:
		return false # Keep at least one bundle
		
	for i in range(bundles.size() - 1, -1, -1):
		if bundles[i].id == bundle_id:
			var removed_bundle := bundles[i]
			if removed_bundle.bundle_changed.is_connected(_on_bundle_contents_changed):
				removed_bundle.bundle_changed.disconnect(_on_bundle_contents_changed)
			bundles.remove_at(i)
			
			if active_bundle == removed_bundle:
				var next_idx := mini(i, bundles.size() - 1)
				set_active_bundle(bundles[next_idx].id)
				
			bundle_list_changed.emit()
			save_all()
			return true
	return false

func set_active_bundle(bundle_id: String) -> bool:
	for b in bundles:
		if b.id == bundle_id:
			active_bundle = b
			active_bundle_changed.emit(active_bundle)
			bookmarks_updated.emit()
			return true
	return false

func pin_file(path: String, title: String = "", target_bundle_id: String = "") -> bool:
	var bundle: BookmarkBundle = null
	if target_bundle_id.is_empty():
		bundle = active_bundle
	else:
		bundle = get_bundle_by_id(target_bundle_id)
		
	if bundle == null:
		return false
		
	var item := BookmarkItem.new(path, title)
	item.is_pinned = true
	var added := bundle.add_item(item)
	if added:
		history_tracker.record_access(path, item.title)
	return added

func unpin_file(path: String, target_bundle_id: String = "") -> bool:
	var bundle: BookmarkBundle = null
	if target_bundle_id.is_empty():
		bundle = active_bundle
	else:
		bundle = get_bundle_by_id(target_bundle_id)
		
	if bundle == null:
		return false
		
	return bundle.remove_item_by_path(path)

func is_file_pinned(path: String, target_bundle_id: String = "") -> bool:
	var bundle: BookmarkBundle = null
	if target_bundle_id.is_empty():
		bundle = active_bundle
	else:
		bundle = get_bundle_by_id(target_bundle_id)
		
	if bundle == null:
		return false
	return bundle.has_item(path)

func open_file(path: String, title: String = "") -> void:
	if path.is_empty():
		return
		
	var item := history_tracker.record_access(path, title)
	var res_type := item.resource_type if item != null else "File"
	
	file_open_requested.emit(path, res_type)
	
	if editor_interface != null:
		if SceneScriptSwitcher.is_scene_path(path) and editor_interface.has_method("open_scene_from_path"):
			editor_interface.open_scene_from_path(path)
		elif SceneScriptSwitcher.is_script_path(path) and editor_interface.has_method("edit_script"):
			var script_res = ResourceLoader.load(path)
			if script_res is Script:
				editor_interface.edit_script(script_res)
		elif editor_interface.has_method("edit_resource"):
			var res = ResourceLoader.load(path)
			if res != null:
				editor_interface.edit_resource(res)

func toggle_scene_to_script(current_file_path: String = "", root_node: Node = null) -> Dictionary:
	var file_to_toggle := current_file_path
	if file_to_toggle.is_empty():
		# Try detecting from active history or editor
		var history_entries := history_tracker.get_entries()
		if not history_entries.is_empty():
			file_to_toggle = history_entries[0].path
			
	var result := SceneScriptSwitcher.execute_toggle(file_to_toggle, root_node, editor_interface)
	if result["success"] and not result["target_path"].is_empty():
		open_file(result["target_path"])
	return result

# Smart auto-bundling algorithm:
# Discovers related files (.gd, .tscn, .tres, .png, .shader, etc.) matching a stem or prefix
func auto_group_files_from_stem(
	stem_or_path: String,
	bundle_name: String = "",
	search_dirs: Array[String] = []
) -> BookmarkBundle:
	var clean_stem: String = stem_or_path.get_file().get_basename().to_lower()
	# Strip common prefixes/suffixes for broader matching
	clean_stem = clean_stem.trim_suffix("_controller").trim_suffix("_manager").trim_suffix("_data")
	
	var final_name: String = bundle_name
	if final_name.is_empty():
		final_name = clean_stem.capitalize()
		
	var new_bundle := create_bundle(final_name, Color(0.4, 0.75, 0.4, 1.0), "Package", [clean_stem])
	new_bundle.auto_group_prefix = clean_stem
	
	# Determine scan roots
	var scan_roots: Array[String] = search_dirs.duplicate()
	if scan_roots.is_empty():
		if stem_or_path.begins_with("res://"):
			scan_roots.append(stem_or_path.get_base_dir())
		scan_roots.append("res://")
		
	var discovered_paths: Array[String] = []
	for root in scan_roots:
		_scan_directory_for_matches(root, clean_stem, discovered_paths, 3)
		
	for p in discovered_paths:
		new_bundle.add_path(p)
		
	return new_bundle

func _scan_directory_for_matches(dir_path: String, stem: String, out_paths: Array[String], max_depth: int) -> void:
	if max_depth <= 0:
		return
	if not DirAccess.dir_exists_absolute(dir_path):
		return
		
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
		
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while not file_name.is_empty():
		if not file_name.begins_with("."):
			var full_path := dir_path.path_join(file_name).simplify_path()
			if dir.current_is_dir():
				_scan_directory_for_matches(full_path, stem, out_paths, max_depth - 1)
			else:
				var f_stem := file_name.get_basename().to_lower()
				if f_stem.contains(stem) and not out_paths.has(full_path):
					out_paths.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()

func search_all(query: String) -> Dictionary:
	var result: Dictionary = {
		"bookmarks": [] as Array[BookmarkItem],
		"history": [] as Array[BookmarkItem],
		"bundles": [] as Array[BookmarkBundle]
	}
	
	var q := query.to_lower().strip_edges()
	
	# Search bookmarks across all bundles
	var seen_paths: Dictionary = {}
	for b in bundles:
		if b.matches_query(q):
			result["bundles"].append(b)
		for item in b.items:
			if not seen_paths.has(item.path) and item.matches_query(q):
				seen_paths[item.path] = true
				result["bookmarks"].append(item)
				
	# Search recent history
	result["history"] = history_tracker.search_history(q)
	
	return result
