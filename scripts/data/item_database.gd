class_name ItemDatabase

const ITEMS := {
	"item_jacket_note": {
		"name": "Carta dobrada",
		"description": "Uma carta antiga retirada do bolso de uma jaqueta azul-marinho.",
		"icon": "res://art/items/bedroom/item_jacket_note.png",
		"region": Rect2(175, 160, 960, 900),
		"type": "readable",
		"text": "Quando a noite entrar sem ser convidada, não procure primeiro nas mãos dos vivos.\n\nComece onde o rosto antigo guarda, junto ao peito, o brilho que não lhe pertence.\nDepois, procure descanso no lugar em que o bordado resiste ao tempo.\nOnde a claridade fria cair sobre o chão, abaixe os olhos para o desenho esquecido.\nPor fim, volte-se à escrita fechada sobre a madeira de trabalho.\n\nSó nessa ordem a lembrança dela consentirá em se revelar."
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
		"text": "Ele nunca confiou nas fechaduras grandes.\n\nGuardava o que importava onde ninguém pensaria em procurar:\nnão atrás da porta,\nmas dentro daquilo que registra seus pecados.\n\nA chave pequena pertence ao silêncio da escrivaninha."
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
