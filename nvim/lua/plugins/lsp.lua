-- LSP and completion plugins

return {
  -- Mason: LSPサーバー管理
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },

  -- Mason-LSPconfig 連携
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = {
      "williamboman/mason.nvim",
    },
    opts = {
      ensure_installed = {
        "lua_ls",        -- Lua
        "ruff",          -- Python linter
        "basedpyright",  -- Python language server
        "gopls",         -- Go
        "ts_ls",         -- TypeScript/JavaScript
        "rust_analyzer", -- Rust
        "dockerls",      -- Docker
        "yamlls",        -- YAML
        "jsonls",        -- JSON
        "bashls",        -- Bash
      },
      automatic_installation = false,  -- Dockerでは事前インストール済み
    },
  },

  -- goto-preview: VS Code風のPeek UI
  {
    "rmagatti/goto-preview",
    config = function()
      require("goto-preview").setup({
        default_mappings = false,
        resizing_mappings = false,
        width = 100,
        height = 18,
        border = "rounded",
        post_open_hook = function(_, win)
          vim.api.nvim_win_set_option(win, "winblend", 3)
        end,
      })
    end,
  },

  -- LSP設定
  {
    "neovim/nvim-lspconfig",
    lazy = false,  -- 遅延ロードを無効にして常にロード
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "rmagatti/goto-preview",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lspconfig = require("lspconfig")
      local ok_mason, mason_lspconfig = pcall(require, "mason-lspconfig")
      local util = require("lspconfig.util")
      
      -- LspInfoコマンドを作成
      vim.api.nvim_create_user_command("LspInfo", function()
        vim.cmd("checkhealth lsp")
      end, { desc = "Show LSP information" })

      -- 診断表示の設定
      vim.diagnostic.config({
        virtual_text = false, -- 仮想テキストは非表示（軽量化）
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "if_many",
        },
      })

      -- VS Code風の診断配色はafter/plugin/diagnostic_highlight.luaで設定

      -- 診断フロート（カーソル位置のみ）
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        callback = function()
          vim.diagnostic.open_float(0, {
            scope = "cursor",  -- カーソル位置のみ
            focus = false,
            border = "rounded",
            source = "if_many",
            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
            severity_sort = true,
          })
        end,
      })

      -- LSPキーマップ
      local on_attach = function(client, bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end
        
        -- basedpyright の診断を完全無効化 + 既存診断をリセット
        if client and client.name == "basedpyright" then
          client.handlers["textDocument/publishDiagnostics"] = function() end
          -- 既に出ている basedpyright の診断を即時リセット
          local ns = vim.lsp.diagnostic and vim.lsp.diagnostic.get_namespace and vim.lsp.diagnostic.get_namespace(client.id)
          if ns then 
            vim.diagnostic.reset(ns, bufnr)
          else
            -- フォールバック: namespace IDで直接リセット
            vim.diagnostic.reset(client.id, bufnr)
          end
        end

        -- グローバルの C-n/C-p を先に削除
        pcall(vim.keymap.del, "n", "<C-n>")
        pcall(vim.keymap.del, "n", "<C-p>")

        map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
        map("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
        map("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
        
        -- 定義/参照: goto-preview 優先（無ければフォールバック）
        map("n", "<C-]>", function()
          local ok, gp = pcall(require, "goto-preview")
          if ok and gp.goto_preview_definition then 
            return gp.goto_preview_definition() 
          end
          return vim.lsp.buf.definition()
        end, "LSP: Peek Definition")
        
        map("n", "gr", function()
          local ok, gp = pcall(require, "goto-preview")
          if ok and gp.goto_preview_references then 
            return gp.goto_preview_references() 
          end
          return vim.lsp.buf.references()
        end, "LSP: Peek References")
        
        -- 診断ジャンプ（API を goto_* に統一）
        local function dnext() vim.diagnostic.goto_next({}) end
        local function dprev() vim.diagnostic.goto_prev({}) end
        map("n", "<C-n>", dnext, "Diagnostics: Next")
        map("n", "<C-p>", dprev, "Diagnostics: Prev")
        map("n", "]d", dnext, "Diagnostics: Next")
        map("n", "[d", dprev, "Diagnostics: Prev")
        
        map("n", ",r", vim.lsp.buf.rename, "LSP: Rename")
        map("n", ",a", vim.lsp.buf.format, "LSP: Format")
        map("v", ",a", vim.lsp.buf.format, "LSP: Format")
        map("n", ",l", "<cmd>Telescope diagnostics<cr>", "Telescope diagnostics")
        map("n", ",d", vim.diagnostic.open_float, "Diagnostic float")
        map("n", ",o", function() vim.lsp.buf.code_action({ context = { only = { "source.organizeImports" } } }) end, "Organize Imports")

        if client.server_capabilities.semanticTokensProvider then
          client.server_capabilities.semanticTokensProvider = nil
        end
      end

      -- ===== LSP servers (setup_handlers は 1 箇所のみ) =====
      local servers = { "lua_ls", "basedpyright", "ruff", "gopls", "ts_ls" }
      
      if ok_mason and type(mason_lspconfig.setup) == "function" then
        mason_lspconfig.setup({ ensure_installed = servers })
        
        if type(mason_lspconfig.setup_handlers) == "function" then
          -- 新しい API（setup_handlers がある場合）
          mason_lspconfig.setup_handlers({
            -- デフォルトハンドラー
            function(server)
              lspconfig[server].setup({ 
                on_attach = on_attach, 
                capabilities = capabilities 
              })
            end,
            
            -- lua_ls
            ["lua_ls"] = function()
              lspconfig.lua_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                  Lua = {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = {
                      library = vim.api.nvim_get_runtime_file("", true),
                      checkThirdParty = false,
                    },
                    telemetry = { enable = false },
                  },
                },
              })
            end,
            
            -- basedpyright（診断は on_attach で止める）
            ["basedpyright"] = function()
              lspconfig.basedpyright.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                root_dir = util.root_pattern("pyproject.toml", "setup.cfg", "requirements.txt", ".git"),
                settings = {
                  python = {
                    analysis = {
                      typeCheckingMode = "basic",
                      autoSearchPaths = true,
                      useLibraryCodeForTypes = true,
                    },
                  },
                  basedpyright = { disableOrganizeImports = true },
                },
              })
            end,
            
            -- ruff（1回だけ attach）
            ["ruff"] = function()
              lspconfig.ruff.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
              })
            end,
            
            -- gopls
            ["gopls"] = function()
              lspconfig.gopls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                  gopls = {
                    analyses = { unusedparams = true },
                    staticcheck = true,
                  },
                },
              })
            end,
            
            -- ts_ls
            ["ts_ls"] = function()
              lspconfig.ts_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            end,
          })
        else
          -- 古い mason-lspconfig（setup_handlers が無い）→ 明示フォールバック
          for _, server in ipairs(servers) do
            if server == "basedpyright" then
              lspconfig.basedpyright.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                root_dir = util.root_pattern("pyproject.toml", "setup.cfg", "requirements.txt", ".git"),
                settings = {
                  python = { 
                    analysis = { 
                      typeCheckingMode = "basic", 
                      autoSearchPaths = true, 
                      useLibraryCodeForTypes = true 
                    } 
                  },
                  basedpyright = { disableOrganizeImports = true },
                },
              })
            elseif server == "ruff" then
              lspconfig.ruff.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
              })
            elseif server == "lua_ls" then
              lspconfig.lua_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                  Lua = {
                    runtime = { version = "LuaJIT" },
                    diagnostics = { globals = { "vim" } },
                    workspace = {
                      library = vim.api.nvim_get_runtime_file("", true),
                      checkThirdParty = false,
                    },
                    telemetry = { enable = false },
                  },
                },
              })
            elseif server == "gopls" then
              lspconfig.gopls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                  gopls = {
                    analyses = { unusedparams = true },
                    staticcheck = true,
                  },
                },
              })
            else
              lspconfig[server].setup({ 
                on_attach = on_attach, 
                capabilities = capabilities 
              })
            end
          end
        end
      else
        -- mason-lspconfig が無い場合の最小セット
        lspconfig.lua_ls.setup({ 
          on_attach = on_attach, 
          capabilities = capabilities 
        })
        lspconfig.basedpyright.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          root_dir = util.root_pattern("pyproject.toml", "setup.cfg", "requirements.txt", ".git"),
          settings = {
            python = { 
              analysis = { 
                typeCheckingMode = "basic", 
                autoSearchPaths = true, 
                useLibraryCodeForTypes = true 
              } 
            },
            basedpyright = { disableOrganizeImports = true },
          },
        })
        lspconfig.ruff.setup({
          on_attach = on_attach,
          capabilities = capabilities,
          root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
        })
      end
    end,
  },

  -- 補完エンジン
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      
      -- friendly-snippetsをロード
      require("luasnip.loaders.from_vscode").lazy_load()

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = false }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
        }, {
          { name = "buffer", keyword_length = 3 },
        }),
        formatting = {
          format = function(entry, vim_item)
            vim_item.menu = ({
              nvim_lsp = "[LSP]",
              luasnip = "[Snippet]",
              buffer = "[Buffer]",
              path = "[Path]",
            })[entry.source.name]
            return vim_item
          end,
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        experimental = {
          ghost_text = false, -- 軽量化のため無効
        },
        performance = {
          debounce = 60,
          throttle = 30,
          fetching_timeout = 200,
        },
      })

      -- コマンドライン補完
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
        }, {
          { name = "cmdline" },
        }),
      })

      -- 検索補完
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },

}