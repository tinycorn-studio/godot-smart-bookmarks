# bundle_manager_dialog.gd
# Dialog for creating, organizing, color-tagging, and auto-grouping feature bundles.
@tool
class_name BundleManagerDialog
extends Window

signal bundles_modified

var manager: BookmarkManager = null

@onready var bundle_list: ItemList = $Margin/VBox/MainSplit/LeftPane/BundleList
@onready var bundle_name_edit: LineEdit = $Margin/VBox/MainSplit/RightPane/DetailVBox/NameHBox/NameEdit
@onready var bundle_color_picker: ColorPickerButton = $Margin/VBox/MainSplit/RightPane/DetailVBox/ColorHBox/ColorPicker
@onready var bundle_tags_edit: LineEdit = $Margin/VBox/MainSplit/RightPane/DetailVBox/TagsHBox/TagsEdit
@onready var items_tree: Tree = $Margin/VBox/MainSplit/RightPane/ItemsVBox/ItemsTree

@onready var add_bundle_btn: Button = $Margin/VBox/MainSplit/LeftPane/BundleButtons/AddBundleBtn
@onready var delete_bundle_btn: Button = $Margin/VBox/MainSplit/LeftPane/BundleButtons/DeleteBundleBtn

@onready var add_file_btn: Button = $Margin/VBox/MainSplit/RightPane/ItemsVBox/ItemActions/AddFileBtn
@onready var remove_file_btn: Button = $Margin/VBox/MainSplit/RightPane/ItemsVBox/ItemActions/RemoveFileBtn
@onready var move_up_btn: Button = $Margin/VBox/MainSplit/RightPane/ItemsVBox/ItemActions/MoveUpBtn
@onready var move_down_btn: Button = $Margin/VBox/MainSplit/RightPane/ItemsVBox/ItemActions/MoveDownBtn

@onready var auto_group_stem_edit: LineEdit = $Margin/VBox/AutoGroupSection/AutoGroupHBox/StemEdit
@onready var auto_group_btn: Button = $Margin/VBox/AutoGroupSection/AutoGroupHBox/AutoGroupBtn

@onready var save_close_btn: Button = $Margin/VBox/FooterHBox/SaveCloseBtn
@onready var export_json_btn: Button = $Margin/VBox/FooterHBox/ExportJsonBtn
@onready var import_json_btn: Button = $Margin/VBox/FooterHBox/ImportJsonBtn

var selected_bundle: BookmarkBundle = null

func _ready() -> void:
	title = "Smart Bookmarks - Manage Feature Bundles"
	close_requested.connect(_on_close_requested)
	
	if add_bundle_btn != null:
		add_bundle_btn.pressed.connect(_on_add_bundle_pressed)
	if delete_bundle_btn != null:
		delete_bundle_btn.pressed.connect(_on_delete_bundle_pressed)
	if bundle_list != null:
		bundle_list.item_selected.connect(_on_bundle_item_selected)
		
	if bundle_name_edit != null:
		bundle_name_edit.text_changed.connect(_on_bundle_name_changed)
	if bundle_color_picker != null:
		bundle_color_picker.color_changed.connect(_on_bundle_color_changed)
	if bundle_tags_edit != null:
		bundle_tags_edit.text_changed.connect(_on_bundle_tags_changed)
		
	if add_file_btn != null:
		add_file_btn.pressed.connect(_on_add_file_pressed)
	if remove_file_btn != null:
		remove_file_btn.pressed.connect(_on_remove_file_pressed)
	if move_up_btn != null:
		move_up_btn.pressed.connect(_on_move_up_pressed)
	if move_down_btn != null:
		move_down_btn.pressed.connect(_on_move_down_pressed)
		
	if auto_group_btn != null:
		auto_group_btn.pressed.connect(_on_auto_group_pressed)
		
	if save_close_btn != null:
		save_close_btn.pressed.connect(_on_save_close_pressed)
	if export_json_btn != null:
		export_json_btn.pressed.connect(_on_export_json_pressed)
	if import_json_btn != null:
		import_json_btn.pressed.connect(_on_import_json_pressed)

func setup(p_manager: BookmarkManager) -> void:
	manager = p_manager
	refresh_bundles_list()

func refresh_bundles_list() -> void:
	if manager == null or bundle_list == null:
		return
		
	bundle_list.clear()
	var bundles := manager.get_all_bundles()
	for i in range(bundles.size()):
		var b := bundles[i]
		var text := "%s (%d files)" % [b.name, b.items.size()]
		bundle_list.add_item(text)
		
	if not bundles.is_empty():
		var select_idx: int = 0
		if selected_bundle != null:
			for i in range(bundles.size()):
				if bundles[i].id == selected_bundle.id:
					select_idx = i
					break
		bundle_list.select(select_idx)
		_on_bundle_item_selected(select_idx)
	else:
		selected_bundle = null
		_clear_details()

func _on_bundle_item_selected(index: int) -> void:
	if manager == null:
		return
	var bundles := manager.get_all_bundles()
	if index < 0 or index >= bundles.size():
		return
		
	selected_bundle = bundles[index]
	_load_bundle_details(selected_bundle)

func _load_bundle_details(bundle: BookmarkBundle) -> void:
	if bundle == null:
		return
		
	if bundle_name_edit != null:
		bundle_name_edit.text = bundle.name
	if bundle_color_picker != null:
		bundle_color_picker.color = bundle.color_tag
	if bundle_tags_edit != null:
		bundle_tags_edit.text = ", ".join(bundle.tags)
		
	_refresh_items_tree()

