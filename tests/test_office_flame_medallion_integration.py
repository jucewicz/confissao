import unittest
from pathlib import Path


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
        box_scene = (ROOT / "scenes" / "zooms" / "office" / "zoom_office_inventory_box.tscn").read_text(encoding="utf-8")
        desktop_scene = (ROOT / "scenes" / "zooms" / "office" / "zoom_office_desktop.tscn").read_text(encoding="utf-8")

        self.assertIn('const CORRECT_X := "6"', puzzle_script)
        self.assertIn('const CORRECT_Y := "12"', puzzle_script)
        self.assertIn('const CORRECT_Z := "22"', puzzle_script)
        self.assertIn('GameState.set_flag("office_box_opened", true)', puzzle_script)
        self.assertIn('interaction_requested.emit("office_inventory_box_solved")', puzzle_script)
        self.assertIn('tween_property(self, "position"', puzzle_script)

        for node_name in ["XInput", "YInput", "ZInput", "SubmitButton"]:
            self.assertIn(f'name="{node_name}"', box_scene)

        self.assertIn('interaction_id = "open_office_desktop_letters_stack"', desktop_scene)
        self.assertIn('interaction_id = "open_office_inventory_box"', desktop_scene)
        self.assertIn('cursor_type = "grab"', desktop_scene)
        self.assertIn('res://scripts/zooms/office_desktop_zoom.gd', desktop_scene)

    def test_office_room_does_not_keep_zoom_stack_after_room_change(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        office_controller = (ROOT / "scripts" / "rooms" / "office_controller.gd").read_text(encoding="utf-8")

        self.assertIn("func close_all_zooms", zoom_manager)
        self.assertIn("parent_zoom_stack.clear()", zoom_manager)
        self.assertIn("zoom_manager.close_all_zooms()", main_script)
        self.assertIn('box_hotspot.cursor_type = "pickup"', office_controller)
        self.assertIn('box_hotspot.cursor_type = "inspect"', office_controller)
        self.assertIn("res://scripts/core/scaled_zoom_view.gd", (ROOT / "scripts" / "puzzles" / "office_inventory_box_puzzle.gd").read_text(encoding="utf-8"))

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
