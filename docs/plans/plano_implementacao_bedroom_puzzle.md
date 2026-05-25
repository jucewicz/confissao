# Plano de Implementação — Puzzle “A Caixa de Joias da Senhora”

## Objetivo deste documento

Este arquivo serve como ponto de partida para implementar o primeiro cenário jogável do projeto: o **Master Bedroom**. A ideia é criar uma primeira versão funcional do jogo com um puzzle completo, usando os assets e zoom-ins já produzidos.

A prioridade agora não é implementar todos os cenários da mansão, mas sim criar uma **vertical slice jogável**: um cenário com exploração, hotspots, zoom-ins, inventário, item coletável, leitura de cartas, puzzle de sequência e recompensa.

---

## Cenário inicial da entrega

### Cenário implementado

**Master Bedroom**

Este cenário deve funcionar como o primeiro ambiente completo de teste do jogo. Ele contém o puzzle principal:

**Puzzle: “A Caixa de Joias da Senhora”**

### Objetivo do puzzle

O jogador deve descobrir a sequência correta de símbolos para abrir a caixa de joias localizada na penteadeira.

### Sequência correta

**Lua → Flor → Coroa → Chave**

### Recompensa

Ao abrir a caixa de joias, o jogador recebe:

1. **Uma chave pequena**
2. **Uma carta dobrada**

A chave será usada futuramente em outro cenário, como escritório, biblioteca ou cozinha. A carta dobrada deve dar uma dica de onde essa chave deve ser usada.

---

## Fluxo completo do puzzle

1. O jogador entra no Master Bedroom.
2. O jogador explora o cenário clicando em hotspots.
3. O jogador encontra pistas visuais nos zoom-ins:
   - Retrato: símbolo da **Lua**
   - Sofá/colcha/bordado floral: símbolo da **Flor**
   - Tapete iluminado pela lua: símbolo da **Coroa**
   - Livro na escrivaninha: símbolo da **Chave**
4. O jogador abre o armário.
5. Dentro do armário, há jaquetas penduradas.
6. Em uma jaqueta azul-marinho, há uma carta no bolso frontal.
7. O jogador coleta essa carta.
8. A carta contém um enigma indicando a ordem dos símbolos.
9. O jogador interage com a caixa de joias.
10. O jogador insere a sequência correta: **Lua → Flor → Coroa → Chave**.
11. A caixa abre.
12. O jogador coleta a chave pequena e a carta dobrada.
13. O puzzle do quarto é marcado como resolvido.

---

## Assets necessários do cenário

### Background principal

- `master_bedroom_background`
  - Imagem principal do quarto.
  - Deve conter cama, armário, gaveteiro, criados-mudos, penteadeira, sofá, tapete, retrato, janela e escrivaninha.

### Zoom-ins obrigatórios do puzzle

1. `zoom_portrait_moon`
   - Retrato com colar ou broche de lua.
   - Entrega a pista da **Lua**.

2. `zoom_bedcover_or_sofa_flower`
   - Bordado floral em tecido.
   - Entrega a pista da **Flor**.

3. `zoom_rug_crown`
   - Área iluminada do tapete com coroa.
   - Entrega a pista da **Coroa**.

4. `zoom_writing_desk_key_book`
   - Livro na escrivaninha com símbolo de chave.
   - Entrega a pista da **Chave**.

5. `zoom_jewelry_box_closed`
   - Caixa de joias fechada com mecanismo de símbolos.
   - Interface do puzzle.

6. `zoom_jewelry_box_open`
   - Caixa aberta contendo chave pequena e carta dobrada.
   - Estado resolvido da caixa.

### Zoom-ins adicionais já definidos

7. `zoom_chest_drawer_open`
   - Gaveta aberta do gaveteiro alto.
   - Pode ser reutilizado para gavetas vazias.

8. `zoom_nightstand_top_drawer_open`
   - Gaveta superior do criado-mudo aberta.

9. `zoom_nightstand_bottom_drawer_open`
   - Gaveta inferior do criado-mudo aberta.

10. `zoom_wardrobe_open_with_note`
   - Armário aberto com jaquetas e carta no bolso da jaqueta azul-marinho.

11. `zoom_wardrobe_open_without_note`
   - Mesmo armário aberto, mas sem a carta após coleta.

