-- /root/.config/nvim/init.lua 〔完全置換〕
-- ========== 基本オプション ==========
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = { "ucs-bom", "utf-8", "cp932", "latin1" } -- Docker 内の日本語も考慮
vim.opt.number = true
vim.opt.relativenumber = false
vim.opt.signcolumn = "auto"
vim.opt.updatetime = 250
vim.opt.termguicolors = true
vim.opt.background = "dark"
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- ========== lazy.nvim をブートストラップ ==========
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ========== プラグイン定義（spec を一本化） ==========
require("lazy").setup({
  -- 必要最低限（LSP + goto-preview + cmp の capabilities だけ）
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", build = ":MasonUpdate" },
  { "williamboman/mason-lspconfig.nvim" },
  { "rmagatti/goto-preview", dependencies = { "nvim-lua/plenary.nvim" } },
  { "hrsh7th/nvim-cmp" },
  { "hrsh7th/cmp-nvim-lsp" },
}, {
  ui = { border = "rounded" },
  defaults = { lazy = false, version = false },
  performance = {
    cache = { enabled = true },
    rtp = { disabled_plugins = { "gzip", "matchit", "matchparen", "tarPlugin", "tohtml", "tutor", "zipPlugin" } },
  },
})

-- 便利コマンド（任意）
vim.keymap.set("n", ",m", ":Mason<CR>", { noremap = true, desc = "Open Mason UI" })
vim.keymap.set("n", ",i", ":LspInfo<CR>", { noremap = true, desc = "Show LSP Info" })

-- ========== 自作 LSP モジュール ==========
require("guchio.lsp").setup()