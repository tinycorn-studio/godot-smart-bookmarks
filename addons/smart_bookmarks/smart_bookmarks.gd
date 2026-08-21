# smart_bookmarks.gd
# Main EditorPlugin entry point for Smart Bookmarks & Quick File Switcher.
@tool
class_name SmartBookmarksPlugin
extends EditorPlugin

var manager: BookmarkManager = null
var toolbar_ribbon: ToolbarRibbon = null

const TOOLBAR_RIBBON_SCENE: PackedScene = preload("ui/toolbar_ribbon.tscn")

func _enter_tree() -> void:
	# 1. Initialize Bookmark Manager singleton/controller
	manager = BookmarkManager.new()
	manager.initialize(get_editor_interface(), "res://smart_bookmarks.cfg", "user://smart_bookmarks_user.cfg")
	
	# 2. Instantiate and inject toolbar ribbon
	if TOOLBAR_RIBBON_SCENE != null:
		toolbar_ribbon = TOOLBAR_RIBBON_SCENE.instantiate() as ToolbarRibbon
		add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_ribbon)
		toolbar_ribbon.setup(manager, get_editor_interface())
		
	# 3. Connect editor signals for auto history tracking
	var editor_interface := get_editor_interface()
	if editor_interface != null:
		if editor_interface.has_signal("scene_changed"):
			editor_interface.scene_changed.connect(_on_editor_scene_changed)
			
	# Connect to script editor if available
	_connect_script_editor_signals()

func _exit_tree() -> void:
	# 1. Save all project and user configurations
	if manager != null:
		manager.save_all()
		
	# 2. Remove and clean up toolbar ribbon
	if toolbar_ribbon != null:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_ribbon)
		toolbar_ribbon.queue_free()
		toolbar_ribbon = null
		
	# 3. Disconnect signals
	var editor_interface := get_editor_interface()
	if editor_interface != null:
		if editor_interface.has_signal("scene_changed") and editor_interface.scene_changed.is_connected(_on_editor_scene_changed):
			editor_interface.scene_changed.disconnect(_on_editor_scene_changed)
		if editor_interface.has_method("get_script_editor"):
			var se = editor_interface.get_script_editor()
			if se != null and se.has_signal("editor_script_changed") and se.editor_script_changed.is_connected(_on_script_changed):
				se.editor_script_changed.disconnect(_on_script_changed)
			
	manager = null

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
		
	var key_event := event as InputEventKey
	
	# Shortcut: Alt + S -> Toggle Scene <-> Script
	if key_event.alt_pressed and not key_event.ctrl_pressed and not key_event.shift_pressed and key_event.keycode == KEY_S:
		_trigger_toggle()
		get_viewport().set_input_as_handled()
		return
		
	# Shortcut: Alt + B -> Quick Search Palette
	if key_event.alt_pressed and not key_event.ctrl_pressed and not key_event.shift_pressed and key_event.keycode == KEY_B:
		_trigger_quick_search()
		get_viewport().set_input_as_handled()
		return
		
	# Shortcut: Alt + Shift + P -> Pin Current File
	if key_event.alt_pressed and key_event.shift_pressed and key_event.keycode == KEY_P:
		_trigger_pin_current()
		get_viewport().set_input_as_handled()
		return

func _trigger_toggle() -> void:
	if manager == null:
		return
	var current_path := _get_active_file_path()
	var root_node: Node = null
	var ei := get_editor_interface()
	if ei != null and ei.has_method("get_edited_scene_root"):
		root_node = ei.get_edited_scene_root()
	manager.toggle_scene_to_script(current_path, root_node)

func _trigger_quick_search() -> void:
	if toolbar_ribbon != null:
		toolbar_ribbon._open_quick_search()

func _trigger_pin_current() -> void:
	if manager == null:
		return
	var current_path := _get_active_file_path()
	if not current_path.is_empty():
		manager.pin_file(current_path)
		if toolbar_ribbon != null:
			toolbar_ribbon.refresh_tabs()

func _get_active_file_path() -> String:
	var ei := get_editor_interface()
	if ei == null:
		return ""
		
	# Check script editor
	if ei.has_method("get_script_editor"):
		var se = ei.get_script_editor()
		if se != null and se.has_method("get_current_script"):
			var script = se.get_current_script()
			if script is Script and not script.resource_path.is_empty():
				return script.resource_path
				
	# Check edited scene
	if ei.has_method("get_edited_scene_root"):
		var root = ei.get_edited_scene_root()
		if root != null and not root.scene_file_path.is_empty():
			return root.scene_file_path
			
	return ""

func _on_editor_scene_changed(root_node: Node) -> void:
	if root_node == null or manager == null:
		return
	if not root_node.scene_file_path.is_empty():
		manager.history_tracker.record_access(root_node.scene_file_path, root_node.name)

func _connect_script_editor_signals() -> void:
	var ei := get_editor_interface()
	if ei == null or not ei.has_method("get_script_editor"):
		return
	var se = ei.get_script_editor()
	if se != null and se.has_signal("editor_script_changed"):
		se.editor_script_changed.connect(_on_script_changed)

func _on_script_changed(script: Script) -> void:
	if script == null or manager == null:
		return
	if not script.resource_path.is_empty():
		manager.history_tracker.record_access(script.resource_path, script.resource_path.get_file())
