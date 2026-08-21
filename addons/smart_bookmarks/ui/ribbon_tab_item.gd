# ribbon_tab_item.gd
# Individual interactive bookmark tab rendered in the Smart Bookmarks toolbar ribbon.
@tool
class_name RibbonTabItem
extends PanelContainer

signal tab_clicked(item: BookmarkItem)
signal unpin_requested(item: BookmarkItem)
signal context_action_triggered(action: String, item: BookmarkItem)

var item: BookmarkItem = null

@onready var icon_rect: TextureRect = $HBox/IconRect
@onready var title_label: Label = $HBox/TitleLabel
@onready var close_button: Button = $HBox/CloseButton
@onready var color_tag_bar: ColorRect = $ColorTagBar
@onready var context_menu: PopupMenu = $ContextMenu

var is_hovered: bool = false
var normal_style: StyleBoxFlat
var hover_style: StyleBoxFlat

func _ready() -> void:
	_setup_styles()
	_setup_context_menu()
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	close_button.pressed.connect(_on_close_button_pressed)
	
	if item != null:
		update_ui()

func set_bookmark_item(p_item: BookmarkItem) -> void:
	item = p_item
	if is_inside_tree():
		update_ui()

func update_ui() -> void:
	if item == null:
		return
		
	if title_label != null:
		title_label.text = item.title
		
	tooltip_text = "%s\nPath: %s\nType: %s\nLast opened: %s" % [
		item.title,
		item.path,
		item.resource_type,
		item.get_relative_time_string()
	]
	
	if color_tag_bar != null:
		color_tag_bar.color = item.custom_color
		color_tag_bar.visible = (item.custom_color != Color.WHITE and item.custom_color.a > 0.0)
		
	if icon_rect != null:
		_load_icon()

func _load_icon() -> void:
	var icon_path := "res://addons/smart_bookmarks/icons/"
	var icon_file := "file_generic.svg"
	
	match item.resource_type:
		"PackedScene":
			icon_file = "file_scene.svg"
		"GDScript", "CSharpScript":
			icon_file = "file_script.svg"
		"Resource", "Material", "Shader":
			icon_file = "file_resource.svg"
		_:
			icon_file = "file_generic.svg"
			
	var full_icon_path := icon_path + icon_file
	if ResourceLoader.exists(full_icon_path):
		var tex = load(full_icon_path)
		if tex is Texture2D:
			icon_rect.texture = tex

func _setup_styles() -> void:
	normal_style = StyleBoxFlat.new()
	normal_style.bg_color = Color(0.18, 0.20, 0.24, 0.7)
	normal_style.set_corner_radius_all(4)
	normal_style.border_color = Color(0.3, 0.35, 0.42, 0.6)
	normal_style.set_border_width_all(1)
	normal_style.content_margin_left = 6
	normal_style.content_margin_right = 4
	normal_style.content_margin_top = 2
	normal_style.content_margin_bottom = 2
	
	hover_style = StyleBoxFlat.new()
	hover_style.bg_color = Color(0.25, 0.28, 0.35, 0.9)
	hover_style.set_corner_radius_all(4)
	hover_style.border_color = Color(0.45, 0.65, 0.95, 0.9)
	hover_style.set_border_width_all(1)
	hover_style.content_margin_left = 6
	hover_style.content_margin_right = 4
	hover_style.content_margin_top = 2
	hover_style.content_margin_bottom = 2
	
	add_theme_stylebox_override("panel", normal_style)

func _setup_context_menu() -> void:
	if context_menu == null:
		return
	context_menu.clear()
	context_menu.add_item("Open File", 1)
	context_menu.add_item("Scene <-> Script Toggle (Alt+S)", 2)
	context_menu.add_separator()
	context_menu.add_item("Copy Path to Clipboard", 3)
	context_menu.add_separator()
	context_menu.add_item("Set Color: Blue", 10)
	context_menu.add_item("Set Color: Green", 11)
	context_menu.add_item("Set Color: Red", 12)
	context_menu.add_item("Set Color: Yellow", 13)
	context_menu.add_item("Clear Color Tag", 14)
	context_menu.add_separator()
	context_menu.add_item("Remove from Bundle (Unpin)", 99)
	
	context_menu.id_pressed.connect(_on_context_menu_id_pressed)

func _on_mouse_entered() -> void:
	is_hovered = true
	add_theme_stylebox_override("panel", hover_style)
	if close_button != null:
		close_button.modulate = Color(1.0, 1.0, 1.0, 0.8)

func _on_mouse_exited() -> void:
	is_hovered = false
	add_theme_stylebox_override("panel", normal_style)
	if close_button != null:
		close_button.modulate = Color(1.0, 1.0, 1.0, 0.3)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.is_pressed():
		if event.button_index == MOUSE_BUTTON_LEFT:
			tab_clicked.emit(item)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if context_menu != null:
				context_menu.position = Vector2i(get_global_mouse_position())
				context_menu.popup()
			accept_event()

func _on_close_button_pressed() -> void:
	unpin_requested.emit(item)

func _on_context_menu_id_pressed(id: int) -> void:
	match id:
		1:
			tab_clicked.emit(item)
		2:
			context_action_triggered.emit("toggle_scene_script", item)
		3:
			DisplayServer.clipboard_set(item.path)
			context_action_triggered.emit("copied_path", item)
		10:
			item.custom_color = Color(0.3, 0.65, 0.95, 1.0)
			update_ui()
			context_action_triggered.emit("color_changed", item)
		11:
			item.custom_color = Color(0.4, 0.8, 0.4, 1.0)
			update_ui()
			context_action_triggered.emit("color_changed", item)
		12:
			item.custom_color = Color(0.9, 0.35, 0.35, 1.0)
			update_ui()
			context_action_triggered.emit("color_changed", item)
		13:
			item.custom_color = Color(0.95, 0.8, 0.3, 1.0)
			update_ui()
			context_action_triggered.emit("color_changed", item)
		14:
			item.custom_color = Color(1.0, 1.0, 1.0, 1.0)
			update_ui()
			context_action_triggered.emit("color_changed", item)
		99:
			unpin_requested.emit(item)
