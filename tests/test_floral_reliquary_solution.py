import ast
import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PUZZLE_SCRIPT = ROOT / "scripts" / "puzzles" / "floral_reliquary_puzzle.gd"
FAR_ZOOM_SCRIPT = ROOT / "scripts" / "puzzles" / "floral_reliquary_far_zoom.gd"

EXPECTED_SOLUTION = {
    "culpa": "lily",
    "amor": "rose",
    "silencio": "violet",
    "sangue": "carnation",
}


def load_solution(script_path: Path) -> dict[str, str]:
    script = script_path.read_text(encoding="utf-8")
    match = re.search(r"const SOLUTION := (\{.*?\n\})", script, re.DOTALL)
    if match is None:
        raise AssertionError(f"SOLUTION not found in {script_path}")

    solution_source = re.sub(r"(\w+):", r'"\1":', match.group(1))
    return ast.literal_eval(solution_source)


class FloralReliquarySolutionTest(unittest.TestCase):
    def test_expected_flower_meanings_are_the_puzzle_solution(self) -> None:
        self.assertEqual(load_solution(PUZZLE_SCRIPT), EXPECTED_SOLUTION)
        self.assertEqual(load_solution(FAR_ZOOM_SCRIPT), EXPECTED_SOLUTION)

    def test_solving_only_marks_reliquary_solved_for_now(self) -> None:
        script = PUZZLE_SCRIPT.read_text(encoding="utf-8")

        self.assertIn('GameState.set_flag(SOLVED_FLAG, true)', script)
        self.assertIn('interaction_requested.emit("floral_reliquary_solved")', script)
        self.assertNotIn("Inventory.add_item", script)


if __name__ == "__main__":
    unittest.main()
