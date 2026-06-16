import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


class BotanyBookReadingUITest(unittest.TestCase):
    def test_botany_book_has_reading_page_and_popup_controls(self) -> None:
        item_database = (ROOT / "scripts" / "data" / "item_database.gd").read_text(encoding="utf-8")
        popup_scene = (ROOT / "scenes" / "ui" / "readable_letter_popup.tscn").read_text(encoding="utf-8")
        popup_script = (ROOT / "scripts" / "ui" / "readable_letter_popup.gd").read_text(encoding="utf-8")

        self.assertTrue(
            (ROOT / "art" / "items" / "library" / "botany_book_page_flowers.png").exists()
        )
        self.assertTrue(
            (ROOT / "art" / "items" / "bedroom" / "jacket_note_read.png").exists()
        )
        self.assertIn('"read_image": "res://art/items/library/botany_book_page_flowers.png"', item_database)
        self.assertIn('"read_image": "res://art/items/bedroom/jacket_note_read.png"', item_database)
        self.assertIn('"description": "Uma carta antiga retirada do bolso de uma jaqueta azul-marinho.', item_database)
        self.assertIn('text = "Ler"', popup_scene)
        self.assertIn('node name="ReadButton"', popup_scene)
        self.assertIn('node name="PageOverlay"', popup_scene)
        self.assertIn('node name="PageImage"', popup_scene)
        self.assertIn('node name="BackToItemButton"', popup_scene)
        self.assertIn("read_button.pressed.connect(_open_read_image)", popup_script)
        self.assertIn("back_to_item_button.pressed.connect(_close_read_image)", popup_script)
        self.assertIn('item_data.get("read_image", "")', popup_script)


if __name__ == "__main__":
    unittest.main()
