-- Language specific plugins

return {
  -- Markdown
  {
    "plasticboy/vim-markdown",
    ft = { "markdown" },
    config = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.opt.foldenable = false
    end,
  },

  -- Markdown Preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      vim.fn["mkdp#util#install"]()
    end,
    keys = {
      { ",p", "<cmd>MarkdownPreviewToggle<cr>", ft = "markdown", desc = "Markdown Preview" },
    },
  },

  -- TOML
  {
    "cespare/vim-toml",
    ft = { "toml" },
  },

  -- Rust
  {
    "rust-lang/rust.vim",
    ft = { "rust" },
  },

  -- Go
  {
    "fatih/vim-go",
    ft = { "go" },
    build = ":GoUpdateBinaries",
    config = function()
      -- vim-goの設定（LSPと重複しないように最小限）
      vim.g.go_fmt_command = "goimports"
      vim.g.go_def_mapping_enabled = 0  -- LSPを使うので無効化
      vim.g.go_doc_keywordprg_enabled = 0  -- LSPを使うので無効化
      vim.g.go_gopls_enabled = 0  -- nvim-lspconfigを使うので無効化
    end,
  },
}
