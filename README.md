# Smart Bookmarks & Quick File Switcher for Godot 4

[![Godot Engine](https://img.shields.io/badge/Godot-4.x-478cbf?logo=godotengine&logoColor=white)](https://godotengine.org)
[![Language](https://img.shields.io/badge/Language-GDScript%204%20(Static%20Typing)-478cbf)](#)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](#)
[![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)](#)

> **Supercharge your Godot 4 editor workflow**: Eliminate navigation friction in large game projects with a visual toolbar ribbon, logical feature bundles, instantaneous bidirectional scene-to-script toggling, and fast recent file history.

---

## 🌟 Key Features

### 1. Visual Toolbar Bookmark Ribbon (`CONTAINER_TOOLBAR`)
- **Pinned Tabs**: Keep your most frequently accessed scenes, scripts, and resources pinned right in the Godot top toolbar.
- **Resource Type Icons**: Automatic icon badges for scenes (`.tscn`, `.scn`), scripts (`.gd`, `.cs`, `.gdshader`), resources (`.tres`, `.res`), textures, and data files.
- **Custom Color Tagging**: Assign visual color accents (Blue, Green, Red, Yellow) to distinguish gameplay systems at a glance.
- **Right-Click Context Menu**: Quick access to "Open File", "Fast Toggle (Alt+S)", "Copy Resource Path", "Change Color Tag", and "Unpin".

### 2. Feature Grouping & Smart Bundling System
- **Logical Feature Bundles**: Group all related files for a game system under one named bundle (e.g. `Player` containing `player.tscn`, `player.gd`, `player_stats.tres`, and `player_sprite.png`).
- **One-Click Bundle Switching**: Switch your entire ribbon view between different features with a single dropdown selection.
- **⚡ Smart Auto-Grouping Heuristic**: Enter a keyword or feature stem (e.g. `player`, `enemy_boss`, `inventory`), and Smart Bookmarks scans your project to automatically bundle matching scenes, scripts, and resources.
- **JSON Export / Import**: Easily share feature bundle sets with teammates across version control.

### 3. Fast Scene-to-Script Toggle (`Alt + S`)
- **Instant Bidirectional Switching**: Press `Alt + S` or click the toolbar toggle button to jump immediately from a Scene (`.tscn`) to its attached or matching Script (`.gd`), and vice-versa!
- **Intelligent Heuristic Resolution**:
  - Checks root node attached scripts.
  - Checks selected node scripts.
  - Matches sibling files with identical stems (`res://entities/player/player.tscn` ↔ `res://entities/player/player.gd`).
  - Resolves mirror directory structures (`res://scenes/player.tscn` ↔ `res://scripts/player.gd`).

### 4. Recent File Access History (LRU Ring Buffer)
- **Automatic History Tracking**: Tracks the last 30 opened scenes and scripts.
- **Smart Recency & Frequency**: Records access timestamps ("2m ago", "Just now") and usage frequency.
- **Toolbar Dropdown**: Instant 1-click jump to any recently touched file without browsing the FileSystem dock.

### 5. Quick Search & Open Palette (`Alt + B`)
- **Fuzzy Search Modal**: Press `Alt + B` or click `🔍` to open the Spotlight/QuickOpen search palette.
- **Multi-Category Filtering**: Instant filter tabs for `[All]`, `[Bookmarks]`, `[Recent History]`, and `[Bundles]`.
- **Keyboard Friendly**: Navigate with arrow keys, press `Enter` to open, `Esc` to dismiss.

### 6. Dual-Tier Persistence
- **Project Tier (`res://smart_bookmarks.cfg`)**: Shared bundles and team bookmarks saved in clean INI format, ready for Git version control.
- **Local User Tier (`user://smart_bookmarks_user.cfg`)**: Active bundle selection, local recent history, and UI state saved per developer.

---

## ⌨️ Default Keyboard Shortcuts

| Shortcut | Action | Description |
| :--- | :--- | :--- |
| **`Alt + S`** | **Fast Scene/Script Toggle** | Instant jump between scene view and script editor |
| **`Alt + B`** | **Quick Search Palette** | Opens fuzzy search modal for bookmarks, history, and bundles |
| **`Alt + Shift + P`** | **Pin Current File** | Pins the active scene or script to current feature bundle |

---

## 📁 Package Architecture & Directory Map

```
packages/smart_bookmarks/
├── addons/
│   └── smart_bookmarks/
│       ├── plugin.cfg                         # Godot 4 EditorPlugin manifest
│       ├── smart_bookmarks.gd                 # Main EditorPlugin entry point (@tool)
│       ├── icons/                             # Crisp SVG vector icons
│       │   ├── bookmark_icon.svg
│       │   ├── bundle_icon.svg
│       │   ├── toggle_scene_script.svg
│       │   ├── pin_icon.svg
│       │   ├── history_icon.svg
│       │   ├── search_icon.svg
│       │   ├── file_scene.svg
│       │   ├── file_script.svg
│       │   ├── file_resource.svg
│       │   └── file_generic.svg
│       ├── core/                              # Modular core architecture
│       │   ├── bookmark_item.gd               # Item data model & serialization
│       │   ├── bookmark_bundle.gd             # Feature bundle collection resource
│       │   ├── scene_script_switcher.gd       # Scene <-> Script heuristic engine
│       │   ├── recent_history_tracker.gd      # 30-slot LRU ring buffer
│       │   ├── bookmark_storage.gd            # Dual-tier ConfigFile persistence
│       │   └── bookmark_manager.gd            # Central singleton & coordinator
│       └── ui/                                # Native Editor UI components
│           ├── ribbon_tab_item.tscn           # Visual bookmark button with hover/menu
│           ├── ribbon_tab_item.gd
│           ├── toolbar_ribbon.tscn            # CONTAINER_TOOLBAR ribbon bar
│           ├── toolbar_ribbon.gd
│           ├── bundle_manager_dialog.tscn     # Feature bundle manager modal
│           ├── bundle_manager_dialog.gd
│           ├── quick_search_palette.tscn      # Quick search modal popup
│           └── quick_search_palette.gd
├── demo/                                      # Standalone interactive showcase
│   ├── demo.tscn                              # Runnable showcase scene
│   ├── demo.gd                                # Interactive controller & self-tests
│   └── mock_project/                          # Mock assets (Player, Enemies, UI)
│       ├── player/
│       ├── enemies/
│       └── ui/
└── README.md                                  # Complete documentation
```

---

## 🚀 Installation & Setup

### Method 1: Copy to Existing Project
1. Copy the `addons/smart_bookmarks` folder into your Godot project's `res://addons/` directory.
2. In the Godot Editor menu, navigate to:  
   **Project** → **Project Settings** → **Plugins**.
3. Locate **Smart Bookmarks & Quick File Switcher** and check **Enable**.
4. The Smart Bookmarks ribbon will appear immediately in the top editor toolbar!

### Method 2: Standalone Demo Testing
1. Open the project root in Godot 4.x.
2. Open and run `packages/smart_bookmarks/demo/demo.tscn`.
3. Test interactive bundle management, live scene-to-script toggling (`Alt + S`), quick search (`Alt + B`), and execute the built-in automated test suite!

---

## 🛠️ API & Core Classes Reference

### `BookmarkManager`
Central singleton coordinating bundles, history, shortcuts, and editor hooks.
```gdscript
var manager := BookmarkManager.new()
manager.initialize(editor_interface, "res://smart_bookmarks.cfg", "user://smart_bookmarks_user.cfg")

# Create a new bundle
var bundle := manager.create_bundle("Inventory System", Color(0.4, 0.8, 0.4))

# Pin a file
manager.pin_file("res://ui/inventory.tscn", "Inventory HUD")

# Toggle between scene and script
var result := manager.toggle_scene_to_script("res://ui/inventory.tscn")
print("Target: ", result["target_path"]) # -> res://ui/inventory.gd

# Smart Auto-Group files matching a stem
var auto_bundle := manager.auto_group_files_from_stem("player")
```

### `SceneScriptSwitcher`
Pure static heuristic engine resolving pairings between `.tscn` and `.gd`/`.cs`.
```gdscript
# Resolve script from scene path
var script_path := SceneScriptSwitcher.resolve_script_from_scene("res://scenes/player.tscn")

# Resolve scene from script path
var scene_path := SceneScriptSwitcher.resolve_scene_from_script("res://scripts/player.gd")

# Execute full toggle dictionary
var res := SceneScriptSwitcher.execute_toggle("res://player.gd")
```

### `RecentHistoryTracker`
LRU ring buffer maintaining up to `max_capacity` recent items.
```gdscript
var tracker := RecentHistoryTracker.new(30)
tracker.record_access("res://player.gd", "player.gd")
var entries := tracker.get_entries() # Array[BookmarkItem] sorted by recency
```

---

## 📄 License
This project is licensed under the **MIT License**. Free for commercial and non-commercial game projects.
