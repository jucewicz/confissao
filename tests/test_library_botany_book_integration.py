import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class LibraryBotanyBookIntegrationTest(unittest.TestCase):
    def test_library_botany_book_assets_scenes_and_handlers_are_registered(self) -> None:
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        library_scene = (ROOT / "scenes" / "rooms" / "library" / "library_main.tscn").read_text(encoding="utf-8")

        for path in [
            ROOT / "art" / "items" / "library" / "item_botany_book.png",
            ROOT / "art" / "zoom_ins" / "library" / "zoom_bookshelf_with_botany_book.png",
            ROOT / "art" / "zoom_ins" / "library" / "zoom_bookshelf_without_botany_book.png",
            ROOT / "scenes" / "zooms" / "library" / "zoom_bookshelf_with_botany_book.tscn",
            ROOT / "scenes" / "zooms" / "library" / "zoom_bookshelf_without_botany_book.tscn",
            ROOT / "scripts" / "rooms" / "library_controller.gd",
        ]:
            self.assertTrue(path.exists(), f"Missing library botany book integration file: {path}")

        self.assertIn('"item_botany_book"', item_database)
        self.assertIn('"library_bookshelf_with_botany_book"', zoom_manager)
        self.assertIn('"library_bookshelf_without_botany_book"', zoom_manager)
        self.assertIn('interaction_id = "library_bookshelf"', library_scene)
        self.assertIn("size = Vector2(325, 400)", library_scene)
        self.assertIn("position = Vector2(1322.5, 280)", library_scene)
        self.assertIn('"library_bookshelf":', main_script)
        self.assertIn('"pickup_botany_book":', main_script)
        self.assertIn('GameState.set_flag("library_botany_book_collected", true)', main_script)
        self.assertIn('Inventory.add_item("item_botany_book")', main_script)


if __name__ == "__main__":
    unittest.main()
