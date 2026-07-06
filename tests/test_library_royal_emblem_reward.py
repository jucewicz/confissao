import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class LibraryRoyalEmblemRewardTest(unittest.TestCase):
    def test_library_book_path_reward_reveals_collectable_royal_emblem(self) -> None:
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")
        library_scene = (ROOT / "scenes" / "rooms" / "library" / "library_main.tscn").read_text(encoding="utf-8")
        library_controller = (ROOT / "scripts" / "rooms" / "library_controller.gd").read_text(encoding="utf-8")
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")

        for path in [
            ROOT / "art" / "backgrounds" / "library" / "library.png",
            ROOT / "art" / "backgrounds" / "library" / "library_with_royal_emblem.png",
            ROOT / "art" / "backgrounds" / "library" / "library_without_royal_emblem.png",
            ROOT / "art" / "items" / "library" / "item_royal_family_emblem.png",
        ]:
            self.assertTrue(path.exists(), f"Missing royal emblem reward asset: {path}")

        self.assertIn('"item_royal_family_emblem"', item_database)
        self.assertIn('"icon": "res://art/items/library/item_royal_family_emblem.png"', item_database)
        self.assertIn('interaction_id = "pickup_royal_family_emblem"', library_scene)
        self.assertIn('enabled_flag = "library_book_path_puzzle_solved"', library_scene)
        self.assertIn('disabled_flag = "library_royal_family_emblem_collected"', library_scene)
        self.assertIn('cursor_type = "pickup"', library_scene)

        self.assertIn("DEFAULT_LIBRARY_BACKGROUND", library_controller)
        self.assertIn("OPEN_WITH_EMBLEM_BACKGROUND", library_controller)
        self.assertIn("OPEN_WITHOUT_EMBLEM_BACKGROUND", library_controller)
        self.assertIn('GameState.get_flag("library_book_path_puzzle_solved")', library_controller)
        self.assertIn('GameState.get_flag("library_royal_family_emblem_collected")', library_controller)
        self.assertIn("background.texture = OPEN_WITH_EMBLEM_BACKGROUND", library_controller)
        self.assertIn("background.texture = OPEN_WITHOUT_EMBLEM_BACKGROUND", library_controller)

        self.assertIn('"pickup_royal_family_emblem":', main_script)
        self.assertIn('Inventory.add_item("item_royal_family_emblem")', main_script)
        self.assertIn('GameState.set_flag("library_royal_family_emblem_collected", true)', main_script)
        self.assertIn("_refresh_current_room_state_visuals()", main_script)

        room_branch_match = re.search(
            r'func _on_room_interaction_requested.*?"pickup_royal_family_emblem":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            main_script,
            re.DOTALL,
        )
        self.assertIsNotNone(room_branch_match, "pickup_royal_family_emblem room branch not found")
        self.assertIn("_pickup_royal_family_emblem()", room_branch_match.group("branch"))
        self.assertIn("func _pickup_royal_family_emblem", main_script)

    def test_royal_emblem_is_safe_input_not_direct_victory(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        victory_match = re.search(r"func _check_victory_condition\(.*?(?=\n\nfunc |\Z)", main_script, re.DOTALL)
        self.assertIsNotNone(victory_match, "_check_victory_condition not found")
        victory_function = victory_match.group(0)

        self.assertIn('GameState.get_flag("office_silver_key_collected")', victory_function)
        self.assertNotIn('GameState.get_flag("library_royal_family_emblem_collected")', victory_function)

        self.assertIn('"item_royal_family_emblem"', main_script)
        self.assertIn('const SAFE_EMBLEM_ITEM_IDS', main_script)


if __name__ == "__main__":
    unittest.main()
