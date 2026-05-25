# A CONFISSÃO — Plano Geral de Implementação Ajustado  
## Godot 4 / GDScript — Point-and-Click com Puzzles

Este documento substitui o plano geral anterior e ajusta a implementação para o jogo como ele está sendo desenvolvido agora: uma mansão vitoriana em pixel art, com múltiplos cômodos, zoom-ins estáticos, itens de inventário, cartas, enigmas e puzzles de observação.

A prioridade da primeira entrega não é implementar todos os cômodos, mas sim criar uma **vertical slice jogável** com o **Master Bedroom** e o puzzle completo **“A Caixa de Joias da Senhora”**.

---

# 1. Visão geral do jogo

## Gênero

Point-and-click de investigação com puzzles.

## Estrutura

O jogador explora uma mansão vitoriana escura, investigando cômodos estáticos em 2D lateral. Cada cenário possui hotspots clicáveis que abrem zoom-ins, revelam pistas, permitem coletar itens e resolver puzzles.

## Estilo visual

- Pixel art detalhada.
- Câmera frontal, 2D, ortográfica.
- Cenários em 16:9, 1920x1080.
- Ambientes escuros, góticos, vitorianos.
- Uso forte de sombras, moonlight e tons de madeira escura.
- Zoom-ins também em 1920x1080, mantendo o mesmo estilo do cenário principal.
- Itens de inventário isolados em fundo transparente.

## Tom narrativo

Investigação sombria dentro de uma mansão antiga. O jogador encontra pistas deixadas por moradores anteriores, cartas enigmáticas e objetos pessoais escondidos. A narrativa deve avançar através dos ambientes e dos itens, não por cutscenes longas.

---

# 2. Cômodos principais do jogo

Os quatro backgrounds principais já discutidos/produzidos são:

1. **Office / Escritório**
2. **Master Bedroom / Quarto principal**
3. **Dining Room / Sala de jantar**
4. **Library / Biblioteca**

Esses não devem ser tratados como “quatro paredes de um único quarto”, mas sim como **quatro cômodos diferentes da mansão**.

## Ordem recomendada de implementação

### Primeira entrega

Implementar apenas:

- **Master Bedroom**
- Puzzle completo: **A Caixa de Joias da Senhora**
- Inventário
- Zoom-ins
- Leitura de cartas
- Coleta de itens
- Sistema de puzzle por sequência de símbolos

### Depois da primeira entrega

Implementar o próximo cômodo conectado à chave encontrada no quarto.

Recomendação:

1. Master Bedroom
2. Office
3. Library
4. Dining Room

O **Office** é o melhor próximo cenário porque a chave pequena encontrada na caixa de joias combina naturalmente com uma gaveta, diário, compartimento secreto ou cofre pequeno.

---

# 3. Configuração do projeto Godot

## Project Settings

```text
Display > Window > Size > Viewport Width: 1920
Display > Window > Size > Viewport Height: 1080

Display > Window > Stretch > Mode: canvas_items
Display > Window > Stretch > Aspect: keep
```

## Input Map

Criar as ações:

```text
ui_cancel     -> Escape
pause         -> Escape
inventory     -> I
interact      -> Mouse Left
debug_toggle  -> F1
```

Se futuramente houver troca entre cômodos por setas ou portas:

```text
move_left_room  -> A / Left
move_right_room -> D / Right
```

Mas para o escopo atual, o mais importante é clique em hotspots.

---

# 4. Estrutura de diretórios recomendada

