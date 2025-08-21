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
        vim.keymap.set("n", "<C-]>", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "<C-[>", vim.lsp.buf.references, opts)
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

      -- LSPサーバーの設定
      local lspconfig = require("lspconfig")
      local mason_lspconfig = require("mason-lspconfig")
      
      -- setup_handlers が存在するか確認
      if not mason_lspconfig.setup_handlers then
        -- 古いAPIの場合、手動で設定
        local installed_servers = mason_lspconfig.get_installed_servers()
        for _, server_name in ipairs(installed_servers) do
          if server_name == "lua_ls" then
            lspconfig.lua_ls.setup({
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
          elseif server_name == "pyright" then
            lspconfig.pyright.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                python = {
                  analysis = {
                    autoSearchPaths = true,
                    diagnosticMode = "workspace",
                    useLibraryCodeForTypes = true,
                  },
                },
              },
            })
          elseif server_name == "gopls" then
            lspconfig.gopls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
              settings = {
                gopls = {
                  analyses = { unusedparams = true },
                  staticcheck = true,
                },
              },
            })
          elseif server_name == "ruff" then
            lspconfig.ruff.setup({
              capabilities = capabilities,
              on_attach = on_attach,
            })
          elseif server_name == "ts_ls" then
            lspconfig.ts_ls.setup({
              capabilities = capabilities,
              on_attach = on_attach,
            })
          else
            -- デフォルト設定
            if lspconfig[server_name] then
              lspconfig[server_name].setup({
                capabilities = capabilities,
                on_attach = on_attach,
              })
            end
          end
        end
      else
        -- 新しいAPIを使用
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
        
        ["pyright"] = function()
          lspconfig.pyright.setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = {
              python = {
                analysis = {
                  autoSearchPaths = true,
                  diagnosticMode = "workspace",
                  useLibraryCodeForTypes = true,
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
        
        ["ruff"] = function()
          lspconfig.ruff.setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
        
        ["ts_ls"] = function()
          lspconfig.ts_ls.setup({
            capabilities = capabilities,
            on_attach = on_attach,
          })
        end,
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
