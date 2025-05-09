# Issues-Neovim

Um cliente para gerenciamento de issues do GitHub para linhas de comando e Neovim.

## Funcionalidades

- Interface de terminal (TUI) interativa para visualização e gerenciamento de issues
- Comandos de CLI para gerenciamento rápido de issues
- Integração com Neovim através de plugin Lua
- Detecção automática do repositório atual
- Suporte a busca, criação e comentários em issues

## Estrutura do Código

```
issues-neovim/
├── src/                       # Código fonte principal
│   ├── api/                   # Camada de API
│   │   └── github.js          # Cliente API GitHub com cache
│   ├── cli/                   # Interface de linha de comando
│   │   ├── index.js           # Ponto de entrada da CLI
│   │   ├── commands.js        # Implementação dos comandos
│   │   ├── api.js             # Interface específica da CLI com a API
│   │   └── repo.js            # Detecção de repositório
│   ├── config/                # Configuração compartilhada
│   │   └── index.js           # Gerenciamento de configuração
│   ├── tui/                   # Interface de usuário em terminal
│   │   ├── index.js           # Ponto de entrada da TUI
│   │   ├── actions.js         # Ações da interface
│   │   ├── api.js             # Interface com a API específica da TUI
│   │   ├── events.js          # Manipulação de eventos
│   │   ├── prompts.js         # Prompts interativos
│   │   ├── screen.js          # Inicialização da tela
│   │   ├── state.js           # Gerenciamento de estado
│   │   └── ui.js              # Utilidades de UI
│   ├── utils/                 # Utilidades compartilhadas
│   │   └── format.js          # Formatação de texto
│   └── index.js               # Ponto de entrada principal
├── plugin/                    # Plugin Neovim
│   └── issues-neovim.lua      # Carregador do plugin
├── lua/                       # Módulos Lua para Neovim
│   └── issues-neovim/         # Namespace do plugin
│       ├── init.lua           # Inicialização do plugin
│       └── config.lua         # Configuração do plugin
└── install.sh                 # Script de instalação
```

## Instalação

```bash
# Clone o repositório
git clone https://github.com/issues-vim/issues-vim.git
cd issues-vim

# Instale as dependências
npm install

# Link para uso global (opcional)
npm link

# Para instalar o plugin no Neovim
./install.sh
```

## Uso da CLI

```bash
# Ver todas as issues abertas
issues-neovim list

# Ver issues fechadas
issues-neovim list --closed

# Ver detalhes de uma issue
issues-neovim view 42

# Criar uma nova issue
issues-neovim create

# Adicionar um comentário
issues-neovim comment 42

# Iniciar a interface TUI
issues-neovim tui
```

## Uso no Neovim

```lua
-- Configuração no init.lua
require('issues-neovim').setup({
  default_repository = "owner/repo",
  token = "seu_token_github" -- opcional, pode ser definido como variável de ambiente GITHUB_TOKEN
})

-- Comandos disponíveis no Neovim:
-- :Issues           - Abrir painel de issues
-- :IssueCreate      - Criar uma nova issue
-- :IssueView [num]  - Ver detalhes de uma issue
```

## Requisitos

- Node.js 14+
- Neovim 0.5+ (para o plugin)
- Git (para detecção automática de repositório)

## Desenvolvimento

```bash
# Instalar dependências de desenvolvimento
npm install

# Executar testes
npm test

# Criar um link simbólico para desenvolvimento
npm link
```

## Licença

MIT