```text
res://
├── scenes/
│   ├── main/
│   │   └── main.tscn
│   ├── rooms/
│   │   ├── bedroom/
│   │   │   ├── bedroom_main.tscn
│   │   │   ├── bedroom_hotspots.tscn
│   │   │   └── bedroom_data.gd
│   │   ├── office/
│   │   │   └── office_main.tscn
│   │   ├── library/
│   │   │   └── library_main.tscn
│   │   └── dining_room/
│   │       └── dining_room_main.tscn
│   ├── zooms/
│   │   ├── bedroom/
│   │   │   ├── zoom_portrait_moon.tscn
│   │   │   ├── zoom_flower_embroidery.tscn
│   │   │   ├── zoom_rug_crown.tscn
│   │   │   ├── zoom_key_book.tscn
│   │   │   ├── zoom_jewelry_box_closed.tscn
│   │   │   ├── zoom_jewelry_box_open.tscn
│   │   │   ├── zoom_wardrobe_with_note.tscn
│   │   │   ├── zoom_wardrobe_without_note.tscn
│   │   │   ├── zoom_chest_drawer_open.tscn
│   │   │   ├── zoom_nightstand_top_open.tscn
│   │   │   └── zoom_nightstand_bottom_open.tscn
│   │   └── shared/
│   ├── puzzles/
│   │   └── symbol_sequence_puzzle.tscn
│   ├── ui/
│   │   ├── inventory_ui.tscn
│   │   ├── item_popup.tscn
│   │   ├── readable_letter_popup.tscn
│   │   ├── hud.tscn
│   │   └── pause_menu.tscn
│   └── menus/
│       ├── main_menu.tscn
│       └── ending_placeholder.tscn
│
├── scripts/
│   ├── autoloads/
│   │   ├── game_state.gd
│   │   ├── inventory.gd
│   │   ├── scene_router.gd
│   │   └── audio_manager.gd
│   ├── core/
│   │   ├── interactable.gd
│   │   ├── zoom_manager.gd
│   │   ├── room_controller.gd
│   │   └── readable_item.gd
│   ├── puzzles/
│   │   └── symbol_sequence_puzzle.gd
│   └── ui/
│       ├── inventory_ui.gd
│       ├── item_popup.gd
│       └── readable_letter_popup.gd
│
├── art/
│   ├── backgrounds/
│   │   ├── bedroom/
│   │   ├── office/
│   │   ├── library/
│   │   └── dining_room/
│   ├── zoom_ins/
│   │   └── bedroom/
│   ├── items/
│   │   └── bedroom/
│   ├── ui/
│   └── cursors/
│
└── audio/
    ├── bgm/
    ├── ambience/
    └── sfx/
```

---

# 5. Autoloads necessários

## Autoloads recomendados

```text
GameState     -> res://scripts/autoloads/game_state.gd
Inventory     -> res://scripts/autoloads/inventory.gd
SceneRouter   -> res://scripts/autoloads/scene_router.gd
AudioManager  -> res://scripts/autoloads/audio_manager.gd
```

## Responsabilidades

### GameState

Guarda flags globais e estados de puzzles.

Exemplos:

```gdscript
bedroom_jacket_note_collected
bedroom_jewelry_box_solved
bedroom_small_key_collected
bedroom_box_letter_collected
```

### Inventory

Guarda itens coletados.

Exemplos:

```gdscript
item_jacket_note
item_small_victorian_key
item_box_letter
```

### SceneRouter

Controla transições entre cômodos.

Exemplos:

```gdscript
go_to_room("bedroom")
go_to_room("office")
```

### AudioManager

Controla SFX, BGM e ambiência.

---

# 6. Estrutura da cena principal

## `main.tscn`

```text
Main (Node)
├── CurrentRoomContainer (Node)
├── ZoomLayer (CanvasLayer)
│   └── ZoomManager (Control)
├── UILayer (CanvasLayer)
│   ├── HUD
│   ├── InventoryUI
│   └── CursorHint
├── FadeLayer (CanvasLayer)
│   └── FadeRect
└── PauseLayer (CanvasLayer)
    └── PauseMenu
```

## Funcionamento

- `CurrentRoomContainer` contém o cômodo atual.
- Ao trocar de cômodo, remove a cena atual e instancia outra.
- `ZoomLayer` abre zoom-ins sobre o cômodo.
- `UILayer` fica sempre visível.
- `FadeLayer` serve para transições.

---

# 7. Sistema de cômodos

Cada cômodo deve ser uma cena própria.

## Exemplo: `bedroom_main.tscn`

```text
BedroomMain (Node2D)
├── Background (Sprite2D)
├── Hotspots (Node2D)
│   ├── PortraitHotspot (Area2D)
│   ├── FlowerHotspot (Area2D)
│   ├── RugHotspot (Area2D)
│   ├── WritingDeskHotspot (Area2D)
│   ├── JewelryBoxHotspot (Area2D)
│   ├── WardrobeHotspot (Area2D)
│   ├── ChestDrawersHotspot (Area2D)
│   ├── LeftNightstandHotspot (Area2D)
│   └── RightNightstandHotspot (Area2D)
└── RoomController
```

