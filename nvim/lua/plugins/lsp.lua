 -- LSP and completion plugins
 -- luacheck: globals vim

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
        "pyright",       -- Python
        "ruff",          -- Python linter
        "gopls",         -- Go
        "ts_ls",         -- TypeScript/JavaScript
        "rust_analyzer", -- Rust
        "dockerls",      -- Docker
        "yamlls",        -- YAML
        "jsonls",        -- JSON
        "bashls",        -- Bash
      },
      -- disable automatic server enabling to avoid duplicate LSP clients
      automatic_enable = false,
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
          source = "always",
          header = "",
          prefix = "",
        },
      })

      -- カーソルホールド時に浮動ウィンドウで診断を表示
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        callback = function()
          vim.diagnostic.open_float(nil, {
            focusable = false,
            close_events = {
              "BufLeave",
              "CursorMoved",
              "InsertEnter",
              "FocusLost",
            },
            border = "rounded",
            source = "always",
            prefix = "",
            scope = "cursor",
          })
        end,
      })

      -- 診断サインをより見やすく
      local signs = { Error = "✗", Warn = "⚠", Hint = "💡", Info = "ℹ" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

      -- LSPキーマップ
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }

        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", ",r", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", ",a", vim.lsp.buf.format, opts)
        vim.keymap.set("v", ",a", vim.lsp.buf.format, opts)
        vim.keymap.set("n", "[d", function()
          vim.diagnostic.jump({ count = -1, float = true })
        end, opts)
        vim.keymap.set("n", "]d", function()
          vim.diagnostic.jump({ count = 1, float = true })
        end, opts)
        vim.keymap.set("n", ",l", "<cmd>Telescope diagnostics<cr>", opts)
        vim.keymap.set("n", ",d", vim.diagnostic.open_float, opts)
        vim.keymap.set("n", ",o", function()
          vim.lsp.buf.code_action({context = {only = {"source.organizeImports"}}})
        end, opts)

        -- セマンティックトークンを無効化（パフォーマンス向上）
        if client.server_capabilities.semanticTokensProvider then
          client.server_capabilities.semanticTokensProvider = nil
        end
      end

      -- LSPサーバーの設定 (vim.lsp.config を使用)
      local lsp = vim.lsp
      local default_config = {
        capabilities = capabilities,
        on_attach = on_attach,
      }

      local servers = {
        lua_ls = {
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
        },
        pyright = {
          -- Disable pyright diagnostics; use ruff for linting instead
          handlers = {
            ["textDocument/publishDiagnostics"] = function() end,
          },
          settings = {
            python = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "workspace",
                useLibraryCodeForTypes = true,
              },
            },
          },
        },
        gopls = {
          settings = {
            gopls = {
              analyses = { unusedparams = true },
              staticcheck = true,
            },
          },
        },
        ruff = {},
        ts_ls = {},
        rust_analyzer = {},
        dockerls = {},
        yamlls = {},
        jsonls = {},
        bashls = {},
      }

      for name, config in pairs(servers) do
        lsp.config(name, vim.tbl_deep_extend("force", default_config, config))
        lsp.enable(name)
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
