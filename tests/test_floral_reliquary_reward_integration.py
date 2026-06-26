import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class FloralReliquaryRewardIntegrationTest(unittest.TestCase):
    def test_floral_reliquary_opens_with_collectable_spiral_medallion_after_solution(self) -> None:
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")
        main_script = (ROOT / "scripts" / "main.gd").read_text(encoding="utf-8")
        zoom_manager = (ROOT / "scripts" / "core" / "zoom_manager.gd").read_text(encoding="utf-8")
        reward_close_scene = (
            ROOT
            / "scenes"
            / "zooms"
            / "dining_room"
            / "zoom_floral_reliquary_open_with_spiral_medallion_close.tscn"
        ).read_text(encoding="utf-8")

        for path in [
            ROOT / "art" / "items" / "dining_room" / "item_spiral_medallion.png",
            ROOT / "art" / "zoom_ins" / "dining_room" / "floral_reliquary" / "zoom_floral_reliquary_open_with_spiral_medallion_far.png",
            ROOT / "art" / "zoom_ins" / "dining_room" / "floral_reliquary" / "zoom_floral_reliquary_open_without_spiral_medallion_far.png",
            ROOT / "art" / "zoom_ins" / "dining_room" / "floral_reliquary" / "zoom_floral_reliquary_open_with_spiral_medallion_close.png",
            ROOT / "art" / "zoom_ins" / "dining_room" / "floral_reliquary" / "zoom_floral_reliquary_open_without_spiral_medallion_close.png",
            ROOT / "scenes" / "zooms" / "dining_room" / "zoom_floral_reliquary_open_with_spiral_medallion_far.tscn",
            ROOT / "scenes" / "zooms" / "dining_room" / "zoom_floral_reliquary_open_without_spiral_medallion_far.tscn",
            ROOT / "scenes" / "zooms" / "dining_room" / "zoom_floral_reliquary_open_with_spiral_medallion_close.tscn",
            ROOT / "scenes" / "zooms" / "dining_room" / "zoom_floral_reliquary_open_without_spiral_medallion_close.tscn",
        ]:
            self.assertTrue(path.exists(), f"Missing floral reliquary reward file: {path}")

        self.assertIn('"item_spiral_medallion"', item_database)
        self.assertIn('"dining_room_floral_reliquary_open_with_spiral_medallion_far"', zoom_manager)
        self.assertIn('"dining_room_floral_reliquary_open_without_spiral_medallion_far"', zoom_manager)
        self.assertIn('"dining_room_floral_reliquary_open_with_spiral_medallion_close"', zoom_manager)
        self.assertIn('"dining_room_floral_reliquary_open_without_spiral_medallion_close"', zoom_manager)
        self.assertIn('"pickup_spiral_medallion":', main_script)
        self.assertIn('Inventory.add_item("item_spiral_medallion")', main_script)
        self.assertIn('GameState.set_flag("dining_room_spiral_medallion_collected", true)', main_script)
        self.assertIn('func _open_floral_reliquary_far_zoom', main_script)
        self.assertIn('func _open_floral_reliquary_close_zoom', main_script)
        self.assertIn('func _open_floral_reliquary_reward_close_from_far', main_script)
        self.assertIn('"floral_reliquary_solved":', main_script)
        self.assertIn('_open_floral_reliquary_reward_close_from_far(false)', main_script)
        self.assertIn('res://scripts/zooms/floral_reliquary_reward_zoom.gd', reward_close_scene)


if __name__ == "__main__":
    unittest.main()
