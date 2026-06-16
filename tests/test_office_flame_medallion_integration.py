import unittest
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]


class OfficeFlameMedallionIntegrationTest(unittest.TestCase):
    def test_office_box_flame_medallion_assets_scenes_and_handlers_are_registered(self) -> None:
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        office_scene = (ROOT / "scenes" / "rooms" / "office" / "office_main.tscn").read_text(encoding="utf-8")

        for path in [
            ROOT / "art" / "items" / "office" / "item_flame_medallion.png",
            ROOT / "art" / "backgrounds" / "office" / "office_box_open_with_medallion.png",
            ROOT / "art" / "backgrounds" / "office" / "office_box_open_without_medallion.png",
            ROOT / "art" / "zoom_ins" / "office" / "office_desktop.png",
            ROOT / "art" / "zoom_ins" / "office" / "office_desktop_letters_stack.png",
            ROOT / "art" / "zoom_ins" / "office" / "office_desktop_box.png",
            ROOT / "art" / "zoom_ins" / "office" / "office_desktop_box_open_with_medallion.png",
            ROOT / "art" / "zoom_ins" / "office" / "office_desktop_box_open_without_medallion.png",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_desktop.tscn",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_desktop_letters_stack.tscn",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_inventory_box.tscn",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_box_open_with_medallion.tscn",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_box_open_without_medallion.tscn",
            ROOT / "scripts" / "puzzles" / "office_inventory_box_puzzle.gd",
            ROOT / "scripts" / "rooms" / "office_controller.gd",
            ROOT / "art" / "zoom_ins" / "dining_room" / "zoom_dining_table_with_scribbled_napkin.png",
            ROOT / "art" / "zoom_ins" / "dining_room" / "zoom_dining_table_without_scribbled_napkin.png",
            ROOT / "art" / "items" / "dining_room" / "scribbled_napkin_read.png",
            ROOT / "scenes" / "zooms" / "dining_room" / "zoom_dining_table_with_scribbled_napkin.tscn",
            ROOT / "scenes" / "zooms" / "dining_room" / "zoom_dining_table_without_scribbled_napkin.tscn",
        ]:
            self.assertTrue(path.exists(), f"Missing office flame medallion integration file: {path}")

        self.assertIn('"item_flame_medallion"', item_database)
        self.assertIn('"read_image": "res://art/items/dining_room/scribbled_napkin_read.png"', item_database)
        self.assertIn('"dining_room_table_with_scribbled_napkin"', zoom_manager)
        self.assertIn('"dining_room_table_without_scribbled_napkin"', zoom_manager)
        self.assertIn('"office_desktop"', zoom_manager)
        self.assertIn('"office_desktop_letters_stack"', zoom_manager)
        self.assertIn('"office_inventory_box"', zoom_manager)
        self.assertIn('"office_box_open_with_medallion"', zoom_manager)
        self.assertIn('"office_box_open_without_medallion"', zoom_manager)
        self.assertIn('script = ExtResource("1")', office_scene)
        self.assertIn('interaction_id = "office_box"', office_scene)
        self.assertIn('cursor_type = "inspect"', office_scene)
        self.assertIn('RectangleShape2D_desktop', office_scene)
        self.assertIn('size = Vector2(525, 240)', office_scene)
        self.assertIn('position = Vector2(632.5, 645)', office_scene)
        self.assertIn('"office_box":', main_script)
        self.assertIn('GameState.get_flag("office_box_opened")', main_script)
        self.assertIn('zoom_manager.open_zoom("office_desktop")', main_script)
        self.assertIn('"open_office_desktop_letters_stack":', main_script)
        self.assertIn('"open_office_inventory_box":', main_script)
        self.assertIn('"office_inventory_box_solved":', main_script)
        self.assertIn('"dining_room_table":', main_script)
        self.assertIn('"pickup_scribbled_napkin":', main_script)
        self.assertIn('"pickup_flame_medallion":', main_script)
        self.assertIn('GameState.set_flag("office_flame_medallion_collected", true)', main_script)
        self.assertIn('Inventory.add_item("item_flame_medallion")', main_script)

    def test_office_inventory_box_requires_table_inventory_code(self) -> None:
        puzzle_script = (ROOT / "scripts" / "puzzles" / "office_inventory_box_puzzle.gd").read_text(encoding="utf-8")
        desktop_zoom_script = (ROOT / "scripts" / "zooms" / "office_desktop_zoom.gd").read_text(encoding="utf-8")
        box_scene = (ROOT / "scenes" / "zooms" / "office" / "zoom_office_inventory_box.tscn").read_text(encoding="utf-8")
        desktop_scene = (ROOT / "scenes" / "zooms" / "office" / "zoom_office_desktop.tscn").read_text(encoding="utf-8")

        self.assertIn('const CORRECT_X := "6"', puzzle_script)
        self.assertIn('const CORRECT_Y := "12"', puzzle_script)
        self.assertIn('const CORRECT_Z := "22"', puzzle_script)
        self.assertIn('GameState.set_flag("office_box_opened", true)', puzzle_script)
        self.assertIn('interaction_requested.emit("office_inventory_box_solved")', puzzle_script)
        self.assertIn('tween_property(self, "position"', puzzle_script)

        for node_name in ["XValueLabel", "YValueLabel", "ZValueLabel", "XSlot", "YSlot", "ZSlot", "SubmitButton"]:
            self.assertIn(f'name="{node_name}"', box_scene)
        self.assertIn("func _on_slot_gui_input", puzzle_script)
        self.assertIn("MOUSE_BUTTON_RIGHT", puzzle_script)
        self.assertIn("MOUSE_BUTTON_WHEEL_UP", puzzle_script)
        self.assertIn('const STATE_KEY := "office_inventory_box_state"', puzzle_script)
        self.assertIn("GameState.get_value(STATE_KEY", puzzle_script)
        self.assertIn("GameState.set_value(STATE_KEY", puzzle_script)
        self.assertIn("REPEAT_INITIAL_DELAY", puzzle_script)
        self.assertIn("REPEAT_INTERVAL", puzzle_script)
        self.assertIn("func _on_repeat_timer_timeout", puzzle_script)

        self.assertIn('interaction_id = "open_office_desktop_letters_stack"', desktop_scene)
        self.assertIn('interaction_id = "open_office_inventory_box"', desktop_scene)
        self.assertIn('cursor_type = "grab"', desktop_scene)
        self.assertIn('res://scripts/zooms/office_desktop_zoom.gd', desktop_scene)
        self.assertIn('const LETTERS_STACK_RECT := Rect2(305.0, 250.0, 285.0, 150.0)', desktop_zoom_script)
        self.assertIn("func refresh_state_visuals", desktop_zoom_script)
        self.assertIn("OPEN_WITH_MEDALLION_DESKTOP_TEXTURE", desktop_zoom_script)
        self.assertIn("OPEN_WITHOUT_MEDALLION_DESKTOP_TEXTURE", desktop_zoom_script)
        self.assertIn('res://art/backgrounds/office/office_box_open_with_medallion.png', desktop_zoom_script)
        self.assertIn('res://art/backgrounds/office/office_box_open_without_medallion.png', desktop_zoom_script)

    def test_office_room_does_not_keep_zoom_stack_after_room_change(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        office_controller = (ROOT / "scripts" / "rooms" / "office_controller.gd").read_text(encoding="utf-8")

        self.assertIn("func close_all_zooms", zoom_manager)
        self.assertIn("parent_zoom_stack.clear()", zoom_manager)
        self.assertIn("zoom_manager.close_all_zooms()", main_script)
        self.assertIn('current_zoom.refresh_state_visuals()', zoom_manager)
        self.assertIn('box_hotspot.cursor_type = "pickup"', office_controller)
        self.assertIn('box_hotspot.cursor_type = "inspect"', office_controller)
        self.assertIn("res://scripts/core/scaled_zoom_view.gd", (ROOT / "scripts" / "puzzles" / "office_inventory_box_puzzle.gd").read_text(encoding="utf-8"))

    def test_office_room_opens_desktop_even_after_box_is_opened(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        branch_match = re.search(
            r'"office_box":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            main_script,
            re.DOTALL,
        )
        self.assertIsNotNone(branch_match, "office_box branch not found")
        branch = branch_match.group("branch")

        self.assertIn('zoom_manager.open_zoom("office_desktop")', branch)
        self.assertNotIn("_open_office_box_zoom", branch)

    def test_opened_office_box_keeps_desktop_as_only_parent_zoom(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")

        desktop_branch_match = re.search(
            r'"open_office_inventory_box":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            main_script,
            re.DOTALL,
        )
        self.assertIsNotNone(desktop_branch_match, "open_office_inventory_box branch not found")
        self.assertIn("_open_office_box_zoom(false, true)", desktop_branch_match.group("branch"))

        for interaction_id in ["pickup_flame_medallion", "office_inventory_box_solved"]:
            branch_match = re.search(
                rf'"{interaction_id}":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
                main_script,
                re.DOTALL,
            )
            self.assertIsNotNone(branch_match, f"{interaction_id} branch not found")
            self.assertIn("_open_office_box_zoom(false, false, true)", branch_match.group("branch"))

        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        self.assertIn("preserve_parent_stack", zoom_manager)
        self.assertIn("_prepare_current_zoom_for_replacement()", zoom_manager)

    def test_office_room_background_stays_on_full_room_art_after_box_state_changes(self) -> None:
        office_controller = (ROOT / "scripts" / "rooms" / "office_controller.gd").read_text(encoding="utf-8")

        self.assertIn("DEFAULT_OFFICE_BACKGROUND", office_controller)
        self.assertIn('res://art/backgrounds/office/office_new.png', office_controller)
        self.assertIn("background.texture = DEFAULT_OFFICE_BACKGROUND", office_controller)
        self.assertNotIn("office_box_open_with_medallion.png", office_controller)
        self.assertNotIn("office_box_open_without_medallion.png", office_controller)

    def test_dining_table_napkin_clue_is_collectable_and_readable(self) -> None:
        dining_scene = (ROOT / "scenes" / "rooms" / "dining_room" / "dining_room_main.tscn").read_text(encoding="utf-8")
        table_scene = (ROOT / "scenes" / "zooms" / "dining_room" / "zoom_dining_table_with_scribbled_napkin.tscn").read_text(encoding="utf-8")
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")

        self.assertIn('interaction_id = "dining_room_table"', dining_scene)
        self.assertIn('interaction_id = "pickup_scribbled_napkin"', table_scene)
        self.assertIn('disabled_flag = "dining_room_scribbled_napkin_collected"', table_scene)
        self.assertIn('func _open_dining_room_table_zoom', main_script)
        self.assertIn('zoom_manager.open_zoom("dining_room_table_with_scribbled_napkin")', main_script)
        self.assertIn('zoom_manager.open_zoom("dining_room_table_without_scribbled_napkin")', main_script)
        self.assertIn('"read_image": "res://art/items/dining_room/scribbled_napkin_read.png"', item_database)


if __name__ == "__main__":
    unittest.main()
