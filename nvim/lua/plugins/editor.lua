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
      { "<C-e>", "<cmd>NvimTreeToggle<cr>", desc = "Toggle file tree" },
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
            folder = false,  -- フォルダアイコンも非表示
            folder_arrow = true,  -- 矢印だけ表示
            git = false,  -- Gitアイコンを非表示
          },
          glyphs = {
            default = "",
            symlink = "@",
            folder = {
              arrow_closed = "▸",
              arrow_open = "▾",
              default = "",  -- フォルダ自体のアイコンは空
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
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
      on_attach = function(bufnr)
        local api = require("nvim-tree.api")
        api.config.mappings.default_on_attach(bufnr)
        vim.keymap.set("n", "<C-e>", api.tree.toggle, { buffer = bufnr })
      end,
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

  -- Git差分表示
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add          = { text = '+' },
        change       = { text = '~' },
        delete       = { text = '_' },
        topdelete    = { text = '‾' },
        changedelete = { text = '~' },
        untracked    = { text = '' },
      },
      signcolumn = true,  -- Sign columnにgit差分を表示
      numhl      = false, -- 行番号のハイライト
      linehl     = false, -- 行全体のハイライト
      word_diff  = false, -- 単語単位の差分
      watch_gitdir = {
        interval = 1000,
        follow_files = true
      },
      attach_to_untracked = true,
      current_line_blame = false, -- 現在行のblame情報表示
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = 'eol', -- 'eol' | 'overlay' | 'right_align'
        delay = 1000,
        ignore_whitespace = false,
      },
      current_line_blame_formatter = '<author>, <author_time:%Y-%m-%d> - <summary>',
      sign_priority = 6,
      update_debounce = 100,
      status_formatter = nil,
      max_file_length = 40000,
      preview_config = {
        -- プレビューウィンドウの設定
        border = 'single',
        style = 'minimal',
        relative = 'cursor',
        row = 0,
        col = 1
      },
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- ナビゲーション
        map('n', ']c', function()
          if vim.wo.diff then
            vim.cmd.normal({']c', bang = true})
          else
            gitsigns.nav_hunk('next')
          end
        end, {desc = 'Next hunk'})

        map('n', '[c', function()
          if vim.wo.diff then
            vim.cmd.normal({'[c', bang = true})
          else
            gitsigns.nav_hunk('prev')
          end
        end, {desc = 'Previous hunk'})

        -- アクション
        map('n', '<leader>hs', gitsigns.stage_hunk, {desc = 'Stage hunk'})
        map('n', '<leader>hr', gitsigns.reset_hunk, {desc = 'Reset hunk'})
        map('v', '<leader>hs', function() gitsigns.stage_hunk {vim.fn.line('.'), vim.fn.line('v')} end, {desc = 'Stage hunk'})
        map('v', '<leader>hr', function() gitsigns.reset_hunk {vim.fn.line('.'), vim.fn.line('v')} end, {desc = 'Reset hunk'})
        map('n', '<leader>hS', gitsigns.stage_buffer, {desc = 'Stage buffer'})
        map('n', '<leader>hu', gitsigns.undo_stage_hunk, {desc = 'Undo stage hunk'})
        map('n', '<leader>hR', gitsigns.reset_buffer, {desc = 'Reset buffer'})
        map('n', '<leader>hp', gitsigns.preview_hunk, {desc = 'Preview hunk'})
        map('n', '<leader>hb', function() gitsigns.blame_line{full=true} end, {desc = 'Blame line'})
        map('n', '<leader>tb', gitsigns.toggle_current_line_blame, {desc = 'Toggle blame'})
        map('n', '<leader>hd', gitsigns.diffthis, {desc = 'Diff this'})
        map('n', '<leader>hD', function() gitsigns.diffthis('~') end, {desc = 'Diff this ~'})
        map('n', '<leader>td', gitsigns.toggle_deleted, {desc = 'Toggle deleted'})

        -- Text object
        map({'o', 'x'}, 'ih', ':<C-U>Gitsigns select_hunk<CR>', {desc = 'Select hunk'})
      end
    },
  },
}
