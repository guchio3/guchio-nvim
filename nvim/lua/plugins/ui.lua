-- UI plugins

return {
  -- カラースキーム: hybrid
  {
    "w0ng/vim-hybrid",
    lazy = false,
    priority = 1000,
  },
  -- ステータスライン
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
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- インデントガイド
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = "VeryLazy",  -- 遅延読み込み
    opts = {
      enabled = false,  -- デフォルトで無効
    },
    config = function(_, opts)
      require("ibl").setup(opts)
      -- トグルコマンドを追加
      vim.api.nvim_create_user_command("IndentGuidesToggle", function()
        require("ibl").setup_buffer(0, { enabled = not require("ibl.config").get_config(0).enabled })
      end, {})
    end,
  },

  -- 括弧の自動補完
  {
    "cohama/lexima.vim",
    event = "InsertEnter",
  },

  -- Git操作
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiffsplit", "Gread", "Gwrite", "Ggrep", "GMove", "GDelete", "GBrowse", "GRemove", "GRename", "Glgrep", "Gedit" },
  },
}
