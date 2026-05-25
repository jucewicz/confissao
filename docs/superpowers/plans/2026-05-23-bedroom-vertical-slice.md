# Bedroom Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first playable Godot slice: Master Bedroom exploration, zoom-ins, inventory, readable notes, jewelry-box symbol puzzle, rewards, and demo ending.

**Architecture:** Use a small Godot 4 scene stack: `Main` owns the current room, zoom overlay, inventory UI, and letter popup. Autoloads store global flags and inventory, while room/zoom scripts emit simple interactions into `Main`.

**Tech Stack:** Godot 4.6, GDScript, `.tscn` scenes, existing PNG assets under `res://art`.

---

### Task 1: Project Settings And Autoloads

**Files:**
- Modify: `project.godot`
- Create: `scripts/autoloads/game_state.gd`
- Create: `scripts/autoloads/inventory.gd`
- Create: `scripts/autoloads/audio_manager.gd`
- Create: `scripts/data/item_database.gd`

- [x] Add 1920x1080 display settings, input actions, main scene, and autoload entries.
- [x] Implement boolean flags in `GameState`.
- [x] Implement item add/remove/has logic in `Inventory`.
- [x] Add a quiet `AudioManager` stub so gameplay scripts can call SFX without crashing before audio assets exist.
- [x] Define bedroom item names, icons, descriptions, and readable note text in `ItemDatabase`.

### Task 2: Core Interaction And Zoom Flow

**Files:**
- Create: `scripts/core/interactable.gd`
- Create: `scripts/core/zoom_manager.gd`
- Create: `scripts/core/zoom_view.gd`

- [x] Implement reusable `Interactable` `Area2D` with hover cursor and `interaction_id`.
- [x] Implement `ZoomManager` that maps zoom IDs to bedroom zoom scenes, opens/closes overlay, and delegates interactions.
- [x] Implement `ZoomView` that displays a zoom image and optional internal hotspots.

### Task 3: UI And Puzzle

**Files:**
- Create: `scripts/ui/inventory_ui.gd`
- Create: `scripts/ui/readable_letter_popup.gd`
- Create: `scripts/puzzles/symbol_sequence_puzzle.gd`
- Create: `scenes/ui/inventory_ui.tscn`
- Create: `scenes/ui/readable_letter_popup.tscn`
- Create: `scenes/puzzles/symbol_sequence_puzzle.tscn`

- [x] Build inventory bar that displays collected bedroom items.
- [x] Build readable letter modal that shows item image and text.
- [x] Build six-symbol puzzle with input preview, clear action, wrong feedback, and solved signal.

### Task 4: Main And Bedroom Scenes

**Files:**
- Create: `scripts/main.gd`
- Create: `scripts/rooms/bedroom_controller.gd`
- Create: `scenes/main/main.tscn`
- Create: `scenes/rooms/bedroom/bedroom_main.tscn`
- Create: `scenes/zooms/bedroom/*.tscn`

- [x] Load bedroom as the starting room.
- [x] Add principal bedroom hotspots for portrait, flower, rug, writing desk, jewelry box, wardrobe, chest, and nightstands.
- [x] Add zoom scenes for all bedroom PNG zoom-ins.
- [x] Wire wardrobe note pickup, jewelry-box puzzle, reward item pickup, readable letters, and demo-ending message.

### Task 5: Verification

**Files:**
- Run against project root.

- [x] Open project in Godot to regenerate imports.
- [x] Run the main scene headless and verify it starts without script/runtime errors.
- [ ] Adjust hotspot rectangles visually in Godot after testing, because coordinates are first-pass approximations.
