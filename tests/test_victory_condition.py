import re
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MAIN_SCRIPT = ROOT / "scripts" / "main.gd"


def extract_function(script: str, function_name: str) -> str:
    match = re.search(rf"func {function_name}\(.*?(?=\n\nfunc |\Z)", script, re.DOTALL)
    if match is None:
        raise AssertionError(f"{function_name} not found")
    return match.group(0)


class VictoryConditionTest(unittest.TestCase):
    def test_victory_requires_the_three_puzzle_completion_flags(self) -> None:
        script = MAIN_SCRIPT.read_text(encoding="utf-8")
        victory_function = extract_function(script, "_check_victory_condition")

        self.assertIn('GameState.get_flag("bedroom_small_key_collected")', victory_function)
        self.assertIn('GameState.get_flag("dining_room_eye_medallion_collected")', victory_function)
        self.assertIn('GameState.get_flag("dining_room_floral_reliquary_solved")', victory_function)
        self.assertNotIn('GameState.get_flag("bedroom_box_letter_collected")', victory_function)

    def test_each_final_puzzle_step_checks_for_victory(self) -> None:
        script = MAIN_SCRIPT.read_text(encoding="utf-8")

        for interaction_id in [
            "pickup_small_key",
            "pickup_eye_medallion",
            "floral_reliquary_solved",
        ]:
            branch_match = re.search(
                rf'"{interaction_id}":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
                script,
                re.DOTALL,
            )
            self.assertIsNotNone(branch_match, f"{interaction_id} branch not found")
            self.assertIn("_check_victory_condition()", branch_match.group("branch"))


if __name__ == "__main__":
    unittest.main()
