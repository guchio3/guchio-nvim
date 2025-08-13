-- UI and colorscheme plugins

return {
  -- カラースキーム（複数の人気テーマを追加）
  {
    "rafi/awesome-vim-colorschemes",
    priority = 1000,
    config = function()
      vim.opt.background = "dark"
    end,
  },
  
  -- Tokyo Night (人気のモダンテーマ)
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night", -- night, storm, day, moon
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = true },
        keywords = { italic = true },
        functions = {},
        variables = {},
      },
    },
  },
  
  -- Catppuccin (パステルカラーのテーマ)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = {
        light = "latte",
        dark = "mocha",
      },
    },
  },
  
  -- Gruvbox (レトロな雰囲気の人気テーマ)
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      contrast = "hard", -- hard, medium, soft
      transparent_mode = false,
    },
  },
  
  -- Kanagawa (日本風の落ち着いたテーマ)
  {
    "rebelot/kanagawa.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      compile = false,
      undercurl = true,
      commentStyle = { italic = true },
      functionStyle = {},
      keywordStyle = { italic = true },
      statementStyle = { bold = true },
      typeStyle = {},
      transparent = false,
      dimInactive = false,
      terminalColors = true,
      colors = {
        palette = {},
        theme = { wave = {}, lotus = {}, dragon = {}, all = {} },
      },
      overrides = function(colors)
        return {}
      end,
      theme = "wave", -- wave, dragon, lotus
      background = {
        dark = "wave",
        light = "lotus",
      },
    },
  },

  -- ステータスライン（lightlineの代わりにlualineを使用）
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "auto",
        component_separators = "|",
        section_separators = "",
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { "filename" },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- インデントガイド（元の設定と同様、デフォルトで無効）
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",  -- 遅延読み込み
    opts = {
      enabled = false,  -- デフォルトで無効（元の設定と同じ）
    },
    config = function(_, opts)
      require("ibl").setup(opts)
      -- トグルコマンドを追加
      vim.api.nvim_create_user_command("IndentGuidesToggle", function()
        require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
      end, {})
    end,
  },

  -- Git signs（元の設定にはなかったので、控えめに設定）
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
        untracked = { text = "" },  -- 未追跡ファイルは表示しない
      },
      signcolumn = true,  -- signcolumn を有効化（Git変更を表示）
      numhl = false,      -- 行番号には色を付けない
      linehl = false,     -- 行全体には背景色を付けない
      word_diff = false,
      watch_gitdir = {
        interval = 1000,
        follow_files = true,
      },
      attach_to_untracked = true,
      current_line_blame = false,
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol",
        delay = 1000,
        ignore_whitespace = false,
      },
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        border = "single",
        style = "minimal",
        relative = "cursor",
        row = 0,
        col = 1,
      },
    },
  },

  -- ウィンドウリサイズ（既存から引き継ぎ）
  {
    "simeji/winresizer",
    keys = {
      { "<C-e>", "<cmd>WinResizerStartResize<cr>", desc = "Window Resizer" },
    },
  },

  -- 括弧の自動補完（既存から引き継ぎ）
  {
    "cohama/lexima.vim",
    event = "InsertEnter",
  },

  -- Git操作（既存から引き継ぎ）
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse", "GRemove", "GRename", "Glgrep", "Gedit" },
  },
}