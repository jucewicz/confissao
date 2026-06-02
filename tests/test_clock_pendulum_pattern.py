import ast
import re
import unittest
from collections import deque
from pathlib import Path
from typing import Optional


LEVELS = ["up", "middle", "down"]
SOLVED_STATES = {
    ("up", "up", "up"),
    ("middle", "middle", "middle"),
    ("down", "down", "down"),
}
PENDULUM_SCRIPT = (
    Path(__file__).resolve().parents[1]
    / "scripts"
    / "puzzles"
    / "clock_pendulum_puzzle.gd"
)


def load_initial_state() -> tuple[str, str, str]:
    script = PENDULUM_SCRIPT.read_text(encoding="utf-8")
    match = re.search(r"const INITIAL_STATE := (\[[^\]]+\])", script)
    if match is None:
        raise AssertionError("INITIAL_STATE not found")

    state = ast.literal_eval(match.group(1))
    return tuple(state)


def ascend(level: str) -> str:
    return LEVELS[(LEVELS.index(level) - 1) % len(LEVELS)]


def descend(level: str) -> str:
    return LEVELS[(LEVELS.index(level) + 1) % len(LEVELS)]


def click(state: tuple[str, str, str], pendulum_index: int) -> tuple[str, str, str]:
    next_state = list(state)
    if pendulum_index == 0:
        next_state[0] = descend(next_state[0])
        next_state[1] = ascend(next_state[1])
    elif pendulum_index == 1:
        next_state[0] = ascend(next_state[0])
        next_state[1] = descend(next_state[1])
        next_state[2] = ascend(next_state[2])
    elif pendulum_index == 2:
        next_state[1] = ascend(next_state[1])
        next_state[2] = descend(next_state[2])
    else:
        raise ValueError(f"Unknown pendulum index: {pendulum_index}")

    return tuple(next_state)


def shortest_solution_length(initial_state: tuple[str, str, str]) -> Optional[int]:
    queue = deque([(initial_state, 0)])
    seen = {initial_state}

    while queue:
        state, distance = queue.popleft()
        if state in SOLVED_STATES:
            return distance

        for index in range(3):
            next_state = click(state, index)
            if next_state not in seen:
                seen.add(next_state)
                queue.append((next_state, distance + 1))

    return None


class ClockPendulumPatternTest(unittest.TestCase):
    def test_initial_pattern_does_not_solve_in_one_click(self) -> None:
        initial_state = load_initial_state()

        one_click_states = [click(initial_state, index) for index in range(3)]

        self.assertTrue(SOLVED_STATES.isdisjoint(one_click_states))

    def test_initial_pattern_still_has_a_short_solution(self) -> None:
        initial_state = load_initial_state()

        solution_length = shortest_solution_length(initial_state)

        self.assertIsNotNone(solution_length)
        self.assertGreaterEqual(solution_length, 3)
        self.assertLessEqual(solution_length, 5)


if __name__ == "__main__":
    unittest.main()