---

## Itens de inventário

### 1. Carta da jaqueta

ID sugerido:

`item_jacket_note`

Função:

- Contém o enigma que indica a ordem dos símbolos.
- Deve ser coletada no armário.
- Depois de coletada, o armário deve passar a usar a imagem sem carta.

Texto sugerido da carta:

> Quando a noite entrar sem ser convidada, não procure primeiro nas mãos dos vivos.  
> Comece por aquilo que repousa sobre o peito de quem já não fala.  
> Depois, siga para a flor que nunca murcha, costurada no assento do descanso.  
> Onde a luz fria tocar o chão, curve-se diante da coroa esquecida.  
> Por fim, busque no livro fechado aquilo que abre o que foi calado.  
> Só nessa ordem a lembrança dela consentirá em se revelar.

Solução indicada:

- Peito de quem já não fala → retrato → **Lua**
- Flor que nunca murcha → bordado → **Flor**
- Luz fria no chão → tapete iluminado → **Coroa**
- Livro fechado → livro da escrivaninha → **Chave**

Sequência:

**Lua → Flor → Coroa → Chave**

---

### 2. Chave pequena

ID sugerido:

`item_small_victorian_key`

Função:

- Coletada dentro da caixa de joias após resolver o puzzle.
- Deve abrir um compartimento, gaveta ou objeto em outro cenário.
- Por enquanto, pode ficar no inventário sem uso implementado.

Descrição curta para inventário:

> Uma pequena chave vitoriana de latão envelhecido. Delicada demais para uma porta comum.

---

### 3. Carta da caixa

ID sugerido:

`item_box_letter`

Função:

- Coletada dentro da caixa de joias junto com a chave.
- Dá uma dica de onde a chave deve ser usada.
- Deve conectar o quarto ao próximo cenário.

Texto provisório sugerido:

> Ele nunca confiou nas fechaduras grandes.  
> Guardava o que importava onde ninguém pensaria em procurar:  
> não atrás da porta, mas dentro daquilo que registra seus pecados.

Interpretação sugerida:

- A chave deve abrir algo no **escritório**, possivelmente uma gaveta secreta da escrivaninha, um diário trancado ou um compartimento ligado a documentos.

---

## Hotspots do Master Bedroom

Cada hotspot deve ter:

- ID
- Área clicável no background
- Ação ao clicar
- Estado necessário, se houver
- Texto de feedback, se necessário

### Lista inicial de hotspots

#### `hotspot_portrait`

Ação:

- Abre `zoom_portrait_moon`.

Texto opcional:

> O retrato observa o quarto em silêncio. Algo frio brilha junto ao peito da figura.

---

#### `hotspot_bed_or_sofa_flower`

Ação:

- Abre `zoom_bedcover_or_sofa_flower`.

Texto opcional:

> O tecido antigo guarda padrões cuidadosos, repetidos como se obedecessem a uma ordem.

---

#### `hotspot_rug_moonlight`

Ação:

- Abre `zoom_rug_crown`.

Texto opcional:

> A luz da lua atravessa o quarto e toca uma parte específica do tapete.

---

#### `hotspot_writing_desk_book`

Ação:

- Abre `zoom_writing_desk_key_book`.

Texto opcional:

> Um livro fechado repousa sobre a escrivaninha. A capa parece marcada por um símbolo.

---

#### `hotspot_jewelry_box`

Ação:

- Se a caixa ainda estiver fechada: abre `zoom_jewelry_box_closed`.
- Se o puzzle já foi resolvido: abre `zoom_jewelry_box_open`.

---

#### `hotspot_wardrobe`

Ação:

- Se `item_jacket_note` ainda não foi coletado: abre `zoom_wardrobe_open_with_note`.
- Se `item_jacket_note` já foi coletado: abre `zoom_wardrobe_open_without_note`.

---

#### `hotspot_jacket_note`

Disponível em:

`zoom_wardrobe_open_with_note`

Ação:

- Coleta `item_jacket_note`.
- Atualiza estado: `jacket_note_collected = true`.
- Troca o zoom futuro do armário para `zoom_wardrobe_open_without_note`.

Texto opcional:

> Havia uma carta dobrada no bolso da jaqueta.