Cada hotspot abre um zoom-in ou executa uma ação.

---

# 8. Sistema de hotspots

## Script base: `interactable.gd`

```gdscript
class_name Interactable
extends Area2D

signal interacted(interaction_id: String)

@export var interaction_id: String = ""
@export var enabled_flag: String = ""
@export var disabled_flag: String = ""

var is_hovered := false

func _ready() -> void:
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	is_hovered = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)

func _on_mouse_exited() -> void:
	is_hovered = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)

func _on_input_event(_viewport, event, _shape_idx) -> void:
	if not _is_available():
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			AudioManager.play_sfx("click")
			interacted.emit(interaction_id)

func _is_available() -> bool:
	if enabled_flag != "" and not GameState.get_flag(enabled_flag):
		return false
	if disabled_flag != "" and GameState.get_flag(disabled_flag):
		return false
	return true
```

---

# 9. Sistema de zoom-ins

## Ideia

Zoom-ins são telas estáticas em 1920x1080 que aparecem sobre o cenário principal. Eles podem ter hotspots internos para coletar itens ou abrir puzzles.

## Script: `zoom_manager.gd`

```gdscript
extends Control

signal zoom_opened(zoom_id: String)
signal zoom_closed

@onready var zoom_root: Control = $ZoomRoot

var current_zoom: Node = null

var zoom_scenes := {
	"portrait_moon": preload("res://scenes/zooms/bedroom/zoom_portrait_moon.tscn"),
	"flower_embroidery": preload("res://scenes/zooms/bedroom/zoom_flower_embroidery.tscn"),
	"rug_crown": preload("res://scenes/zooms/bedroom/zoom_rug_crown.tscn"),
	"key_book": preload("res://scenes/zooms/bedroom/zoom_key_book.tscn"),
	"jewelry_box_closed": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_closed.tscn"),
	"jewelry_box_open": preload("res://scenes/zooms/bedroom/zoom_jewelry_box_open.tscn"),
	"wardrobe_with_note": preload("res://scenes/zooms/bedroom/zoom_wardrobe_with_note.tscn"),
	"wardrobe_without_note": preload("res://scenes/zooms/bedroom/zoom_wardrobe_without_note.tscn"),
	"chest_drawer_open": preload("res://scenes/zooms/bedroom/zoom_chest_drawer_open.tscn"),
	"nightstand_top_open": preload("res://scenes/zooms/bedroom/zoom_nightstand_top_open.tscn"),
	"nightstand_bottom_open": preload("res://scenes/zooms/bedroom/zoom_nightstand_bottom_open.tscn"),
}

func _ready() -> void:
	visible = false

func open_zoom(zoom_id: String) -> void:
	if current_zoom != null:
		return
	if not zoom_scenes.has(zoom_id):
		push_warning("Zoom não encontrado: " + zoom_id)
		return

	current_zoom = zoom_scenes[zoom_id].instantiate()
	zoom_root.add_child(current_zoom)
	visible = true

	var tween := create_tween()
	current_zoom.modulate.a = 0.0
	tween.tween_property(current_zoom, "modulate:a", 1.0, 0.2)

	zoom_opened.emit(zoom_id)

func close_zoom() -> void:
	if current_zoom == null:
		return

	var zoom_to_close := current_zoom
	current_zoom = null

	var tween := create_tween()
	tween.tween_property(zoom_to_close, "modulate:a", 0.0, 0.15)
	tween.tween_callback(func():
		zoom_to_close.queue_free()
		visible = false
		zoom_closed.emit()
	)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close_zoom()
```

---

# 10. Inventário

## Itens do Master Bedroom

```text
item_jacket_note
item_small_victorian_key
item_box_letter
```

## Script: `inventory.gd`

