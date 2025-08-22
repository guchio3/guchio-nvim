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
docker run --rm -it --detach-keys=ctrl-q,ctrl-q \
  -u $(id -u):$(id -g) -e HOME=/root \
  -v "$HOME:$HOME" --workdir="$(pwd)" nvim
```

## Set alias

Add to your shell configuration (`.bashrc`, `.zshrc`, etc.):

```bash
nvim() {
  docker run --rm -it \
    --detach-keys=ctrl-q,ctrl-q \
    -u $(id -u):$(id -g) \
    -e HOME=/root \
    -v "$HOME:$HOME" \
    --workdir="$(pwd)" \
    nvim "$@"
}
```

## Troubleshooting

### `Ctrl-p` doesn’t work (Docker detach keys)

Docker’s default detach key sequence is `ctrl-p,ctrl-q`. Pressing only `Ctrl-p`
makes Docker wait for the next key, so Neovim sees nothing until the next
keypress. This can look like “first press ignored, second press jumps twice”.

Two solutions:

1. Pass `--detach-keys=ctrl-q,ctrl-q` in `docker run` (shown in the alias).
2. Set `~/.docker/config.json` with:

   ```json
   { "detachKeys": "ctrl-q,ctrl-q" }
   ```

See: docker container attach reference, docker config.json man page.

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
- `<C-p>` - Previous error or warning
- `<C-n>` - Next error or warning
- `,d` - Show diagnostic in floating window
- `,o` - Organize imports
- `,l` - List diagnostics
- `,m` - Open Mason UI (package manager)
- `,i` - Show LSP server info

### File Tree

- `<C-e>` - Toggle file tree
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
