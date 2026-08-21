# scene_script_switcher.gd
# Fast bidirectional heuristic resolver and toggle engine between Scene (.tscn) and Script (.gd/.cs).
@tool
class_name SceneScriptSwitcher
extends RefCounted

# Pre-defined search extension pairs
const SCRIPT_EXTENSIONS: Array[String] = ["gd", "cs", "gdshader"]
const SCENE_EXTENSIONS: Array[String] = ["tscn", "scn"]

static func is_scene_path(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext in SCENE_EXTENSIONS

static func is_script_path(path: String) -> bool:
	var ext := path.get_extension().to_lower()
	return ext in SCRIPT_EXTENSIONS

# Heuristic 1: Resolve matching script for a given scene
static func resolve_script_from_scene(scene_path: String, root_node: Node = null) -> String:
	# 1. If root node is loaded and has an attached script, that is the most reliable match
	if root_node != null:
		var script_res = root_node.get_script()
		if script_res is Script and not script_res.resource_path.is_empty():
			return script_res.resource_path
			
	if scene_path.is_empty():
		return ""
		
	var stem := scene_path.get_basename()
	var base_dir := scene_path.get_base_dir()
	var file_name_stem := scene_path.get_file().get_basename()
	
	# 2. Sibling script in exact same directory: e.g. "res://player.tscn" -> "res://player.gd"
	for ext in SCRIPT_EXTENSIONS:
		var candidate := stem + "." + ext
		if FileAccess.file_exists(candidate):
			return candidate
			
	# 3. Mirror in "scripts" or "src" folder: e.g. "res://scenes/player.tscn" -> "res://scripts/player.gd"
	var dir_variations: Array[String] = [
		base_dir.replace("/scenes", "/scripts"),
		base_dir.replace("/Scenes", "/Scripts"),
		base_dir.replace("/scenes", "/src"),
		base_dir.path_join("../scripts"),
		base_dir.path_join("../src"),
		"res://scripts",
		"res://src"
	]
	
	for dir in dir_variations:
		for ext in SCRIPT_EXTENSIONS:
			var candidate := dir.path_join(file_name_stem + "." + ext).simplify_path()
			if FileAccess.file_exists(candidate):
				return candidate
				
	# 4. Fallback convention: return predicted sibling path even if not yet on disk
	return stem + ".gd"

# Heuristic 2: Resolve matching scene for a given script
static func resolve_scene_from_script(script_path: String) -> String:
	if script_path.is_empty():
		return ""
		
	var stem := script_path.get_basename()
	var base_dir := script_path.get_base_dir()
	var file_name_stem := script_path.get_file().get_basename()
	
	# 1. Sibling scene in exact same directory: e.g. "res://player.gd" -> "res://player.tscn"
	for ext in SCENE_EXTENSIONS:
		var candidate := stem + "." + ext
		if FileAccess.file_exists(candidate):
			return candidate
			
	# 2. Mirror in "scenes" or "ui" folder: e.g. "res://scripts/player.gd" -> "res://scenes/player.tscn"
	var dir_variations: Array[String] = [
		base_dir.replace("/scripts", "/scenes"),
		base_dir.replace("/Scripts", "/Scenes"),
		base_dir.replace("/src", "/scenes"),
		base_dir.path_join("../scenes"),
		base_dir.path_join("../Scenes"),
		base_dir.path_join("../ui"),
		"res://scenes",
		"res://ui"
	]
	
	for dir in dir_variations:
		for ext in SCENE_EXTENSIONS:
			var candidate := dir.path_join(file_name_stem + "." + ext).simplify_path()
			if FileAccess.file_exists(candidate):
				return candidate
				
	# 3. Fallback convention: return predicted sibling path
	return stem + ".tscn"

# Perform toggle calculation and execution
static func execute_toggle(
	current_file_path: String,
	root_node: Node = null,
	editor_interface: Object = null
) -> Dictionary:
	var result: Dictionary = {
		"success": false,
		"source_path": current_file_path,
		"target_path": "",
		"target_type": "",
		"exists": false,
		"message": ""
	}
	
	if current_file_path.is_empty():
		result["message"] = "No active file path specified to toggle."
		return result
		
	if is_scene_path(current_file_path):
		var target_script := resolve_script_from_scene(current_file_path, root_node)
		result["target_path"] = target_script
		result["target_type"] = "Script"
		result["exists"] = FileAccess.file_exists(target_script)
		result["success"] = true
		result["message"] = "Toggled from Scene '%s' to Script '%s'" % [current_file_path.get_file(), target_script.get_file()]
		
		if editor_interface != null and result["exists"]:
			_open_in_editor(editor_interface, target_script, "Script")
			
	elif is_script_path(current_file_path):
		var target_scene := resolve_scene_from_script(current_file_path)
		result["target_path"] = target_scene
		result["target_type"] = "Scene"
		result["exists"] = FileAccess.file_exists(target_scene)
		result["success"] = true
		result["message"] = "Toggled from Script '%s' to Scene '%s'" % [current_file_path.get_file(), target_scene.get_file()]
		
		if editor_interface != null and result["exists"]:
			_open_in_editor(editor_interface, target_scene, "Scene")
	else:
		result["message"] = "File '%s' is neither a recognized Scene nor Script." % current_file_path.get_file()
		
	return result

static func _open_in_editor(editor_interface: Object, path: String, type: String) -> void:
	if editor_interface == null:
		return
	if type == "Scene" and editor_interface.has_method("open_scene_from_path"):
		editor_interface.open_scene_from_path(path)
	elif type == "Script" and editor_interface.has_method("edit_script"):
		var script_res = ResourceLoader.load(path)
		if script_res is Script:
			editor_interface.edit_script(script_res)
	elif editor_interface.has_method("edit_resource"):
		var res = ResourceLoader.load(path)
		if res != null:
			editor_interface.edit_resource(res)