```gdscript
extends Node

signal item_added(item_id: String)
signal item_removed(item_id: String)
signal inventory_changed

var items: Array[String] = []

func add_item(item_id: String) -> bool:
	if item_id in items:
		return false

	items.append(item_id)
	item_added.emit(item_id)
	inventory_changed.emit()
	AudioManager.play_sfx("item_pickup")
	return true

func remove_item(item_id: String) -> void:
	if item_id not in items:
		return

	items.erase(item_id)
	item_removed.emit(item_id)
	inventory_changed.emit()

func has_item(item_id: String) -> bool:
	return item_id in items

func clear() -> void:
	items.clear()
	inventory_changed.emit()
```

## Banco de dados simples dos itens

Criar um arquivo:

```text
res://scripts/data/item_database.gd
```

Exemplo:

```gdscript
class_name ItemDatabase

const ITEMS := {
	"item_jacket_note": {
		"name": "Carta dobrada",
		"icon": "res://art/items/bedroom/jacket_note.png",
		"type": "readable",
		"text": "Quando a noite entrar sem ser convidada..."
	},
	"item_small_victorian_key": {
		"name": "Chave pequena",
		"icon": "res://art/items/bedroom/small_key.png",
		"type": "key",
		"text": ""
	},
	"item_box_letter": {
		"name": "Carta selada",
		"icon": "res://art/items/bedroom/box_letter.png",
		"type": "readable",
		"text": "Ele nunca confiou nas fechaduras grandes..."
	}
}
```

---

# 11. Leitura de cartas

As imagens dos itens não devem conter texto real legível. Elas podem ter rabiscos. O texto real deve aparecer na UI.

## Cena: `readable_letter_popup.tscn`

```text
ReadableLetterPopup (Control)
├── DarkOverlay (ColorRect)
├── Panel (NinePatchRect / PanelContainer)
│   ├── ItemImage (TextureRect)
│   ├── TitleLabel (Label)
│   ├── BodyLabel (RichTextLabel)
│   └── CloseButton (Button)
```

## Comportamento

- Ao clicar em uma carta no inventário, abrir modal.
- Mostrar imagem do item.
- Mostrar texto legível na interface.
- Fechar com botão ou Escape.

---

# 12. Puzzle principal da primeira entrega

## Puzzle: “A Caixa de Joias da Senhora”

### Objetivo

Abrir a caixa de joias na penteadeira.

### Pistas estáticas

| Símbolo | Onde está |
|---|---|
| Lua | Colar/broche no retrato |
| Flor | Bordado floral no tecido do quarto |
| Coroa | Área iluminada pela lua no tapete |
| Chave | Livro na escrivaninha |

### Ordem correta

```text
Lua → Flor → Coroa → Chave
```

### Símbolos disponíveis na caixa

```text
Lua
Flor
Coroa
Chave
Pássaro
Estrela
```

Os símbolos **Pássaro** e **Estrela** são distrações.

---

# 13. Enigma da carta da jaqueta

A carta coletada no armário deve indicar a ordem dos símbolos sem ser óbvia demais.

Texto recomendado:

```text
Quando a noite entrar sem ser convidada, não procure primeiro nas mãos dos vivos.

Comece por aquilo que repousa sobre o peito de quem já não fala.
Depois, siga para a flor que nunca murcha, costurada no assento do descanso.
Onde a luz fria tocar o chão, curve-se diante da coroa esquecida.
Por fim, busque no livro fechado aquilo que abre o que foi calado.

Só nessa ordem a lembrança dela consentirá em se revelar.
```

Interpretação:

```text
Peito de quem já não fala -> retrato -> Lua
Flor que nunca murcha -> bordado -> Flor
Luz fria no chão -> tapete -> Coroa
Livro fechado -> livro da escrivaninha -> Chave
```

---

# 14. Puzzle de sequência de símbolos

## Cena

```text
symbol_sequence_puzzle.tscn
```

## Árvore sugerida

```text
SymbolSequencePuzzle (Control)
├── BackgroundImage / JewelryBoxImage
├── SymbolButtons
│   ├── MoonButton
│   ├── FlowerButton
│   ├── CrownButton
│   ├── KeyButton
│   ├── BirdButton
│   └── StarButton
├── InputPreview
├── ClearButton
└── ConfirmButton
```

## Script: `symbol_sequence_puzzle.gd`

