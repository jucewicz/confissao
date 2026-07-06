class_name ItemDatabase

const ITEMS := {
	"item_jacket_note": {
		"name": "Carta dobrada",
		"description": "Uma carta antiga retirada do bolso de uma jaqueta azul-marinho. A caligrafia parece cuidadosa, mas a mensagem exige atenção.",
		"icon": "res://art/items/bedroom/item_jacket_note.png",
		"region": Rect2(175, 160, 960, 900),
		"read_image": "res://art/items/bedroom/jacket_note_read.png",
		"type": "inspectable",
		"text": ""
	},
	"item_small_victorian_key": {
		"name": "Chave pequena",
		"description": "Uma pequena chave vitoriana de latão envelhecido.",
		"icon": "res://art/items/bedroom/item_small_victorian_key.png",
		"region": Rect2(130, 320, 1100, 520),
		"type": "inspectable",
		"text": ""
	},
	"item_box_letter": {
		"name": "Carta selada",
		"description": "Uma carta formal encontrada junto à chave.",
		"icon": "res://art/items/bedroom/item_box_letter.png",
		"region": Rect2(130, 310, 1000, 585),
		"type": "readable",
		"text": "Não serve para nenhum puzzle ainda"
	},
	"item_eye_medallion": {
		"name": "Medalhão do olho fechado",
		"description": "Um medalhão antigo de metal escurecido, gravado com um olho fechado.",
		"icon": "res://art/items/dining_room/item_eye_medallion.png",
		"type": "inspectable",
		"text": ""
	},
	"item_scribbled_napkin": {
		"name": "Guardanapo rabiscado",
		"description": "Um guardanapo antigo com uma mensagem escrita às pressas.",
		"icon": "res://art/items/dining_room/item_scribbled_napkin.png",
		"read_image": "res://art/items/dining_room/scribbled_napkin_read.png",
		"type": "inspectable",
		"text": ""
	},
	"item_botany_book": {
		"name": "Livro de botânica",
		"description": "Um volume antigo de capa verde, marcado por anotações sobre flores usadas em ritos e homenagens.",
		"icon": "res://art/items/library/item_botany_book.png",
		"read_image": "res://art/items/library/botany_book_page_flowers.png",
		"type": "inspectable",
		"text": ""
	},
	"item_royal_family_emblem": {
		"name": "Emblema da família real",
		"description": "Um emblema pesado de metal dourado, marcado por uma flor-de-lis coroada.",
		"icon": "res://art/items/library/item_royal_family_emblem.png",
		"type": "inspectable",
		"text": ""
	},
	"item_flame_medallion": {
		"name": "Medalhão da chama",
		"description": "Um medalhão antigo de metal escurecido, gravado com uma chama.",
		"icon": "res://art/items/office/item_flame_medallion.png",
		"type": "inspectable",
		"text": ""
	},
	"item_silver_key": {
		"name": "Chave prateada",
		"description": "Uma chave prateada ornamentada, retirada do cofre.",
		"icon": "res://art/items/office/item_silver_key.png",
		"type": "inspectable",
		"text": ""
	},
	"item_spiral_medallion": {
		"name": "Medalhão espiral",
		"description": "Um medalhão antigo de metal escurecido, gravado com um nó espiralado.",
		"icon": "res://art/items/dining_room/item_spiral_medallion.png",
		"type": "inspectable",
		"text": ""
	}
}


static func get_item(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})


static func get_item_texture(item_id: String) -> Texture2D:
	var item_data := get_item(item_id)
	var icon_path: String = item_data.get("icon", "")
	if icon_path == "":
		return null

	var texture := load(icon_path)
	if not item_data.has("region"):
		return texture

	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = item_data["region"]
	return atlas
