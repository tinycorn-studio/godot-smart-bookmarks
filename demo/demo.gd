# demo.gd
# Interactive standalone showcase scene for Smart Bookmarks & Quick File Switcher.
extends Control

var manager: BookmarkManager = null
var current_active_file: String = "res://demo/mock_project/player/player.tscn"
var current_mode: String = "Scene"

@onready var ribbon_host: MarginContainer = $VBox/RibbonHost
@onready var file_tree: Tree = $VBox/MainSplit/LeftPane/FileTree
@onready var active_file_label: Label = $VBox/MainSplit/CenterPane/WorkspaceHeader/ActiveFileLabel
@onready var mode_badge: Label = $VBox/MainSplit/CenterPane/WorkspaceHeader/ModeBadge
@onready var code_preview: CodeEdit = $VBox/MainSplit/CenterPane/PreviewContainer/CodePreview
@onready var scene_preview_panel: PanelContainer = $VBox/MainSplit/CenterPane/PreviewContainer/ScenePreviewPanel
@onready var scene_nodes_tree: Tree = $VBox/MainSplit/CenterPane/PreviewContainer/ScenePreviewPanel/VBox/SceneNodesTree
@onready var config_text_view: TextEdit = $VBox/MainSplit/RightPane/ConfigSection/ConfigTextView
@onready var history_item_list: ItemList = $VBox/MainSplit/RightPane/HistorySection/HistoryItemList
@onready var event_log_text: RichTextLabel = $VBox/MainSplit/RightPane/LogSection/EventLog
@onready var test_results_label: Label = $VBox/MainSplit/RightPane/TestSection/TestResultsLabel

# Action buttons
@onready var toggle_btn: Button = $VBox/MainSplit/CenterPane/ActionHBox/ToggleBtn
@onready var search_btn: Button = $VBox/MainSplit/CenterPane/ActionHBox/SearchBtn
@onready var pin_btn: Button = $VBox/MainSplit/CenterPane/ActionHBox/PinBtn
@onready var run_tests_btn: Button = $VBox/MainSplit/RightPane/TestSection/RunTestsBtn

var TOOLBAR_RIBBON_SCENE: PackedScene = load("res://addons/smart_bookmarks/ui/toolbar_ribbon.tscn") if ResourceLoader.exists("res://addons/smart_bookmarks/ui/toolbar_ribbon.tscn") else load("res://addons/smart_bookmarks/ui/toolbar_ribbon.tscn")
var toolbar_ribbon_instance: ToolbarRibbon = null

func _ready() -> void:
	_log_event("🚀 Initializing Smart Bookmarks Demo...")
	
	# 1. Initialize BookmarkManager with isolated paths for demo
	manager = BookmarkManager.new()
	var demo_proj_cfg := "user://demo_smart_bookmarks.cfg"
	var demo_user_cfg := "user://demo_smart_bookmarks_user.cfg"
	manager.initialize(null, demo_proj_cfg, demo_user_cfg)
	
	# 2. Populate starter demo bundles if newly initialized
	_populate_demo_bundles_if_needed()
	
	# 3. Instantiate and attach ToolbarRibbon
	if TOOLBAR_RIBBON_SCENE != null:
		toolbar_ribbon_instance = TOOLBAR_RIBBON_SCENE.instantiate() as ToolbarRibbon
		ribbon_host.add_child(toolbar_ribbon_instance)
		toolbar_ribbon_instance.setup(manager, null)
		toolbar_ribbon_instance.file_clicked.connect(_on_ribbon_file_clicked)
		
	# 4. Connect manager signals
	manager.file_open_requested.connect(_on_file_open_requested)
	manager.bookmarks_updated.connect(_update_diagnostics)
	manager.history_updated.connect(_update_diagnostics)
	manager.bundle_list_changed.connect(_update_diagnostics)
	
	# 5. Setup UI buttons
	if toggle_btn != null:
		toggle_btn.pressed.connect(_on_toggle_pressed)
	if search_btn != null:
		search_btn.pressed.connect(_on_search_pressed)
	if pin_btn != null:
		pin_btn.pressed.connect(_on_pin_pressed)
	if run_tests_btn != null:
		run_tests_btn.pressed.connect(_run_self_tests)
		
	# 6. Build file tree and open initial file
	_build_mock_file_tree()
	_open_file_in_workspace(current_active_file)
	_update_diagnostics()
	
	_log_event("✅ Demo ready. Press Alt+S to toggle between Scene and Script!")

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.is_pressed() or event.is_echo():
		return
	var key_event := event as InputEventKey
	if key_event.alt_pressed and key_event.keycode == KEY_S:
		_on_toggle_pressed()
		get_viewport().set_input_as_handled()
	elif key_event.alt_pressed and key_event.keycode == KEY_B:
		_on_search_pressed()
		get_viewport().set_input_as_handled()

