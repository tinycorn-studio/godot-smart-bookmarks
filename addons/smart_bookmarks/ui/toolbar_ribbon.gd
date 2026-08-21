# toolbar_ribbon.gd
# Main toolbar ribbon injected into Godot Editor's CONTAINER_TOOLBAR.
@tool
class_name ToolbarRibbon
extends HBoxContainer

signal file_clicked(path: String)
signal toggle_requested

var manager: BookmarkManager = null
var editor_interface: Object = null

@onready var bundle_selector: OptionButton = $BundleSelector
@onready var tabs_scroll: ScrollContainer = $TabsScroll
@onready var tabs_container: HBoxContainer = $TabsScroll/TabsContainer
@onready var pin_current_btn: Button = $PinCurrentBtn
@onready var toggle_btn: Button = $ToggleBtn
@onready var recent_menu_btn: MenuButton = $RecentMenuBtn
@onready var search_btn: Button = $SearchBtn
@onready var manage_btn: Button = $ManageBtn

var bundle_manager_dlg: BundleManagerDialog = null
var quick_search_pal: QuickSearchPalette = null

const TAB_ITEM_SCENE: PackedScene = preload("ribbon_tab_item.tscn")

func _ready() -> void:
	if bundle_selector != null:
		bundle_selector.item_selected.connect(_on_bundle_selected)
	if pin_current_btn != null:
		pin_current_btn.pressed.connect(_on_pin_current_pressed)
	if toggle_btn != null:
		toggle_btn.pressed.connect(_on_toggle_pressed)
	if search_btn != null:
		search_btn.pressed.connect(_on_search_pressed)
	if manage_btn != null:
		manage_btn.pressed.connect(_on_manage_pressed)
	if recent_menu_btn != null:
		var popup := recent_menu_btn.get_popup()
		popup.id_pressed.connect(_on_recent_menu_id_pressed)
		recent_menu_btn.about_to_popup.connect(_on_recent_menu_about_to_popup)

func setup(p_manager: BookmarkManager, p_editor_interface: Object = null) -> void:
	manager = p_manager
	editor_interface = p_editor_interface
	
	if manager != null:
		if not manager.bundle_list_changed.is_connected(_refresh_bundle_selector):
			manager.bundle_list_changed.connect(_refresh_bundle_selector)
		if not manager.active_bundle_changed.is_connected(_on_active_bundle_changed):
			manager.active_bundle_changed.connect(_on_active_bundle_changed)
		if not manager.bookmarks_updated.is_connected(refresh_tabs):
			manager.bookmarks_updated.connect(refresh_tabs)
		if not manager.history_updated.is_connected(_refresh_recent_menu):
			manager.history_updated.connect(_refresh_recent_menu)
			
	_refresh_bundle_selector()
	refresh_tabs()
	_refresh_recent_menu()

func _refresh_bundle_selector() -> void:
	if bundle_selector == null or manager == null:
		return
		
	bundle_selector.clear()
	var bundles := manager.get_all_bundles()
	var active_b := manager.get_active_bundle()
	var active_idx: int = 0
	
	for i in range(bundles.size()):
		var b := bundles[i]
		bundle_selector.add_item("📦 " + b.name, i)
		if active_b != null and b.id == active_b.id:
			active_idx = i
			
	bundle_selector.add_separator()
	bundle_selector.add_item("+ Manage Bundles...", 900)
	
	if not bundles.is_empty():
		bundle_selector.select(active_idx)

func _on_bundle_selected(index: int) -> void:
	if manager == null or bundle_selector == null:
		return
	var item_id := bundle_selector.get_item_id(index)
	if item_id == 900:
		_open_bundle_manager()
		_refresh_bundle_selector()
		return
		
	var bundles := manager.get_all_bundles()
	if item_id >= 0 and item_id < bundles.size():
		manager.set_active_bundle(bundles[item_id].id)

func _on_active_bundle_changed(_bundle: BookmarkBundle) -> void:
	_refresh_bundle_selector()
	refresh_tabs()

