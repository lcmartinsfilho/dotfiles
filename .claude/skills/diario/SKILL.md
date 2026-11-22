---
name: diario
description: Diário do Luiz no vault Obsidian. "/diario" abre a sessão (lê as últimas notas publicadas e busca os fios em aberto); "/diario fim" redige o resumo da conversa, deixa o Luiz revisar no chat e só então grava a nota do dia em diario/AAAA/MM/ no vault. Use quando o Luiz pedir /diario, disser que vai começar ou encerrar o diário, ou pedir para salvar/publicar a entrada do dia.
---

# Diário

Vault: `~/Obsidian/lcm`. Notas diárias: `diario/AAAA/MM/AAAA-MM-DD.md`. Frameworks e mecanismos consolidados: `sintese/`.

A busca vem do MCP `vault-search` (`search_notes`, `get_note`, `related_notes`, `reindex`). Se o MCP, o índice ou o Ollama não responderem, caia para `grep` e leitura direta sem tratar isso como erro.

Modo escolhido pelo argumento: sem argumento = **abrir**; `fim` = **fim**. Qualquer outro argumento: perguntar qual dos dois.

## Regras que valem sempre

1. **Nada é gravado no vault sem aprovação explícita** (ver "Fim", passo 4). Antes disso o resumo existe só no chat.
2. **Nota já publicada nunca é reescrita pelo Claude.** Só se acrescentam novas seções `## Sessão N`. Correções em notas publicadas são do Luiz.
3. **Sem horários escritos pelo Claude**, nem em respostas nem nas notas. A data vem do nome do arquivo.
4. **Não sugerir que o Luiz vá dormir** por causa do horário.
5. Papel durante a conversa: o Luiz gera as hipóteses; o Claude refina, complica, nomeia mecanismos e faz perguntas socráticas, sem conduzir. Tabelas e mapas em vez de listas sequenciais quando houver estrutura.
6. "manualista" e "resíduo manualista" nunca são anglicizados. Idioma: português do Brasil.
7. O que é lido como contexto são só **notas publicadas**. Nunca tratar rascunho, ou algo que o Claude disse numa sessão anterior, como fato sobre o Luiz.

## Abrir (`/diario`)

1. Obter a data de hoje com `date +%F`.
2. Listar `diario/` e ler, direto do arquivo, as últimas 5 notas por nome. Se a nota de hoje já existir, ler também.
3. Extrair os fios em aberto, principalmente das seções "Pendências / em aberto" dessas notas.
4. Para cada fio relevante, `search_notes` (use `--path diario` para o histórico e `--path sintese` para mecanismos já nomeados). Abrir os melhores resultados com `get_note` e citar o caminho de cada nota usada.
5. Responder com um panorama curto (3 a 6 linhas): fios em aberto e o que mudou desde a última nota. Não despejar o histórico. Perguntar por onde o Luiz quer começar.
6. Se não houver nenhuma nota publicada ainda, dizer isso e começar do zero.

## Fim (`/diario fim`)

1. Rever a conversa da sessão inteira.
2. Redigir o resumo **no chat**, no formato abaixo, seguindo as regras de redação.
3. **Revisão:** o Luiz pede ajustes em linguagem natural ("isso foi hipótese", "use o meu termo"). Aplicar e reexibir a seção alterada. Reexibir o resumo completo só se mudou muito ou se ele pedir.
4. **Aprovação:** depois da última versão mostrada, pedir uma confirmação específica ("responda *publicar* para gravar"). Só gravar com "publicar" ou equivalente inequívoco dado *depois* dessa versão. Um "ok" no meio da revisão não vale.
5. **Gravação:**
   - `mkdir -p diario/AAAA/MM`.
   - Se o arquivo do dia não existe, criar com o frontmatter abaixo.
   - Se existe, **acrescentar** `## Sessão N` (N = próxima) ao final, sem tocar no conteúdo anterior.
   - Se conseguir identificar o id da sessão (arquivo `.jsonl` mais recente em `~/.claude/projects/<diretório-atual-codificado>/`), registrá-lo na linha logo abaixo do título da seção; senão, omitir.
6. Chamar `reindex` e informar o resumo retornado. Se falhar, avisar que o timer indexa em até 15 min.
7. Informar o caminho gravado.

### Formato da nota

```markdown
---
data: AAAA-MM-DD
tags: [diario]
autor: claude-resumo
revisado: true
---

# AAAA-MM-DD

## Sessão 1
_sessão do Claude Code: <id>_

### <Assunto>
...

### Pendências / em aberto
- ...
```

- Cabeçalhos por assunto (`### Trabalho`, `### Leituras`...), cada seção com mais de 200 caracteres: o indexador faz chunks por cabeçalho e funde seções menores.
- `### Pendências / em aberto` fecha toda sessão; é daqui que a próxima abertura tira os fios.
- Mais curto que a conversa, sem enchimento.

### Regras de redação

| Registrar | Não registrar como fato |
|---|---|
| O que o Luiz afirmou, concluiu ou decidiu | Sugestões do Claude que ele não adotou |
| Hipóteses dele, marcadas como "hipótese:" | Hipóteses ou brainstorm promovidos a conclusão |
| Mecanismos que ele nomeou, com as palavras dele | Reformulações do Claude no lugar do termo dele |
| Compromissos e pendências | Cenários hipotéticos |
| Fatos que ele relatou, no nível em que relatou | Inferências sobre saúde, personalidade ou motivações que ele não afirmou |

- Contribuição do Claude só entra se o Luiz a adotou, e com atribuição explícita: "(sugestão do Claude, adotada)". Sugestão não adotada que seja relevante para o fio: uma linha, "Claude sugeriu X; sem decisão".
- `[[wikilinks]]` só para notas que existem (conferir antes). Reaproveitar tags já usadas no vault, sem inventar tags novas.
- Mecanismos que apareçam em várias entradas podem ser **propostos** para `sintese/` ao fim da revisão; nunca gravar em `sintese/` sem aprovação, e nunca dentro da nota diária.

## Falhas

- Vault inacessível: dizer, e não gravar em outro lugar.
- Sessão encerrada antes da aprovação: o resumo se perde, mas a sessão pode ser retomada (`claude --resume`) e `/diario fim` rodado de novo. Resumir ao fim de cada bloco de conversa, não só no fim do dia.
