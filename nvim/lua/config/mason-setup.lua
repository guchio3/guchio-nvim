-- Mason setup for Docker build
-- このファイルはDockerビルド時にツールをインストールするために使用

local function install_all_tools()
  local registry = require("mason-registry")
  
  -- 必要なツールのリスト
  local tools = {
    -- LSP servers
    "lua-language-server",
    "pyright",
    "ruff-lsp",
    "gopls",
    "typescript-language-server",
    "rust-analyzer",
    "dockerfile-language-server",
    "yaml-language-server",
    "json-lsp",
    "bash-language-server",
    
    -- Formatters/Linters
    "black",
    "isort",
    "ruff",
    "mypy",
    "gofumpt",
    "golangci-lint",
    "prettier",
    "stylua",
    "shellcheck",
    "shfmt",
  }
  
  registry.refresh(function()
    for _, tool_name in ipairs(tools) do
      local ok, pkg = pcall(registry.get_package, tool_name)
      if ok then
        if not pkg:is_installed() then
          pkg:install()
        end
      else
        vim.notify("Failed to find package: " .. tool_name, vim.log.levels.WARN)
      end
    end
  end)
end

-- Dockerビルド時のみ実行
if vim.env.DOCKER_BUILD == "1" then
  vim.defer_fn(function()
    install_all_tools()
    -- インストール完了を待つ
    vim.defer_fn(function()
      vim.cmd("quitall")
    end, 30000) -- 30秒待つ
  end, 1000)
end