---

#### `hotspot_jewelry_box_key`

Disponível em:

`zoom_jewelry_box_open`

Ação:

- Coleta `item_small_victorian_key`.

Texto opcional:

> Uma pequena chave de latão envelhecido.

---

#### `hotspot_jewelry_box_letter`

Disponível em:

`zoom_jewelry_box_open`

Ação:

- Coleta `item_box_letter`.

Texto opcional:

> Uma carta cuidadosamente dobrada foi deixada junto da chave.

---

## Estados do puzzle

Estados mínimos recomendados:

```js
const gameState = {
  bedroom: {
    jacketNoteCollected: false,
    jewelryBoxSolved: false,
    smallKeyCollected: false,
    boxLetterCollected: false,
  },
  inventory: []
};
```

Estados opcionais:

```js
const puzzleState = {
  jewelryBoxInput: [],
  inspectedPortrait: false,
  inspectedFlower: false,
  inspectedRug: false,
  inspectedBook: false,
  readJacketNote: false,
  readBoxLetter: false,
};
```

---

## Puzzle da caixa de joias

### Símbolos disponíveis

- Lua
- Flor
- Coroa
- Chave
- Pássaro
- Estrela

### Solução

```js
const jewelryBoxSolution = ["moon", "flower", "crown", "key"];
```

### Entrada do jogador

O jogador deve selecionar quatro símbolos em ordem.

Sugestão de comportamento:

- Cada clique em um símbolo adiciona o símbolo à sequência atual.
- Mostrar visualmente a sequência escolhida.
- Permitir limpar a entrada.
- Quando houver quatro símbolos, validar automaticamente ou exigir botão de confirmar.

### Em caso de erro

Texto sugerido:

> O mecanismo resiste. A ordem parece incorreta.

A entrada pode ser limpa automaticamente.

### Em caso de acerto

Texto sugerido:

> Um clique seco rompe o silêncio. A caixa se abre.

Atualizar:

```js
gameState.bedroom.jewelryBoxSolved = true;
```

Depois disso, exibir `zoom_jewelry_box_open`.

---

## Sistema mínimo necessário para implementar agora

### 1. Sistema de cenas

Necessário para trocar entre:

- cenário principal do quarto;
- zoom-ins;
- telas de item/carta;
- puzzle da caixa.

Estrutura sugerida:

```js
currentScene = "bedroom_main";
```

Exemplos:

```js
"bedroom_main"
"zoom_portrait_moon"
"zoom_rug_crown"
"zoom_wardrobe_open_with_note"
"zoom_jewelry_box_closed"
"zoom_jewelry_box_open"
```

---

### 2. Sistema de hotspots

Cada cena deve ter uma lista de áreas clicáveis.

Exemplo conceitual:

```js
const hotspots = {
  bedroom_main: [
    {
      id: "portrait",
      x: 620,
      y: 140,
      width: 190,
      height: 170,
      action: () => goToScene("zoom_portrait_moon")
    }
  ]
};
```

As coordenadas devem ser ajustadas de acordo com o tamanho real do canvas/imagem.

---

### 3. Sistema de zoom-ins

Em qualquer zoom-in, deve existir uma forma de voltar ao quarto.

Sugestão:

- tecla ESC;
- botão “Voltar”;
- clique com botão direito;
- hotspot discreto no canto da tela.

---

### 4. Sistema de inventário

O inventário deve permitir:

- adicionar item;
- verificar se item já foi coletado;
- abrir/inspecionar item;
- ler cartas.

Estrutura sugerida:

```js
const items = {
  item_jacket_note: {
    name: "Carta dobrada",
    description: "Uma carta antiga retirada do bolso de uma jaqueta azul-marinho.",
    type: "readable",
    text: "..."
  },
  item_small_victorian_key: {
    name: "Chave pequena",
    description: "Uma pequena chave vitoriana de latão envelhecido.",
    type: "key"
  },
  item_box_letter: {
    name: "Carta selada",
    description: "Uma carta formal encontrada junto da chave.",
    type: "readable",
    text: "..."
  }
};
```

---

### 5. Sistema de leitura de cartas

Ao clicar em uma carta no inventário:

- abrir uma tela/modal;
- mostrar a imagem do item;
- mostrar o texto legível da carta em fonte do jogo;
- permitir fechar.

