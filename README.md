# CONFISSAO

Jogo de aventura point-and-click feito em Godot. O jogador explora uma casa, observa detalhes dos ambientes, coleta itens, lê cartas e resolve pequenos enigmas para avançar pela narrativa.

## Sobre o projeto

`CONFISSAO` e um jogo 2D com foco em investigacao, atmosfera e interacao por clique. A experiencia comeca no quarto e se expande para outros comodos por meio do corredor, incluindo escritorio, biblioteca e sala de jantar.

O projeto usa:

- Sistema de salas com transicoes.
- Inventario com itens coletaveis, inspecionaveis e cartas legiveis.
- Cenas de zoom para examinar objetos de perto.
- Puzzles integrados ao estado do jogo.
- Menus de inicio, pausa e vitoria.
- Cursores customizados para indicar tipos de interacao.

## Requisitos

- Godot 4.6 ou superior.
- Sistema operacional compativel com Godot.

O projeto esta configurado com:

- Cena principal: `res://scenes/main/main.tscn`
- Resolucao base: `1920x1080`
- Stretch mode: `canvas_items`

## Como executar

1. Abra o Godot.
2. Clique em **Import**.
3. Selecione o arquivo `project.godot`.
4. Abra o projeto.
5. Pressione **Run Project** ou `F5`.

## Controles

- Botao esquerdo do mouse: interagir com objetos, portas e itens.
- `I`: abrir/usar o inventario.
- `Esc`: abrir o menu de pausa ou fechar uma cena de zoom.

Durante o jogo, o cursor muda para indicar a acao disponivel: interagir, coletar, inspecionar, agarrar ou bloqueado.

## Estrutura de pastas

```text
art/
  backgrounds/       Fundos dos ambientes
  cursors/           Cursores customizados
  items/             Arte dos itens de inventario
  ui/                Elementos visuais da interface
  zoom_ins/          Imagens usadas nas cenas de zoom

scenes/
  main/              Cena principal do jogo
  puzzles/           Cenas dos puzzles
  rooms/             Cenas dos comodos
  ui/                Menus, inventario e popups
  zooms/             Cenas de detalhe/inspecao

scripts/
  autoloads/         Estado global, inventario e audio
  core/              Interacoes e gerenciamento de zoom
  data/              Base de dados dos itens
  puzzles/           Logica dos puzzles
  rooms/             Controladores dos ambientes
  ui/                Scripts da interface
```

## Sistemas principais

### Estado do jogo

O estado global fica em `scripts/autoloads/game_state.gd`. Ele armazena flags e valores usados para controlar progresso, itens coletados, puzzles resolvidos e variacoes visuais das salas.

### Inventario

O inventario fica em `scripts/autoloads/inventory.gd`. Ele controla adicao, remocao e verificacao de itens. Os dados dos itens ficam em `scripts/data/item_database.gd`.

### Interacoes

As areas clicaveis usam scripts como `scripts/core/interactable.gd` e `scripts/core/ui_interactable.gd`. Cada interacao dispara um `interaction_id`, que e interpretado pelo controlador principal em `scripts/main.gd`.

### Zooms

As cenas de zoom sao gerenciadas por `scripts/core/zoom_manager.gd`. Elas permitem examinar partes do ambiente de perto e podem abrir outros zooms sem perder o contexto anterior.

### Puzzles

O projeto possui puzzles de sequencia simbolica e de pendulos. A conclusao dos puzzles altera flags no estado global, liberando novos itens, cenas ou estados visuais.

## Fluxo geral do jogo

1. O jogo inicia no quarto.
2. O jogador explora objetos e coleta pistas.
3. A caixa de joias libera itens importantes depois de um puzzle.
4. A chave pequena permite sair do quarto.
5. O corredor conecta os outros ambientes.
6. A sala de jantar contem o puzzle do relogio.
7. A vitoria acontece quando os itens principais sao encontrados.

## Desenvolvimento

Para adicionar uma nova sala:

1. Crie a cena em `scenes/rooms/`.
2. Adicione um controlador semelhante aos scripts em `scripts/rooms/`.
3. Registre a cena no dicionario `room_scenes` em `scripts/main.gd`.
4. Crie interacoes com `interaction_id`.
5. Trate o novo `interaction_id` em `_on_room_interaction_requested`.

Para adicionar um novo item:

1. Adicione a arte em `art/items/`.
2. Cadastre o item em `scripts/data/item_database.gd`.
3. Use `Inventory.add_item("id_do_item")` quando ele for coletado.
4. Use flags em `GameState` se o item alterar o progresso do jogo.

## Observacoes

- Os arquivos `.uid` sao gerados pelo Godot e devem permanecer junto aos recursos correspondentes.
- Edite `project.godot` preferencialmente pela interface do Godot.
- Mantenha os caminhos `res://` atualizados ao mover assets, cenas ou scripts.