```gdscript
extends Control

signal puzzle_solved

@export var puzzle_flag: String = "bedroom_jewelry_box_solved"

var correct_sequence: Array[String] = ["moon", "flower", "crown", "key"]
var current_sequence: Array[String] = []

func press_symbol(symbol_id: String) -> void:
	if current_sequence.size() >= correct_sequence.size():
		return

	current_sequence.append(symbol_id)
	AudioManager.play_sfx("symbol_press")
	_update_preview()

	if current_sequence.size() == correct_sequence.size():
		_check_solution()

func clear_sequence() -> void:
	current_sequence.clear()
	_update_preview()

func _check_solution() -> void:
	if current_sequence == correct_sequence:
		GameState.set_flag(puzzle_flag, true)
		AudioManager.play_sfx("puzzle_correct")
		puzzle_solved.emit()
	else:
		AudioManager.play_sfx("code_wrong")
		current_sequence.clear()
		_update_preview()

func _update_preview() -> void:
	# Atualizar UI visual da sequência escolhida.
	pass
```

---

# 15. Estados do GameState

## Script: `game_state.gd`

```gdscript
extends Node

signal flag_changed(flag_name: String, value: bool)

var flags: Dictionary = {}

func set_flag(flag_name: String, value: bool = true) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)

func get_flag(flag_name: String) -> bool:
	return flags.get(flag_name, false)

func reset() -> void:
	flags.clear()
```

## Flags do Master Bedroom

```text
bedroom_jacket_note_collected
bedroom_jacket_note_read
bedroom_jewelry_box_solved
bedroom_small_key_collected
bedroom_box_letter_collected
bedroom_box_letter_read
```

## Estados derivados

A imagem do armário depende de:

```text
bedroom_jacket_note_collected == false -> wardrobe_with_note
bedroom_jacket_note_collected == true  -> wardrobe_without_note
```

A imagem da caixa depende de:

```text
bedroom_jewelry_box_solved == false -> jewelry_box_closed
bedroom_jewelry_box_solved == true  -> jewelry_box_open
```

---

# 16. Hotspots do Master Bedroom

## Hotspots no background principal

### `hotspot_portrait`

Ação:

```text
open_zoom("portrait_moon")
```

### `hotspot_flower`

Ação:

```text
open_zoom("flower_embroidery")
```

### `hotspot_rug`

Ação:

```text
open_zoom("rug_crown")
```

### `hotspot_writing_desk`

Ação:

```text
open_zoom("key_book")
```

### `hotspot_jewelry_box`

Ação:

```gdscript
if GameState.get_flag("bedroom_jewelry_box_solved"):
	ZoomManager.open_zoom("jewelry_box_open")
else:
	ZoomManager.open_zoom("jewelry_box_closed")
```

### `hotspot_wardrobe`

Ação:

```gdscript
if GameState.get_flag("bedroom_jacket_note_collected"):
	ZoomManager.open_zoom("wardrobe_without_note")
else:
	ZoomManager.open_zoom("wardrobe_with_note")
```

### `hotspot_chest_drawers`

Ação:

```text
open_zoom("chest_drawer_open")
```

### `hotspot_nightstand_left`

Ação:

```text
open_zoom("nightstand_top_open") ou variação equivalente
```

### `hotspot_nightstand_right`

Ação:

```text
open_zoom("nightstand_bottom_open") ou variação equivalente
```

---

# 17. Hotspots internos dos zoom-ins

## `zoom_wardrobe_with_note`

Hotspot:

```text
jacket_note_hotspot
```

Ação:

```gdscript
Inventory.add_item("item_jacket_note")
GameState.set_flag("bedroom_jacket_note_collected", true)
ZoomManager.open_zoom("wardrobe_without_note")
```

Opcionalmente, fechar e reabrir o zoom sem carta.

## `zoom_jewelry_box_closed`

Ação:

- Abrir `symbol_sequence_puzzle`.
- Ao resolver:
  - Setar `bedroom_jewelry_box_solved`.
  - Trocar para `zoom_jewelry_box_open`.

## `zoom_jewelry_box_open`

Hotspots:

```text
small_key_hotspot
box_letter_hotspot
```

Ações:

```gdscript
Inventory.add_item("item_small_victorian_key")
GameState.set_flag("bedroom_small_key_collected", true)
```

```gdscript
Inventory.add_item("item_box_letter")
GameState.set_flag("bedroom_box_letter_collected", true)
```

Se ambos já foram coletados, a imagem ideal seria uma versão futura da caixa aberta vazia. Para a primeira entrega, isso pode ser ignorado ou resolvido escondendo os hotspots.

---

# 18. Texto da carta da caixa

A carta da caixa deve indicar onde a chave será usada em outro cenário.

Como o próximo cenário recomendado é o Office, a carta pode apontar para um diário, gaveta ou compartimento secreto.

Texto provisório recomendado:

```text
Ele nunca confiou nas fechaduras grandes.

Guardava o que importava onde ninguém pensaria em procurar:
não atrás da porta,
mas dentro daquilo que registra seus pecados.

A chave pequena pertence ao silêncio da escrivaninha.
```

Interpretação:

- A chave pequena deve ser usada no escritório.
- Provavelmente em uma escrivaninha, diário ou gaveta trancada.

---

# 19. Sistema de troca entre cômodos

Para a primeira entrega, o jogador pode começar diretamente no Bedroom.

Depois, implementar um mapa simples ou portas clicáveis.

## Opção recomendada para expansão

Cada cômodo tem hotspots de saída:

```text
Bedroom -> Hallway ou Office
Office -> Bedroom / Library
Library -> Dining Room
Dining Room -> Hallway
```

Para não aumentar demais o escopo, a primeira entrega pode usar apenas:

```text
Bedroom
```

e mostrar uma mensagem ao final:

```text
Você encontrou uma chave e uma nova pista. O segredo continua em outro cômodo...
```

---

# 20. Áudio

## SFX necessários para primeira entrega

```text
click
zoom_open
zoom_close
item_pickup
paper_open
symbol_press
puzzle_wrong
puzzle_correct
box_open
drawer_open
wardrobe_open
```

## BGM / Ambiência

Para o bedroom:

- ambiente noturno baixo;
- vento fraco;
- madeira rangendo ocasionalmente;
- talvez relógio distante.

O áudio deve ser sutil. O jogo depende mais de atmosfera do que de ação.

---

# 21. UI recomendada

## HUD

Elementos mínimos:

- Inventário na parte inferior ou lateral.
- Cursor muda ao passar por hotspot.
- Mensagens curtas de feedback.
- Botão de voltar nos zoom-ins.

## Mensagens curtas

Exemplos:

```text
Nada aqui.
Está trancado.
Você pegou uma carta.
A ordem parece incorreta.
A caixa se abriu.
```

---

# 22. Menus

Para primeira entrega:

- Main Menu
- Pause Menu
- Tela final simples ou mensagem de fim da demo

## Main Menu

```text
Novo Jogo
Continuar, se houver save
Sair
```

## Pause Menu

```text
Continuar
Reiniciar
Sair
```

Save/load não é obrigatório para a primeira entrega.

---

# 23. Ordem de implementação atualizada

## Fase 1 — Base técnica

1. Criar projeto Godot 4.
2. Configurar resolução 1920x1080.
3. Criar autoloads:
   - GameState
   - Inventory
   - SceneRouter
   - AudioManager
4. Criar `main.tscn`.
5. Criar `bedroom_main.tscn` com background.
6. Criar sistema de hotspots.
7. Criar sistema de zoom-ins.
8. Criar botão ou tecla para voltar do zoom.

## Fase 2 — Exploração do Bedroom

1. Adicionar hotspots do quarto.
2. Abrir zoom-ins:
   - retrato;
   - flor;
   - tapete;
   - livro;
   - armário;
   - caixa de joias;
   - gavetas opcionais.
3. Garantir que cada zoom-in abre e fecha corretamente.
4. Ajustar colisões dos hotspots.

## Fase 3 — Inventário

1. Criar UI de inventário.
2. Adicionar item ao inventário.
3. Mostrar ícone do item.
4. Clicar no item para inspecionar.
5. Ler cartas em modal próprio.

## Fase 4 — Armário e carta da jaqueta