func _populate_demo_bundles_if_needed() -> void:
	if manager.get_all_bundles().size() <= 1 and manager.get_all_bundles()[0].items.is_empty():
		manager.bundles.clear()
		
		# Bundle 1: Player
		var b_player := BookmarkBundle.new("bundle_player", "Player Feature", Color(0.3, 0.65, 0.95, 1.0))
		b_player.tags = ["Gameplay", "Character"]
		b_player.add_path("res://demo/mock_project/player/player.tscn", "player.tscn")
		b_player.add_path("res://demo/mock_project/player/player.gd", "player.gd")
		b_player.add_path("res://demo/mock_project/player/player_data.tres", "player_data.tres")
		manager.bundles.append(b_player)
		
		# Bundle 2: Enemies
		var b_enemy := BookmarkBundle.new("bundle_enemy", "Enemy Boss", Color(0.9, 0.4, 0.4, 1.0))
		b_enemy.tags = ["Boss", "Combat"]
		b_enemy.add_path("res://demo/mock_project/enemies/enemy_boss.tscn", "enemy_boss.tscn")
		b_enemy.add_path("res://demo/mock_project/enemies/enemy_boss.gd", "enemy_boss.gd")
		b_enemy.add_path("res://demo/mock_project/enemies/enemy_data.tres", "enemy_data.tres")
		manager.bundles.append(b_enemy)
		
		# Bundle 3: UI
		var b_ui := BookmarkBundle.new("bundle_ui", "HUD & Inventory", Color(0.4, 0.8, 0.5, 1.0))
		b_ui.tags = ["UI", "Inventory"]
		b_ui.add_path("res://demo/mock_project/ui/inventory.tscn", "inventory.tscn")
		b_ui.add_path("res://demo/mock_project/ui/inventory.gd", "inventory.gd")
		b_ui.add_path("res://demo/mock_project/ui/hud_theme.tres", "hud_theme.tres")
		manager.bundles.append(b_ui)
		
		manager.set_active_bundle("bundle_player")
		manager.save_all()

func _build_mock_file_tree() -> void:
	if file_tree == null:
		return
	file_tree.clear()
	var root := file_tree.create_item()
	root.set_text(0, "res://demo/mock_project")
	file_tree.hide_root = false
	
	var folders: Dictionary = {
		"player": [
			{"path": "res://demo/mock_project/player/player.tscn", "name": "player.tscn", "type": "Scene"},
			{"path": "res://demo/mock_project/player/player.gd", "name": "player.gd", "type": "Script"},
			{"path": "res://demo/mock_project/player/player_data.tres", "name": "player_data.tres", "type": "Resource"}
		],
		"enemies": [
			{"path": "res://demo/mock_project/enemies/enemy_boss.tscn", "name": "enemy_boss.tscn", "type": "Scene"},
			{"path": "res://demo/mock_project/enemies/enemy_boss.gd", "name": "enemy_boss.gd", "type": "Script"},
			{"path": "res://demo/mock_project/enemies/enemy_data.tres", "name": "enemy_data.tres", "type": "Resource"}
		],
		"ui": [
			{"path": "res://demo/mock_project/ui/inventory.tscn", "name": "inventory.tscn", "type": "Scene"},
			{"path": "res://demo/mock_project/ui/inventory.gd", "name": "inventory.gd", "type": "Script"},
			{"path": "res://demo/mock_project/ui/hud_theme.tres", "name": "hud_theme.tres", "type": "Theme"}
		]
	}
	
	for folder_name in folders:
		var folder_item := file_tree.create_item(root)
		folder_item.set_text(0, "📁 " + folder_name)
		for f in folders[folder_name]:
			var item := file_tree.create_item(folder_item)
			var icon_prefix := "🎬 " if f["type"] == "Scene" else ("📜 " if f["type"] == "Script" else "💎 ")
			item.set_text(0, icon_prefix + f["name"])
			item.set_metadata(0, f["path"])
			
	file_tree.item_activated.connect(func():
		var sel := file_tree.get_selected()
		if sel != null:
			var path = sel.get_metadata(0)
			if path != null and not str(path).is_empty():
				_open_file_in_workspace(str(path))
	)

