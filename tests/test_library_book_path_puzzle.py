import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PUZZLE_SCRIPT = ROOT / "scripts" / "puzzles" / "library_book_path_puzzle.gd"


class LibraryBookPathPuzzleTest(unittest.TestCase):
    def test_book_path_puzzle_assets_scene_and_handlers_are_registered(self) -> None:
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        library_scene = (ROOT / "scenes" / "rooms" / "library" / "library_main.tscn").read_text(encoding="utf-8")

        for path in [
            ROOT / "art" / "zoom_ins" / "library" / "zoom_bookshelf_missing_six_books.png",
            ROOT / "art" / "zoom_ins" / "library" / "book_path_blank.png",
            ROOT / "scenes" / "zooms" / "library" / "zoom_book_path_puzzle.tscn",
            ROOT / "scripts" / "puzzles" / "library_book_path_puzzle.gd",
        ]:
            self.assertTrue(path.exists(), f"Missing library book path puzzle file: {path}")

        self.assertIn('"library_book_path_puzzle"', zoom_manager)
        self.assertIn('interaction_id = "library_book_path_puzzle"', library_scene)
        self.assertIn('"library_book_path_puzzle":', main_script)
        self.assertIn('"library_book_path_puzzle_solved":', main_script)

    def test_scene_uses_one_blank_book_sprite_for_every_book(self) -> None:
        scene = (ROOT / "scenes" / "zooms" / "library" / "zoom_book_path_puzzle.tscn").read_text(encoding="utf-8")

        self.assertIn("book_path_blank.png", scene)
        for book_index in range(1, 7):
            self.assertNotIn(f"book_path_{book_index}.png", scene)

    def test_book_path_lines_are_drawn_from_three_named_levels(self) -> None:
        script = PUZZLE_SCRIPT.read_text(encoding="utf-8")

        self.assertIn("const PATH_LEVELS", script)
        self.assertIn('"low"', script)
        self.assertIn('"middle"', script)
        self.assertIn('"high"', script)
        self.assertIn("const PATH_SEGMENTS", script)
        self.assertIn("func _update_path_lines", script)
        self.assertIn("Line2D.new()", script)

    def test_dragging_swaps_books_when_crossing_occupied_slots(self) -> None:
        script = PUZZLE_SCRIPT.read_text(encoding="utf-8")

        self.assertIn("func _swap_dragged_book_into_slot", script)
        self.assertIn("_swap_dragged_book_into_slot(hovered_slot)", script)
        self.assertIn("var displaced_book := slot_books[target_slot_index]", script)
        self.assertIn("slot_books[drag_origin_slot] = displaced_book", script)

    def test_canonical_book_order_is_still_documented(self) -> None:
        script = PUZZLE_SCRIPT.read_text(encoding="utf-8")
        match = re.search(r"const SOLUTION := (\[.*?\])", script, re.DOTALL)
        self.assertIsNotNone(match, "SOLUTION array not found")
        self.assertEqual(
            re.findall(r'"([^"]+)"', match.group(1)),
            [f"book_{book_index}" for book_index in range(1, 7)],
        )

    def test_solution_accepts_any_continuous_path_across_the_three_levels(self) -> None:
        script = PUZZLE_SCRIPT.read_text(encoding="utf-8")

        self.assertIn("func _is_continuous_path", script)
        self.assertIn("_is_continuous_path()", script)
        self.assertIn("_get_path_start_level", script)
        self.assertIn("_get_path_end_level", script)
        self.assertNotIn("slot_books[index] != SOLUTION[index]", script)


if __name__ == "__main__":
    unittest.main()