1. Implementar `zoom_wardrobe_with_note`.
2. Criar hotspot da carta no bolso.
3. Coletar `item_jacket_note`.
4. Trocar estado para `zoom_wardrobe_without_note`.
5. Permitir leitura da carta no inventário.

## Fase 5 — Puzzle da caixa de joias

1. Implementar `zoom_jewelry_box_closed`.
2. Criar puzzle de sequência de símbolos.
3. Implementar os símbolos:
   - lua;
   - flor;
   - coroa;
   - chave;
   - pássaro;
   - estrela.
4. Validar sequência:
   - lua;
   - flor;
   - coroa;
   - chave.
5. Em caso de acerto, tocar som e marcar puzzle resolvido.
6. Trocar para `zoom_jewelry_box_open`.

## Fase 6 — Recompensas

1. Na caixa aberta, coletar:
   - `item_small_victorian_key`;
   - `item_box_letter`.
2. Permitir leitura da carta da caixa.
3. Exibir mensagem de fim da primeira entrega.

## Fase 7 — Polimento

1. Adicionar SFX.
2. Adicionar fade em zoom-ins.
3. Ajustar cursor.
4. Ajustar mensagens de feedback.
5. Testar o puzzle sem consultar a solução.
6. Verificar se o jogador entende o enigma.
7. Remover bugs de coleta duplicada.

---

# 24. Critérios de conclusão da primeira entrega

A primeira entrega está pronta quando:

- O jogador consegue abrir o Master Bedroom.
- O jogador consegue clicar nos hotspots principais.
- Todos os zoom-ins principais abrem.
- O jogador consegue coletar a carta da jaqueta.
- A carta da jaqueta aparece no inventário.
- O jogador consegue ler o enigma.
- O jogador consegue abrir a caixa de joias.
- O jogador consegue inserir a sequência correta.
- A caixa troca para o estado aberto.
- O jogador consegue coletar a chave e a carta da caixa.
- O inventário mantém os itens corretamente.
- O jogo mostra um encerramento provisório da demo.

Não é necessário na primeira entrega:

- Implementar todos os quatro cômodos.
- Implementar uso real da chave.
- Implementar save/load.
- Implementar mapa da mansão.
- Implementar todos os puzzles finais.
- Implementar animações complexas.

---

# 25. Diferenças importantes em relação ao plano anterior

O plano antigo tratava o jogo como um escape room preso em um escritório com quatro paredes. O plano atual deve ser entendido como:

```text
Mansão point-and-click com múltiplos cômodos.
```

Mudanças principais:

1. As quatro imagens principais são cômodos, não paredes.
2. O primeiro cenário jogável é o Master Bedroom, não o escritório.
3. O puzzle principal da primeira entrega é a caixa de joias, não senha numérica.
4. A progressão é feita por cartas, itens e pistas visuais.
5. O sistema precisa priorizar:
   - zoom-ins;
   - inventário;
   - leitura de cartas;
   - hotspots;
   - puzzle de sequência.
6. O código deve ser modular para reaproveitar o sistema em Office, Library e Dining Room depois.
7. O uso da chave fica para o próximo cenário.

---

# 26. Próximo cenário recomendado

Depois de finalizar o Bedroom, implementar o **Office**.

## Ideia inicial do Office

A chave pequena encontrada na caixa de joias abre:

- uma gaveta trancada da escrivaninha;
- um diário fechado;
- uma caixa pequena;
- ou um compartimento oculto.

Dentro, o jogador encontra uma pista que leva à Library ou Dining Room.

## Possível fluxo

```text
Bedroom -> chave pequena -> Office -> diário/gaveta -> nova pista -> Library
```

---

# 27. Resumo para o Codex

Implementar primeiro uma vertical slice do Master Bedroom.

Foco imediato:

```text
Bedroom background
Hotspots
Zoom-ins
Inventory
Readable letters
Jewelry box symbol puzzle
State changes
Reward items
Demo ending
```

Não implementar ainda:

```text
Todos os cômodos
Todos os puzzles
Save/load
Sistema complexo de mapa
```

O objetivo é provar que o loop principal do jogo funciona:

```text
Explorar -> observar pistas -> coletar carta -> entender enigma -> resolver puzzle -> ganhar item -> receber próxima direção
```
