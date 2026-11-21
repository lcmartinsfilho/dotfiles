<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

## Obsidian vault

O vault pessoal do Obsidian fica em `$HOME/Obsidian/lcm` (padrão em todas as máquinas; `$HOME/Obsidian/` pode conter outros vaults no futuro).

- Use esse diretório para consultar ou gravar notas pessoais quando o usuário pedir.
- Pode existir busca vetorizada (semântica) sobre o vault, mas ela **pode não estar disponível** nesta máquina ou sessão (índice ausente, serviço parado, ferramenta não instalada). Se não estiver, siga com grep/leitura direta de arquivos, sem tratar como erro e sem tentar instalar ou indexar por conta própria.
- O diretório também pode não existir em algumas máquinas; nesse caso, apenas ignore.

## Dotfiles

Os dotfiles do usuário ficam em `$HOME/dotfiles` (repositório git). Arquivos como `~/.claude/CLAUDE.md` são symlinks para lá, então editar o arquivo global também altera o repositório (fica como mudança não commitada). Scripts opcionais, como `install-vault-search.sh` (busca vetorizada do vault, projeto separado `vault-search` + Ollama), vivem nesse repositório e não rodam automaticamente; nunca os execute sem o usuário pedir.
