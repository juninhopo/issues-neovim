# LazyVim Issues CLI

Um CLI simples para gerenciar issues do GitHub do projeto [LazyVim](https://github.com/LazyVim/LazyVim).

## Instalação

Clone este repositório:

```bash
git clone https://github.com/juninhopo/issues-cli.git
cd issues-cli
```

Instale as dependências:

```bash
npm install
```

Instale o CLI globalmente:

```bash
npm link
```

## Uso

### Interface TUI (Terminal User Interface)

Para iniciar a interface TUI similar ao Lazygit, você pode executar:

```bash
lazyvim-issues
```

ou

```bash
lazyvim-issues tui
```

A interface TUI permite:
- Navegar pelas issues abertas e fechadas
- Ver detalhes completos das issues
- Criar novas issues
- Adicionar comentários às issues
- Buscar issues por termo

#### Atalhos de teclado na TUI
- `↑/↓`: Navegar pela lista de issues
- `Enter`: Ver detalhes da issue selecionada
- `Tab`: Alternar entre a lista de issues e os detalhes
- `c`: Comentar na issue selecionada
- `r`: Recarregar a lista de issues
- `q`: Sair da aplicação
- `1`: Ver issues abertas
- `2`: Ver issues fechadas
- `3`: Buscar issues
- `4`: Criar uma nova issue

### Modo de linha de comando

### Autenticação

Para operações somente de leitura (listar issues, ver detalhes, buscar) em repositórios públicos como o LazyVim, **não é necessário** um token de acesso do GitHub.

Para operações de escrita (criar issues, comentar), você precisará de um token de acesso pessoal do GitHub com permissões para issues. Você pode configurar o token como uma variável de ambiente:

```bash
export GITHUB_TOKEN=seu_token_aqui
```

Se você não configurar o token e tentar realizar uma operação que o exija, o CLI irá solicitar o token quando necessário.

### Comandos disponíveis

#### Listar issues

```bash
lazyvim-issues listar
```

Opções:
- `-a, --abertas`: Listar apenas issues abertas (padrão)
- `-f, --fechadas`: Listar apenas issues fechadas
- `-l, --limite <número>`: Número máximo de issues a serem exibidas (padrão: 10)

#### Ver detalhes de uma issue

```bash
lazyvim-issues ver <número>
```

#### Criar uma nova issue

```bash
lazyvim-issues criar
```

#### Adicionar um comentário a uma issue

```bash
lazyvim-issues comentar <número>
```

#### Buscar issues por termo

```bash
lazyvim-issues buscar <termo>
```

## Integração com LazyVim

Existem duas maneiras de integrar este CLI com o LazyVim:

### 1. Integração com terminal flutuante (recomendado)

Copie o arquivo de integração fornecido para o seu diretório de configuração do LazyVim:

```bash
cp integrations/lazyvim-issues.lua ~/.config/nvim/lua/plugins/
```

Isso adicionará:
- Um atalho `<leader>Li` para abrir o LazyVim Issues em um terminal flutuante
- Dependência do plugin `vim-floaterm` para criar um terminal flutuante

### 2. Integração com terminal integrado

Alternativamente, você pode adicionar o seguinte ao seu arquivo de configuração:

```lua
-- ~/.config/nvim/lua/plugins/lazyvim-issues.lua
return {
  {
    "folke/which-key.nvim",
    optional = true,
    opts = {
      defaults = {
        ["<leader>L"] = { name = "+LazyVim" },
      },
    },
  },
  {
    "folke/which-key.nvim",
    optional = true,
    event = "VeryLazy",
    config = function()
      local wk = require("which-key")
      wk.register({
        ["<leader>Li"] = { "<cmd>terminal lazyvim-issues<cr>", "LazyVim Issues" },
      })
    end,
  },
}
```

Isso adicionará um atalho `<leader>Li` para abrir o CLI de issues no terminal integrado do Neovim.

## Desenvolvimento

### Requisitos

- Node.js (versão 14 ou superior)
- npm (versão 6 ou superior)

### Scripts disponíveis

- `npm start`: Inicia a interface TUI (padrão)
- `npm run tui`: Inicia explicitamente a interface TUI

## Licença

ISC