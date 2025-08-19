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

  -- LSP設定
  {
    "neovim/nvim-lspconfig",
    lazy = false,  -- 遅延ロードを無効にして常にロード
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lspconfig = require("lspconfig")
      local ok_mason, mason_lsp = pcall(require, "mason-lspconfig")
      local util = require("lspconfig.util")
      
      -- LspInfoコマンドを作成
      vim.api.nvim_create_user_command("LspInfo", function()
        vim.cmd("checkhealth lsp")
      end, { desc = "Show LSP information" })

      -- 診断表示の設定
      vim.diagnostic.config({
        virtual_text = false, -- 仮想テキストは非表示（軽量化）
        signs = false,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- エラーと警告を下線と淡い背景色で表示
      local function set_diagnostic_hl()
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { underline = true, bg = "#553333", blend = 50 })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { underline = true, bg = "#333355", blend = 50 })
        vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { underline = true, bg = "#333355", blend = 50 })
      end
      set_diagnostic_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_diagnostic_hl })

      vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          vim.diagnostic.open_float(nil, { focus = false })
        end,
      })

      -- LSPキーマップ
      local on_attach = function(client, bufnr)
        local function map(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        if client and client.name == "basedpyright" then
          client.handlers["textDocument/publishDiagnostics"] = function() end
        end

        pcall(vim.keymap.del, "n", "<C-n>", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<C-p>", { buffer = bufnr })

        map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
        map("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
        map("n", "gr", vim.lsp.buf.references, "LSP: References")
        map("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
        map("n", "<C-]>", vim.lsp.buf.definition, "LSP: Go to Definition (Ctrl-])")
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

      -- LSPサーバーの設定
      local servers = {
        "lua_ls",
        "basedpyright",
        "ruff",
        "gopls",
        "ts_ls",
        "rust_analyzer",
        "dockerls",
        "yamlls",
        "jsonls",
        "bashls",
      }

      if ok_mason and type(mason_lsp.setup) == "function" then
        mason_lsp.setup({ ensure_installed = servers })
        if type(mason_lsp.setup_handlers) == "function" then
          mason_lsp.setup_handlers({
            function(server)
              lspconfig[server].setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            end,
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
            ["ruff"] = function()
              lspconfig.ruff.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
              })
            end,
            ["gopls"] = function()
              lspconfig.gopls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                  gopls = { analyses = { unusedparams = true }, staticcheck = true },
                },
              })
            end,
            ["ts_ls"] = function()
              lspconfig.ts_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            end,
          })
        else
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
                      useLibraryCodeForTypes = true,
                    },
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
            elseif server == "gopls" then
              lspconfig.gopls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
                settings = {
                  gopls = { analyses = { unusedparams = true }, staticcheck = true },
                },
              })
            elseif server == "ts_ls" then
              lspconfig.ts_ls.setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            else
              lspconfig[server].setup({
                on_attach = on_attach,
                capabilities = capabilities,
              })
            end
          end
        end
      else
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
                    useLibraryCodeForTypes = true,
                  },
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
          elseif server == "gopls" then
            lspconfig.gopls.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              settings = {
                gopls = { analyses = { unusedparams = true }, staticcheck = true },
              },
            })
          elseif server == "ts_ls" then
            lspconfig.ts_ls.setup({
              on_attach = on_attach,
              capabilities = capabilities,
            })
          else
            lspconfig[server].setup({
              on_attach = on_attach,
              capabilities = capabilities,
            })
          end
        end
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
