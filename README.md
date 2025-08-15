# guchio-nvim

Dockerized Neovim development environment with modern configuration (2025).

## Features

- **Neovim** with Lua configuration
- **lazy.nvim** for fast plugin management
- **Native LSP** with mason.nvim for language server management
- **Telescope** for fuzzy finding
- **Treesitter** for better syntax highlighting
- Pre-configured for Python, Go, TypeScript, Rust development
- **uv** for Python package management

## Build

```bash
docker build -t nvim .
```

## Run

```bash
docker run --rm -it -u $(id -u):$(id -g) -e HOME=/root -v $HOME:$HOME --workdir=$(pwd) nvim
```

## Set alias

Add to your shell configuration (`.bashrc`, `.zshrc`, etc.):

```bash
# nvim Docker wrapper function (with file completion)
nvim() {
    docker run --rm -it \
        -u $(id -u):$(id -g) \
        -e HOME=/root \
        -v $HOME:$HOME \
        --workdir=$(pwd) \
        nvim "$@"
}
```

## Key Mappings

### General
- Leader key: `,`

### File Navigation (Telescope)
- `,f` - Find files
- `,g` - Live grep
- `,b` - Buffers
- `,h` - Help tags
- `,r` - Recent files

### LSP
- `K` - Hover documentation
- `<C-]>` - Go to definition
- `<C-[>` - Find references
- `,r` - Rename
- `,a` - Format code
- `[d` - Previous diagnostic
- `]d` - Next diagnostic
- `,d` - Show diagnostic in floating window
- `,o` - Organize imports
- `,l` - List diagnostics
- `,m` - Open Mason UI (package manager)
- `,i` - Show LSP server info

### File Tree
- `<C-n>` - Toggle file tree
- `,n` - Find current file in tree

### Comments
- `gcc` - Toggle comment (normal mode)
- `gc` - Toggle comment (visual mode)

### UI and Themes
- `,t` - Select color theme (interactive menu)
- `,p` - Preview markdown files

Available themes:
- `hybrid` - Classic dark theme (default)
- `tokyonight` - Modern dark theme (night/storm/moon/day variants)
- `catppuccin` - Pastel color theme (mocha/macchiato/frappe/latte variants)
- `gruvbox` - Retro style theme
- `kanagawa` - Japanese-inspired calm theme (wave/dragon/lotus variants)

## Configuration

The configuration is written in Lua and located in:
- `nvim/init.lua` - Main configuration
- `nvim/lua/plugins/` - Plugin configurations

## Updating

To update LSP servers and tools:
```bash
# Inside the container
:Mason
:MasonUpdate
```