func _open_file_in_workspace(path: String) -> void:
	current_active_file = path
	var ext := path.get_extension().to_lower()
	
	if active_file_label != null:
		active_file_label.text = path
		
	if ext in ["tscn", "scn"]:
		current_mode = "Scene"
		if mode_badge != null:
			mode_badge.text = "MODE: SCENE VIEW (2D/3D)"
			mode_badge.modulate = Color(0.4, 0.8, 1.0)
		_show_scene_preview(path)
	elif ext in ["gd", "cs", "gdshader"]:
		current_mode = "Script"
		if mode_badge != null:
			mode_badge.text = "MODE: SCRIPT EDITOR"
			mode_badge.modulate = Color(1.0, 0.85, 0.4)
		_show_script_preview(path)
	else:
		current_mode = "Resource"
		if mode_badge != null:
			mode_badge.text = "MODE: RESOURCE INSPECTOR"
			mode_badge.modulate = Color(0.9, 0.4, 0.9)
		_show_resource_preview(path)
		
	manager.history_tracker.record_access(path, path.get_file())
	_log_event("📂 Opened: %s" % path)
	_update_diagnostics()

func _show_script_preview(path: String) -> void:
	if code_preview != null and scene_preview_panel != null:
		code_preview.visible = true
		scene_preview_panel.visible = false
		
		if FileAccess.file_exists(path):
			var file := FileAccess.open(path, FileAccess.READ)
			if file != null:
				code_preview.text = file.get_as_text()
				file.close()
		else:
			code_preview.text = "# [Simulated Script Buffer: %s]\nextends Node\n\nfunc _ready() -> void:\n\tprint('Hello from script!')\n" % path.get_file()

func _show_scene_preview(path: String) -> void:
	if code_preview != null and scene_preview_panel != null:
		code_preview.visible = false
		scene_preview_panel.visible = true
		
		if scene_nodes_tree != null:
			scene_nodes_tree.clear()
			var root := scene_nodes_tree.create_item()
			root.set_text(0, "🎬 " + path.get_file().get_basename() + " (Root Node)")
			
			var child1 := scene_nodes_tree.create_item(root)
			child1.set_text(0, "  ▫ CollisionShape2D")
			var child2 := scene_nodes_tree.create_item(root)
			child2.set_text(0, "  ▫ Sprite2D")
			var child3 := scene_nodes_tree.create_item(root)
			child3.set_text(0, "  ▫ AnimationPlayer")

func _show_resource_preview(path: String) -> void:
	if code_preview != null and scene_preview_panel != null:
		code_preview.visible = true
		scene_preview_panel.visible = false
		code_preview.text = "# [Resource Inspector: %s]\n{\n  'resource_path': '%s',\n  'type': 'Resource'\n}\n" % [path.get_file(), path]

func _on_ribbon_file_clicked(path: String) -> void:
	_open_file_in_workspace(path)

func _on_file_open_requested(path: String, _type: String) -> void:
	_open_file_in_workspace(path)

func _on_toggle_pressed() -> void:
	_log_event("🔄 Fast Scene <-> Script Toggle (Alt+S) Triggered!")
	var result := SceneScriptSwitcher.execute_toggle(current_active_file, null, null)
	if result["success"] and not str(result["target_path"]).is_empty():
		_open_file_in_workspace(result["target_path"])
		_log_event("✨ %s" % result["message"])
	else:
		_log_event("⚠️ %s" % result["message"])

func _on_search_pressed() -> void:
	_log_event("🔍 Quick Search Palette (Alt+B) Opened")
	if toolbar_ribbon_instance != null:
		toolbar_ribbon_instance._open_quick_search()

