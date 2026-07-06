import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class OfficeSafeFinalPuzzleTest(unittest.TestCase):
    def test_safe_final_puzzle_assets_scenes_and_handlers_are_registered(self) -> None:
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        office_scene = (ROOT / "scenes" / "rooms" / "office" / "office_main.tscn").read_text(encoding="utf-8")

        for path in [
            ROOT / "art" / "zoom_ins" / "office" / "safe_closed.png",
            ROOT / "art" / "zoom_ins" / "office" / "safe_open.png",
            ROOT / "art" / "zoom_ins" / "office" / "safe_open_with_key.png",
            ROOT / "art" / "items" / "office" / "item_silver_key.png",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_safe_closed.tscn",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_safe_open_with_key.tscn",
            ROOT / "scenes" / "zooms" / "office" / "zoom_office_safe_open_empty.tscn",
            ROOT / "scripts" / "zooms" / "office_safe_puzzle.gd",
            ROOT / "scripts" / "zooms" / "office_safe_open_zoom.gd",
            ROOT / "scripts" / "ui" / "inventory_slot_button.gd",
        ]:
            self.assertTrue(path.exists(), f"Missing office safe final puzzle file: {path}")

        self.assertIn('"item_silver_key"', item_database)
        self.assertIn('"icon": "res://art/items/office/item_silver_key.png"', item_database)
        self.assertIn('interaction_id = "office_safe"', office_scene)
        self.assertIn('cursor_type = "inspect"', office_scene)
        self.assertIn('"office_safe":', main_script)
        self.assertIn('func _open_office_safe_zoom', main_script)
        self.assertIn('"office_safe_closed"', zoom_manager)
        self.assertIn('"office_safe_open_with_key"', zoom_manager)
        self.assertIn('"office_safe_open_empty"', zoom_manager)
        self.assertIn('"pickup_silver_key":', main_script)
        self.assertIn('Inventory.add_item("item_silver_key")', main_script)
        self.assertIn('GameState.set_flag("office_silver_key_collected", true)', main_script)

    def test_safe_accepts_any_four_emblems_and_opens_when_all_are_placed(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        safe_script = (ROOT / "scripts" / "zooms" / "office_safe_puzzle.gd").read_text(encoding="utf-8")
        safe_scene = (ROOT / "scenes" / "zooms" / "office" / "zoom_office_safe_closed.tscn").read_text(encoding="utf-8")
        ui_interactable = (ROOT / "scripts" / "core" / "ui_interactable.gd").read_text(encoding="utf-8")

        for item_id in [
            "item_eye_medallion",
            "item_flame_medallion",
            "item_spiral_medallion",
            "item_royal_family_emblem",
        ]:
            self.assertIn(item_id, main_script)
            self.assertIn(item_id, safe_script)
            self.assertIn(item_id, safe_scene)

        for slot_id in ["place_safe_emblem_0", "place_safe_emblem_1", "place_safe_emblem_2", "place_safe_emblem_3"]:
            self.assertIn(f'interaction_id = "{slot_id}"', safe_scene)
            self.assertIn(f'"{slot_id}":', main_script)

        self.assertIn('const SAFE_EMBLEM_SLOT_STATE_KEY := "office_safe_emblem_slots"', main_script)
        self.assertIn('GameState.set_flag("office_safe_opened", true)', main_script)
        self.assertIn('zoom_manager.open_zoom("office_safe_open_with_key"', main_script)
        self.assertIn("accepted_drop_item_ids", ui_interactable)
        self.assertIn('"_dropped_inventory_item_id"', ui_interactable)

    def test_silver_key_from_the_open_safe_enables_the_hall_exit(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        hall_controller = (ROOT / "scripts" / "rooms" / "hall_controller.gd").read_text(encoding="utf-8")
        victory_match = re.search(r"func _check_victory_condition\(.*?(?=\n\nfunc |\Z)", main_script, re.DOTALL)
        self.assertIsNotNone(victory_match, "_check_victory_condition not found")
        victory_function = victory_match.group(0)

        self.assertIn('GameState.get_flag("office_silver_key_collected")', victory_function)
        self.assertNotIn('GameState.get_flag("office_flame_medallion_collected")', victory_function)
        self.assertNotIn('GameState.get_flag("library_royal_family_emblem_collected")', victory_function)

        branch_match = re.search(
            r'"pickup_silver_key":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            main_script,
            re.DOTALL,
        )
        self.assertIsNotNone(branch_match, "pickup_silver_key branch not found")
        self.assertNotIn("_check_victory_condition()", branch_match.group("branch"))

        center_door_match = re.search(
            r'"go_center_locked":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            main_script,
            re.DOTALL,
        )
        self.assertIsNotNone(center_door_match, "go_center_locked branch not found")
        self.assertIn("_check_victory_condition()", center_door_match.group("branch"))
        self.assertIn("GameState.get_flag(\"office_silver_key_collected\")", hall_controller)
        self.assertIn('center_door_hotspot.cursor_type = "interact"', hall_controller)


if __name__ == "__main__":
    unittest.main()
