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
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      
      -- 共通のon_attach関数
      local on_attach = function(client, bufnr)
        local opts = { noremap = true, silent = true, buffer = bufnr }
        
        vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)  -- <C-[>はESCなので変更
        vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", ",r", vim.lsp.buf.rename, opts)
        vim.keymap.set({ "n", "v" }, ",a", vim.lsp.buf.format, opts)
        
        -- 診断移動はgoto_prev/nextを使用（より安定）
        vim.keymap.set("n", "<C-p>", function() vim.diagnostic.goto_prev({ wrap = false }) end, opts)
        vim.keymap.set("n", "<C-n>", function() vim.diagnostic.goto_next({ wrap = false }) end, opts)
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
      
      -- Mason-LSPconfigのセットアップ（新しいAPI）
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",        -- Lua
          "ruff",          -- Python linter
          "gopls",         -- Go
          "ts_ls",         -- TypeScript/JavaScript
          "rust_analyzer", -- Rust
          "dockerls",      -- Docker
          "yamlls",        -- YAML
          "jsonls",        -- JSON
          "bashls",        -- Bash
        },
        automatic_installation = false,  -- Dockerでは事前インストール済み
        
        -- 新しいAPI: handlersで各LSPサーバーの設定を定義
        handlers = {
          -- デフォルトハンドラー（ほとんどのLSPサーバーに適用）
          function(server_name)
            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
              on_attach = on_attach,
            })
          end,
          
          -- ruff専用の設定
          ["ruff"] = function()
            require("lspconfig").ruff.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              init_options = {
                settings = {
                  format = {
                    args = { "--line-length=120" },
                  },
                },
              },
            })
          end,
          
          -- lua_ls専用の設定
          ["lua_ls"] = function()
            require("lspconfig").lua_ls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
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
          
          -- gopls専用の設定
          ["gopls"] = function()
            require("lspconfig").gopls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                gopls = {
                  analyses = { unusedparams = true },
                  staticcheck = true,
                },
              },
            })
          end,
        }
      })
    end,
  },

  -- LSP設定（診断表示のカスタマイズ）
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      -- LspHealthコマンドを作成（LspInfoは上書きしない）
      vim.api.nvim_create_user_command("LspHealth", function()
        vim.cmd("checkhealth lsp")
      end, { desc = "Show LSP health check" })

      -- 診断表示の設定（サインは完全に無効化）
      vim.diagnostic.config({
        virtual_text = false, -- 仮想テキストは非表示
        signs = false,        -- サインを完全に無効化
        underline = true,     -- 問題のあるコードに下線を引く
        update_in_insert = false,
        severity_sort = true,
        float = {
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
          focusable = false,
          style = "minimal",
          format = function(diagnostic)
            return diagnostic.message
          end,
        },
      })
      
      -- colorschemeが変わっても診断ハイライトを維持
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("MyDiagnosticHL", { clear = true }),
        callback = function()
          vim.api.nvim_set_hl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#ff0000", bg = "#3d0000" })
          vim.api.nvim_set_hl(0, "DiagnosticUnderlineWarn",  { undercurl = true, sp = "#ffaa00", bg = "#3d2800" })
          vim.api.nvim_set_hl(0, "DiagnosticUnderlineInfo",  { undercurl = true, sp = "#00ffff", bg = "#003d3d" })
          vim.api.nvim_set_hl(0, "DiagnosticUnderlineHint",  { undercurl = true, sp = "#00ff00", bg = "#003d00" })
        end,
      })
      -- 起動直後にも適用
      vim.cmd("doautocmd ColorScheme")
      
      -- カーソル位置の診断を自動表示
      vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
          local opts = {
            focusable = false,
            close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
            border = "rounded",
            source = "always",
            prefix = " ",
            scope = "cursor",
          }
          vim.diagnostic.open_float(nil, opts)
        end
      })
      
      -- CursorHoldの待機時間を短くする
      vim.opt.updatetime = 250
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