-- Editor enhancement plugins

return {
  -- Telescope (deniteの代わり)
  {
    "nvim-telescope/telescope.nvim",
    branch = "0.1.x",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function()
          return vim.fn.executable("make") == 1
        end,
      },
    },
    keys = {
      { ",f", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { ",g", "<cmd>Telescope live_grep<cr>", desc = "Grep Files" },
      { ",b", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { ",h", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { ",r", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      
      telescope.setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "truncate" },
          mappings = {
            i = {
              ["<C-n>"] = actions.cycle_history_next,
              ["<C-p>"] = actions.cycle_history_prev,
              ["<C-j>"] = actions.move_selection_next,
              ["<C-k>"] = actions.move_selection_previous,
              ["<C-c>"] = actions.close,
              -- Escはデフォルトのまま（Normal modeへ移行）
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
            },
            n = {
              ["<Esc>"] = actions.close,
              ["<C-c>"] = actions.close,
              ["<CR>"] = actions.select_default,
              ["<C-x>"] = actions.select_horizontal,
              ["<C-v>"] = actions.select_vertical,
              ["<C-t>"] = actions.select_tab,
              ["q"] = actions.close,
            },
          },
        },
        pickers = {
          find_files = {
            find_command = { "rg", "--files", "--hidden", "--glob", "!.git/*" },
          },
        },
        extensions = {
          fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
          },
        },
      })
      
      -- fzf拡張をロード
      pcall(telescope.load_extension, "fzf")
    end,
  },

  -- Treesitter（シンタックスハイライト）
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = {
      "nvim-treesitter/nvim-treesitter-textobjects",
    },
    config = function()
      require("nvim-treesitter.configs").setup({
        -- Dockerビルド時にインストールするパーサーのリスト
        ensure_installed = vim.env.DOCKER_BUILD == "1" and {
          "lua", "vim", "vimdoc", "query",
          "markdown", "markdown_inline",
          "python", "go",
          "javascript", "typescript", "tsx",
          "rust",
          "json", "yaml", "toml",
          "dockerfile",
          "bash",
          "html", "css"
        } or {},
        auto_install = false,  -- 自動インストールを無効化
        sync_install = vim.env.DOCKER_BUILD == "1",  -- Dockerビルド時は同期インストール
        highlight = {
          enable = true,
          -- 大きいファイルでは無効化
          disable = function(lang, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
        },
        indent = {
          enable = true,
        },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            scope_incremental = false,
            node_decremental = "<bs>",
          },
        },
      })
    end,
  },

  -- ファイルツリー（NERDTreeの代わり）
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<C-n>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
      { ",n", "<cmd>NvimTreeFindFile<cr>", desc = "Find current file in tree" },
    },
    opts = {
      sort_by = "case_sensitive",
      view = {
        width = 30,
      },
      renderer = {
        group_empty = true,
        icons = {
          show = {
            file = false,
            folder = true,
            folder_arrow = true,
            git = true,
          },
          glyphs = {
            default = "",
            symlink = "@",
            folder = {
              arrow_closed = ">",
              arrow_open = "v",
              default = "[D]",
              open = "[D]",
              empty = "[D]",
              empty_open = "[D]",
              symlink = "[D@]",
              symlink_open = "[D@]",
            },
            git = {
              unstaged = "M",
              staged = "S",
              unmerged = "U",
              renamed = "R",
              untracked = "?",
              deleted = "D",
              ignored = "I",
            },
          },
        },
      },
      filters = {
        dotfiles = false,
      },
      git = {
        enable = true,
        ignore = false,
      },
    },
  },

  -- コメントアウト
  {
    "numToStr/Comment.nvim",
    keys = {
      { "gcc", mode = "n", desc = "Comment toggle current line" },
      { "gc", mode = { "n", "o" }, desc = "Comment toggle linewise" },
      { "gc", mode = "x", desc = "Comment toggle linewise (visual)" },
      { "gbc", mode = "n", desc = "Comment toggle current block" },
      { "gb", mode = { "n", "o" }, desc = "Comment toggle blockwise" },
      { "gb", mode = "x", desc = "Comment toggle blockwise (visual)" },
    },
    opts = {},
  },

  -- Surround
  {
    "kylechui/nvim-surround",
    version = "*",
    event = "VeryLazy",
    opts = {},
  },
}