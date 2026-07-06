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
    def test_victory_condition_tracks_the_silver_key_from_the_safe(self) -> None:
        script = MAIN_SCRIPT.read_text(encoding="utf-8")
        victory_function = extract_function(script, "_check_victory_condition")

        self.assertIn('GameState.get_flag("office_silver_key_collected")', victory_function)
        for old_final_flag in [
            "bedroom_small_key_collected",
            "dining_room_eye_medallion_collected",
            "office_flame_medallion_collected",
            "dining_room_spiral_medallion_collected",
            "library_royal_family_emblem_collected",
            "bedroom_box_letter_collected",
        ]:
            self.assertNotIn(f'GameState.get_flag("{old_final_flag}")', victory_function)

    def test_silver_key_pickup_does_not_end_the_game_immediately(self) -> None:
        script = MAIN_SCRIPT.read_text(encoding="utf-8")

        branch_match = re.search(
            r'"pickup_silver_key":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            script,
            re.DOTALL,
        )
        self.assertIsNotNone(branch_match, "pickup_silver_key branch not found")
        self.assertIn('GameState.set_flag("office_silver_key_collected", true)', branch_match.group("branch"))
        self.assertNotIn("_check_victory_condition()", branch_match.group("branch"))

    def test_hall_center_door_checks_for_victory(self) -> None:
        script = MAIN_SCRIPT.read_text(encoding="utf-8")

        branch_match = re.search(
            r'"go_center_locked":\n(?P<branch>.*?)(?=\n\t\t"|\n\t\t_:)',
            script,
            re.DOTALL,
        )
        self.assertIsNotNone(branch_match, "go_center_locked branch not found")
        branch = branch_match.group("branch")

        self.assertIn("_check_victory_condition()", branch)
        self.assertIn("_show_victory_screen()", extract_function(script, "_check_victory_condition"))


if __name__ == "__main__":
    unittest.main()