Importante:

A imagem da carta pode ter rabiscos ilegíveis, mas o texto real deve aparecer na interface do jogo, não dentro da imagem.

---

## Ordem recomendada de implementação

### Etapa 1 — Preparar projeto

- Criar pasta de assets do bedroom.
- Nomear todos os arquivos de forma consistente.
- Criar arquivo de configuração de cenas/hotspots.
- Carregar background principal.

### Etapa 2 — Implementar navegação básica

- Exibir `bedroom_main`.
- Criar botão/ação de voltar dos zoom-ins.
- Implementar troca simples de cenas.

### Etapa 3 — Implementar hotspots principais

Adicionar hotspots para:

- retrato;
- flor/bordado;
- tapete;
- livro;
- penteadeira/caixa;
- armário.

### Etapa 4 — Implementar coleta da carta da jaqueta

- Abrir armário com carta.
- Clicar na carta.
- Adicionar carta ao inventário.
- Trocar estado do armário para versão sem carta.

### Etapa 5 — Implementar leitura da carta da jaqueta

- Clicar na carta no inventário.
- Exibir texto do enigma.
- Marcar `readJacketNote = true`, se necessário.

### Etapa 6 — Implementar puzzle da caixa

- Abrir caixa fechada.
- Mostrar símbolos clicáveis.
- Registrar sequência de entrada.
- Validar contra `moon → flower → crown → key`.
- Em caso de acerto, trocar para caixa aberta.

### Etapa 7 — Implementar coleta da recompensa

- Na caixa aberta, coletar chave pequena.
- Coletar carta dobrada.
- Adicionar ambos ao inventário.
- Permitir leitura da carta dobrada.

### Etapa 8 — Finalizar primeira entrega

- Criar condição de “fim da primeira entrega”.
- Exemplo:

```js
if (
  gameState.bedroom.jewelryBoxSolved &&
  gameState.bedroom.smallKeyCollected &&
  gameState.bedroom.boxLetterCollected
) {
  showMessage("Você encontrou uma chave e uma nova pista. O segredo continua em outro cômodo...");
}
```

---

## Critérios de conclusão da primeira entrega

A primeira entrega está completa quando o jogador consegue:

- explorar o quarto;
- abrir todos os zoom-ins principais;
- coletar a carta no armário;
- ler o enigma;
- descobrir ou testar a sequência correta;
- abrir a caixa de joias;
- coletar chave e carta da caixa;
- terminar com os itens no inventário.

Não é necessário implementar ainda:

- o próximo cenário;
- o uso real da chave;
- múltiplos finais;
- sistema de save completo;
- animações complexas.

---

## Próximo cenário sugerido depois do bedroom

O próximo cenário recomendado é o **escritório**.

Justificativa:

- A chave pequena combina com gaveta, diário, compartimento secreto ou cofre pequeno.
- O escritório é naturalmente ligado a documentos, segredos e registros.
- A carta da caixa pode apontar para “aquilo que registra seus pecados”, sugerindo um diário ou livro de contas.

Possível próximo puzzle:

**A chave abre uma gaveta ou diário no escritório, revelando uma pista maior sobre a mansão.**

Mas isso deve ficar para depois que o bedroom estiver jogável.

---

## Observações importantes para o Codex

- Priorizar implementação simples e funcional.
- Evitar criar sistemas grandes antes de validar o gameplay básico.
- Usar dados configuráveis para hotspots, itens e cenas.
- Não hardcodar lógica visual diretamente no componente principal, se possível.
- Separar:
  - cenas;
  - assets;
  - estado do jogo;
  - inventário;
  - lógica do puzzle.
- O texto real das cartas deve estar no código/UI, não nas imagens.
- As imagens dos itens devem ser apenas representação visual.

---

## Resumo final

Implementar primeiro o **Master Bedroom** como cenário completo e jogável.

O foco imediato é validar:

- exploração point-and-click;
- zoom-ins;
- coleta de itens;
- leitura de cartas;
- puzzle de sequência;
- mudança de estado do cenário;
- recompensa final.

Depois disso, o projeto terá uma base sólida para expandir para escritório, biblioteca, cozinha e demais cômodos da mansão.