func refresh_tabs() -> void:
	if tabs_container == null or manager == null:
		return
		
	# Clear existing tab nodes
	for child in tabs_container.get_children():
		child.queue_free()
		
	var active_b := manager.get_active_bundle()
	if active_b == null:
		return
		
	for item in active_b.items:
		var tab_instance: RibbonTabItem = TAB_ITEM_SCENE.instantiate() as RibbonTabItem
		tab_instance.set_bookmark_item(item)
		tab_instance.tab_clicked.connect(_on_tab_item_clicked)
		tab_instance.unpin_requested.connect(_on_tab_unpin_requested)
		tab_instance.context_action_triggered.connect(_on_tab_context_action)
		tabs_container.add_child(tab_instance)

func _on_tab_item_clicked(item: BookmarkItem) -> void:
	if item == null or manager == null:
		return
	file_clicked.emit(item.path)
	manager.open_file(item.path, item.title)

func _on_tab_unpin_requested(item: BookmarkItem) -> void:
	if item == null or manager == null:
		return
	manager.unpin_file(item.path)
	refresh_tabs()

func _on_tab_context_action(action: String, item: BookmarkItem) -> void:
	if action == "toggle_scene_script":
		if manager != null and item != null:
			manager.toggle_scene_to_script(item.path)
	elif action == "color_changed":
		if manager != null:
			manager.save_all()

func _on_pin_current_pressed() -> void:
	if manager == null:
		return
		
	var current_path := _get_current_active_path()
	if not current_path.is_empty():
		manager.pin_file(current_path)
		refresh_tabs()

func _on_toggle_pressed() -> void:
	toggle_requested.emit()
	if manager == null:
		return
	var current_path := _get_current_active_path()
	manager.toggle_scene_to_script(current_path)

func _get_current_active_path() -> String:
	if editor_interface != null:
		# Editor context
		if editor_interface.has_method("get_current_path"):
			var p = editor_interface.get_current_path()
			if not str(p).is_empty():
				return str(p)
		if editor_interface.has_method("get_edited_scene_root"):
			var root = editor_interface.get_edited_scene_root()
			if root != null and not root.scene_file_path.is_empty():
				return root.scene_file_path
	if manager != null:
		var history := manager.history_tracker.get_entries()
		if not history.is_empty():
			return history[0].path
	return ""

func _on_search_pressed() -> void:
	_open_quick_search()

func _on_manage_pressed() -> void:
	_open_bundle_manager()

func _open_bundle_manager() -> void:
	if bundle_manager_dlg == null:
		var scene: PackedScene = preload("bundle_manager_dialog.tscn")
		if scene != null:
			bundle_manager_dlg = scene.instantiate() as BundleManagerDialog
			add_child(bundle_manager_dlg)
			bundle_manager_dlg.setup(manager)
			bundle_manager_dlg.bundles_modified.connect(func():
				_refresh_bundle_selector()
				refresh_tabs()
			)
			
	if bundle_manager_dlg != null:
		bundle_manager_dlg.popup_centered()
		bundle_manager_dlg.refresh_bundles_list()

func _open_quick_search() -> void:
	if quick_search_pal == null:
		var scene: PackedScene = preload("quick_search_palette.tscn")
		if scene != null:
			quick_search_pal = scene.instantiate() as QuickSearchPalette
			add_child(quick_search_pal)
			quick_search_pal.setup(manager)
			
	if quick_search_pal != null:
		quick_search_pal.open_palette()

func _refresh_recent_menu() -> void:
	if recent_menu_btn == null or manager == null:
		return
	var popup := recent_menu_btn.get_popup()
	popup.clear()
	
	var history := manager.history_tracker.get_entries()
	if history.is_empty():
		popup.add_item("(No recent files)", 999)
		popup.set_item_disabled(0, true)
		return
		
	for i in range(mini(history.size(), 20)):
		var item := history[i]
		var label := "%s  —  %s (%s)" % [item.title, item.path, item.get_relative_time_string()]
		popup.add_item(label, i)
		popup.set_item_metadata(i, item.path)
		
	popup.add_separator()
	popup.add_item("Clear Recent History", 800)

func _on_recent_menu_about_to_popup() -> void:
	_refresh_recent_menu()

func _on_recent_menu_id_pressed(id: int) -> void:
	if manager == null or recent_menu_btn == null:
		return
	if id == 800:
		manager.history_tracker.clear_history()
		_refresh_recent_menu()
		return
		
	var popup := recent_menu_btn.get_popup()
	var path_meta = popup.get_item_metadata(id)
	if path_meta != null and not str(path_meta).is_empty():
		manager.open_file(str(path_meta))
