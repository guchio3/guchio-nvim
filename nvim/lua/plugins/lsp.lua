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

      -- VS Code風の診断配色
      local function set_diagnostic_hl()
        -- エラー（赤）
        vim.api.nvim_set_hl(0, "DiagnosticError", { fg = "#F14C4C" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#F14C4C" })
        
        -- 警告（黄色）
        vim.api.nvim_set_hl(0, "DiagnosticWarn", { fg = "#CCA700" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn", { undercurl = true, sp = "#CCA700" })
        
        -- 情報（青）
        vim.api.nvim_set_hl(0, "DiagnosticInfo", { fg = "#3794FF" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo", { undercurl = true, sp = "#3794FF" })
        
        -- ヒント（緑）
        vim.api.nvim_set_hl(0, "DiagnosticHint", { fg = "#10B981" })
        vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint", { undercurl = true, sp = "#10B981" })
        
        -- 不要なコード（薄い表示）
        vim.api.nvim_set_hl(0, "DiagnosticUnnecessary", { fg = "#808080", italic = true })
      end
      set_diagnostic_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_diagnostic_hl })
      
      -- VS Code風のサインアイコン
      vim.fn.sign_define("DiagnosticSignError", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DiagnosticSignWarn", { text = "●", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DiagnosticSignInfo", { text = "●", texthl = "DiagnosticInfo" })
      vim.fn.sign_define("DiagnosticSignHint", { text = "●", texthl = "DiagnosticHint" })

      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        callback = function()
          vim.diagnostic.open_float(0, {
            scope = "cursor",
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

        -- 既存のC-n/C-pマッピングをクリア
        pcall(vim.keymap.del, "n", "<C-n>", { buffer = bufnr })
        pcall(vim.keymap.del, "n", "<C-p>", { buffer = bufnr })

        map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
        map("n", "gd", vim.lsp.buf.definition, "LSP: Go to Definition")
        map("n", "gD", vim.lsp.buf.declaration, "LSP: Go to Declaration")
        map("n", "gr", vim.lsp.buf.references, "LSP: References")
        map("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
        
        -- VS Code風のPeek（goto-previewを利用）
        local ok, goto_preview = pcall(require, "goto-preview")
        if ok then
          map("n", "<C-]>", goto_preview.goto_preview_definition, "Peek Definition")
          map("n", "gR", goto_preview.goto_preview_references, "Peek References")
          map("n", "gI", goto_preview.goto_preview_implementation, "Peek Implementation")
          map("n", "<Esc>", goto_preview.close_all_win, "Close Peek windows")
        else
          map("n", "<C-]>", vim.lsp.buf.definition, "LSP: Go to Definition (Ctrl-])")
        end
        -- 診断ジャンプ（安定化のためnowaitを使わない）
        local function diag_next() vim.diagnostic.jump({ count = 1 }) end
        local function diag_prev() vim.diagnostic.jump({ count = -1 }) end
        map("n", "<C-n>", diag_next, "Diagnostics: Next")
        map("n", "<C-p>", diag_prev, "Diagnostics: Prev")
        map("n", "]d", function() vim.diagnostic.jump({ count = 1 }) end, "Diagnostics: Next")
        map("n", "[d", function() vim.diagnostic.jump({ count = -1 }) end, "Diagnostics: Prev")
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
      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")
      local util = require("lspconfig.util")
      
      -- setup_handlersで一元管理（重複を防ぐ）
      mason_lspconfig.setup_handlers({
        -- デフォルトハンドラー
        function(server_name)
          lspconfig[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
        
        -- 特定のサーバー用カスタム設定
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              Lua = {
                runtime = {
                  version = "LuaJIT",
                },
                diagnostics = {
                  globals = { "vim" },
                },
                workspace = {
                  library = vim.api.nvim_get_runtime_file("", true),
                  checkThirdParty = false,
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          })
        end,
        
        ["gopls"] = function()
          lspconfig.gopls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              gopls = {
                analyses = {
                  unusedparams = true,
                },
                staticcheck = true,
              },
            },
          })
        end,

        ["basedpyright"] = function()
          lspconfig.basedpyright.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            root_dir = util.root_pattern("pyproject.toml", "setup.cfg", "requirements.txt", ".git"),
            settings = {
              basedpyright = { disableOrganizeImports = true },
              python = {
                analysis = {
                  typeCheckingMode = "basic",
                  diagnosticSeverityOverrides = {
                    reportMissingImports = "none",
                    reportDeprecated = "none",
                  },
                  autoSearchPaths = true,
                  useLibraryCodeForTypes = true,
                },
              },
            },
          })
        end,

        ["ruff"] = function()
          lspconfig.ruff.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
          })
        end,

        ["ts_ls"] = function()
          lspconfig.ts_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
      })
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