func _refresh_items_tree() -> void:
	if items_tree == null or selected_bundle == null:
		return
		
	items_tree.clear()
	var root := items_tree.create_item()
	items_tree.hide_root = true
	
	for item in selected_bundle.items:
		var tree_item := items_tree.create_item(root)
		tree_item.set_text(0, item.title)
		tree_item.set_text(1, item.path)
		tree_item.set_text(2, item.resource_type)
		tree_item.set_metadata(0, item.path)

func _clear_details() -> void:
	if bundle_name_edit != null:
		bundle_name_edit.text = ""
	if bundle_tags_edit != null:
		bundle_tags_edit.text = ""
	if items_tree != null:
		items_tree.clear()

func _on_bundle_name_changed(new_name: String) -> void:
	if selected_bundle != null and not new_name.strip_edges().is_empty():
		selected_bundle.name = new_name.strip_edges()
		if bundle_list != null and bundle_list.is_anything_selected():
			var idx := bundle_list.get_selected_items()[0]
			bundle_list.set_item_text(idx, "%s (%d files)" % [selected_bundle.name, selected_bundle.items.size()])
		bundles_modified.emit()

func _on_bundle_color_changed(color: Color) -> void:
	if selected_bundle != null:
		selected_bundle.color_tag = color
		bundles_modified.emit()

func _on_bundle_tags_changed(text: String) -> void:
	if selected_bundle != null:
		var raw_tags := text.split(",")
		var clean_tags: PackedStringArray = []
		for t in raw_tags:
			var s := t.strip_edges()
			if not s.is_empty():
				clean_tags.append(s)
		selected_bundle.tags = clean_tags
		bundles_modified.emit()

func _on_add_bundle_pressed() -> void:
	if manager == null:
		return
	var new_b := manager.create_bundle("New Feature Bundle", Color(0.35, 0.7, 0.95, 1.0))
	selected_bundle = new_b
	refresh_bundles_list()
	bundles_modified.emit()

func _on_delete_bundle_pressed() -> void:
	if manager == null or selected_bundle == null:
		return
	if manager.get_all_bundles().size() <= 1:
		return
	manager.remove_bundle(selected_bundle.id)
	selected_bundle = null
	refresh_bundles_list()
	bundles_modified.emit()

func _on_add_file_pressed() -> void:
	if selected_bundle == null:
		return
	# Add a default placeholder or quick item
	var path := "res://new_script.gd"
	selected_bundle.add_path(path)
	_refresh_items_tree()
	if bundle_list != null and bundle_list.is_anything_selected():
		var idx := bundle_list.get_selected_items()[0]
		bundle_list.set_item_text(idx, "%s (%d files)" % [selected_bundle.name, selected_bundle.items.size()])
	bundles_modified.emit()

func _on_remove_file_pressed() -> void:
	if items_tree == null or selected_bundle == null:
		return
	var selected_item := items_tree.get_selected()
	if selected_item == null:
		return
	var path: String = str(selected_item.get_metadata(0))
	selected_bundle.remove_item_by_path(path)
	_refresh_items_tree()
	if bundle_list != null and bundle_list.is_anything_selected():
		var idx := bundle_list.get_selected_items()[0]
		bundle_list.set_item_text(idx, "%s (%d files)" % [selected_bundle.name, selected_bundle.items.size()])
	bundles_modified.emit()

func _on_move_up_pressed() -> void:
	if items_tree == null or selected_bundle == null:
		return
	var selected_item := items_tree.get_selected()
	if selected_item == null:
		return
	var path: String = str(selected_item.get_metadata(0))
	for i in range(selected_bundle.items.size()):
		if selected_bundle.items[i].path == path:
			selected_bundle.move_item_up(i)
			break
	_refresh_items_tree()
	bundles_modified.emit()

func _on_move_down_pressed() -> void:
	if items_tree == null or selected_bundle == null:
		return
	var selected_item := items_tree.get_selected()
	if selected_item == null:
		return
	var path: String = str(selected_item.get_metadata(0))
	for i in range(selected_bundle.items.size()):
		if selected_bundle.items[i].path == path:
			selected_bundle.move_item_down(i)
			break
	_refresh_items_tree()
	bundles_modified.emit()

func _on_auto_group_pressed() -> void:
	if manager == null or auto_group_stem_edit == null:
		return
	var stem := auto_group_stem_edit.text.strip_edges()
	if stem.is_empty():
		return
	var created_bundle := manager.auto_group_files_from_stem(stem)
	selected_bundle = created_bundle
	refresh_bundles_list()
	bundles_modified.emit()

func _on_export_json_pressed() -> void:
	if manager == null:
		return
	var json_str := BookmarkStorage.export_bundles_json(manager.get_all_bundles())
	DisplayServer.clipboard_set(json_str)

func _on_import_json_pressed() -> void:
	if manager == null:
		return
	var clip := DisplayServer.clipboard_get()
	var imported_bundles := BookmarkStorage.import_bundles_json(clip)
	if not imported_bundles.is_empty():
		for b in imported_bundles:
			manager.bundles.append(b)
		refresh_bundles_list()
		bundles_modified.emit()

func _on_save_close_pressed() -> void:
	if manager != null:
		manager.save_all()
	hide()

func _on_close_requested() -> void:
	if manager != null:
		manager.save_all()
	hide()
