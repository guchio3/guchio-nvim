#!/bin/bash
# Dockerビルド時にMasonツールをインストールするスクリプト

set -e

echo "Installing Mason tools..."

# Neovimを起動してツールをインストール
nvim --headless -c "
lua << EOF
  -- Masonのセットアップを待つ
  vim.defer_fn(function()
    local registry = require('mason-registry')
    
    -- ツールリスト（mason-lspconfig.nvimの設定と一致させる）
    local tools = {
      'lua-language-server',  -- lua_ls
      'pyright',
      'ruff-lsp',
      'gopls',
      'typescript-language-server',  -- tsserver
      'rust-analyzer',
      'dockerfile-language-server',  -- dockerls
      'yaml-language-server',  -- yamlls
      'json-lsp',  -- jsonls
      'bash-language-server',  -- bashls
      'black',
      'isort',
      'ruff',
      'mypy',
      'gofumpt',
      'golangci-lint',
      'prettier',
      'stylua',
      'shellcheck',
      'shfmt',
    }
    
    -- レジストリを更新
    registry.refresh(function()
      local count = 0
      local total = #tools
      
      for _, tool in ipairs(tools) do
        local ok, pkg = pcall(registry.get_package, tool)
        if ok and not pkg:is_installed() then
          pkg:install()
          count = count + 1
        end
      end
      
      -- インストール完了を待つ
      vim.defer_fn(function()
        print('Tools installation completed')
        vim.cmd('quitall')
      end, 20000)
    end)
  end, 2000)
EOF
" +qa

echo "Mason tools installation completed"