func _on_pin_pressed() -> void:
	var added := manager.pin_file(current_active_file)
	if added:
		_log_event("⭐ Pinned '%s' to active bundle '%s'" % [current_active_file.get_file(), manager.get_active_bundle().name])
		if toolbar_ribbon_instance != null:
			toolbar_ribbon_instance.refresh_tabs()
	else:
		_log_event("ℹ️ File already pinned in this bundle.")

func _update_diagnostics() -> void:
	# 1. Update Recent History item list
	if history_item_list != null and manager != null:
		history_item_list.clear()
		var entries := manager.history_tracker.get_entries()
		for item in entries:
			var label := "%s (%s) - %s" % [item.title, item.resource_type, item.get_relative_time_string()]
			history_item_list.add_item(label)
			
	# 2. Update Config raw view
	if config_text_view != null and manager != null:
		var cfg := ConfigFile.new()
		for bundle in manager.bundles:
			var sec := "bundle." + bundle.id
			cfg.set_value(sec, "name", bundle.name)
			cfg.set_value(sec, "color", bundle.color_tag.to_html(false))
			cfg.set_value(sec, "tags", bundle.tags)
			var paths: Array[String] = []
			for item in bundle.items:
				paths.append(item.path)
			cfg.set_value(sec, "items", paths)
		config_text_view.text = cfg.encode_to_text()

func _log_event(msg: String) -> void:
	var timestamp := Time.get_time_string_from_system()
	if event_log_text != null:
		event_log_text.append_text("[%s] %s\n" % [timestamp, msg])

func _run_self_tests() -> void:
	_log_event("🧪 Running Automated Self-Tests...")
	var passed: int = 0
	var total: int = 6
	
	# Test 1: Item Serialization
	var item1 := BookmarkItem.new("res://player.gd", "player.gd")
	var dict := item1.to_dict()
	var item2 := BookmarkItem.from_dict(dict)
	if item2.path == item1.path and item2.resource_type == "GDScript":
		passed += 1
		
	# Test 2: Bundle Add & Remove
	var bundle := BookmarkBundle.new("test_bundle", "Test")
	bundle.add_path("res://scene1.tscn")
	bundle.add_path("res://scene1.tscn") # Duplicate
	if bundle.items.size() == 1:
		bundle.remove_item_by_path("res://scene1.tscn")
		if bundle.items.is_empty():
			passed += 1
			
	# Test 3: Scene Script Switcher Heuristics
	var target_script := SceneScriptSwitcher.resolve_script_from_scene("res://demo/mock_project/player/player.tscn")
	var target_scene := SceneScriptSwitcher.resolve_scene_from_script("res://demo/mock_project/player/player.gd")
	if target_script.ends_with("player.gd") and target_scene.ends_with("player.tscn"):
		passed += 1
		
	# Test 4: Recent History LRU capacity & order
	var tracker := RecentHistoryTracker.new(3)
	tracker.record_access("res://a.gd")
	tracker.record_access("res://b.gd")
	tracker.record_access("res://c.gd")
	tracker.record_access("res://d.gd")
	if tracker.get_entry_count() == 3 and tracker.get_entries()[0].path == "res://d.gd":
		passed += 1
		
	# Test 5: Storage Roundtrip
	var test_bundles: Array[BookmarkBundle] = [BookmarkBundle.new("b1", "B1")]
	test_bundles[0].add_path("res://test.tscn")
	var save_err := BookmarkStorage.save_project_bundles(test_bundles, "user://test_save.cfg")
	var loaded := BookmarkStorage.load_project_bundles("user://test_save.cfg")
	if save_err == OK and loaded.size() >= 1 and loaded[0].items.size() >= 1:
		passed += 1
		
	# Test 6: Smart Auto-Grouping
	var auto_b := manager.auto_group_files_from_stem("player", "Player Group", ["res://demo/mock_project/player"])
	if auto_b != null and auto_b.items.size() >= 2:
		passed += 1
		
	if test_results_label != null:
		test_results_label.text = "Self-Tests: %d / %d PASSED" % [passed, total]
		if passed == total:
			test_results_label.modulate = Color(0.3, 0.9, 0.3)
			_log_event("🎉 ALL %d SELF-TESTS PASSED SUCCESSFULLY!" % total)
		else:
			test_results_label.modulate = Color(0.9, 0.3, 0.3)
			_log_event("❌ Self-tests failed (%d/%d)" % [passed, total])
