-- UI plugins

return {
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
