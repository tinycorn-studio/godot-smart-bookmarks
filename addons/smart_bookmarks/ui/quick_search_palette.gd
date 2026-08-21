# quick_search_palette.gd
# Fast fuzzy search popup palette for bookmarks, recent history, and bundles.
@tool
class_name QuickSearchPalette
extends Window

signal file_selected(path: String)
signal bundle_selected(bundle_id: String)

var manager: BookmarkManager = null

@onready var search_edit: LineEdit = $Margin/VBox/SearchEdit
@onready var tab_bar: TabBar = $Margin/VBox/TabBar
@onready var results_tree: Tree = $Margin/VBox/ResultsTree
@onready var status_label: Label = $Margin/VBox/StatusLabel

var current_results: Array[Dictionary] = []
var selected_filter_mode: int = 0 # 0 = All, 1 = Bookmarks, 2 = Recent, 3 = Bundles

func _ready() -> void:
	title = "Quick Open & Search Bookmarks"
	close_requested.connect(_on_close_requested)
	
	if search_edit != null:
		search_edit.text_changed.connect(_on_search_text_changed)
		search_edit.gui_input.connect(_on_search_gui_input)
		
	if tab_bar != null:
		tab_bar.tab_changed.connect(_on_tab_changed)
		
	if results_tree != null:
		results_tree.item_activated.connect(_on_result_item_activated)
		
	about_to_popup.connect(_on_about_to_popup)

func setup(p_manager: BookmarkManager) -> void:
	manager = p_manager

func open_palette() -> void:
	popup_centered(Vector2i(600, 420))
	if search_edit != null:
		search_edit.text = ""
		search_edit.grab_focus()
	refresh_results()

func _on_about_to_popup() -> void:
	if search_edit != null:
		search_edit.text = ""
		search_edit.grab_focus()
	refresh_results()

func _on_close_requested() -> void:
	hide()

func _on_search_text_changed(_new_text: String) -> void:
	refresh_results()

func _on_tab_changed(tab_idx: int) -> void:
	selected_filter_mode = tab_idx
	refresh_results()

func _on_search_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.is_pressed():
		if event.keycode == KEY_DOWN or event.keycode == KEY_UP:
			if results_tree != null:
				results_tree.grab_focus()
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_activate_first_result()
			if search_edit != null:
				search_edit.accept_event()
		elif event.keycode == KEY_ESCAPE:
			hide()
			if search_edit != null:
				search_edit.accept_event()

func refresh_results() -> void:
	if results_tree == null or manager == null:
		return
		
	results_tree.clear()
	var root := results_tree.create_item()
	results_tree.hide_root = true
	current_results.clear()
	
	var query := search_edit.text.strip_edges() if search_edit != null else ""
	var search_data := manager.search_all(query)
	
	var bookmarks_list: Array[BookmarkItem] = search_data["bookmarks"]
	var history_list: Array[BookmarkItem] = search_data["history"]
	var bundles_list: Array[BookmarkBundle] = search_data["bundles"]
	
	# Update tab counts
	if tab_bar != null:
		var total_count := bookmarks_list.size() + history_list.size() + bundles_list.size()
		tab_bar.set_tab_title(0, "All (%d)" % total_count)
		tab_bar.set_tab_title(1, "Bookmarks (%d)" % bookmarks_list.size())
		tab_bar.set_tab_title(2, "Recent (%d)" % history_list.size())
		tab_bar.set_tab_title(3, "Bundles (%d)" % bundles_list.size())
		
	# Populate results based on active filter
	var result_items_to_show: Array[Dictionary] = []
	
	# 1. Bundles
	if selected_filter_mode == 0 or selected_filter_mode == 3:
		for b in bundles_list:
			result_items_to_show.append({
				"type": "bundle",
				"id": b.id,
				"title": "📦 " + b.name,
				"subtitle": "%d files | Tags: %s" % [b.items.size(), ", ".join(b.tags)],
				"category": "Bundle",
				"color": b.color_tag
			})
			
	# 2. Pinned Bookmarks
	if selected_filter_mode == 0 or selected_filter_mode == 1:
		for item in bookmarks_list:
			result_items_to_show.append({
				"type": "file",
				"path": item.path,
				"title": "⭐ " + item.title,
				"subtitle": item.path,
				"category": "Pinned (" + item.resource_type + ")",
				"color": item.custom_color
			})
			
	# 3. Recent History
	if selected_filter_mode == 0 or selected_filter_mode == 2:
		for item in history_list:
			# If already shown in bookmarks, skip in "All" mode to prevent duplicate rows
			var already_in: bool = false
			if selected_filter_mode == 0:
				for existing in result_items_to_show:
					if existing.get("path", "") == item.path:
						already_in = true
						break
			if not already_in:
				result_items_to_show.append({
					"type": "file",
					"path": item.path,
					"title": "🕒 " + item.title,
					"subtitle": "%s (%s)" % [item.path, item.get_relative_time_string()],
					"category": "Recent",
					"color": Color(0.7, 0.7, 0.7, 1.0)
				})
				
	current_results = result_items_to_show
	
	for entry in current_results:
		var tree_item := results_tree.create_item(root)
		tree_item.set_text(0, entry["title"])
		tree_item.set_text(1, entry["subtitle"])
		tree_item.set_text(2, entry["category"])
		tree_item.set_metadata(0, entry)
		
	if status_label != null:
		status_label.text = "Showing %d results" % current_results.size()
		
	if root.get_child_count() > 0:
		var first_child := root.get_child(0)
		first_child.select(0)

func _activate_first_result() -> void:
	if results_tree == null:
		return
	var selected := results_tree.get_selected()
	if selected == null:
		var root := results_tree.get_root()
		if root != null and root.get_child_count() > 0:
			selected = root.get_child(0)
	if selected != null:
		_on_result_item_activated()

func _on_result_item_activated() -> void:
	if results_tree == null:
		return
	var selected := results_tree.get_selected()
	if selected == null:
		return
		
	var data: Dictionary = selected.get_metadata(0)
	if data.is_empty():
		return
		
	var entry_type: String = data.get("type", "")
	if entry_type == "file":
		var path: String = data.get("path", "")
		file_selected.emit(path)
		if manager != null:
			manager.open_file(path)
		hide()
	elif entry_type == "bundle":
		var b_id: String = data.get("id", "")
		bundle_selected.emit(b_id)
		if manager != null:
			manager.set_active_bundle(b_id)
		hide()
