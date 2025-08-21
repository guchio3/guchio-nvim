-- Neovim configuration (2025 modernized version)
-- Bootstrap lazy.nvim and basic settings

-- Leader key設定
vim.g.mapleader = ","
vim.g.maplocalleader = ","

-- Disable creation of .nvimlog in working directories
vim.env.NVIM_LOG_FILE = "/dev/null"

-- Neovim 0.9+ の高速化設定
if vim.loader then
  vim.loader.enable()
end

-- 基本設定
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"
vim.opt.fileencodings = { "iso-2022-jp", "euc-jp", "sjis", "utf-8" }
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.autoread = true
vim.opt.hidden = true
vim.opt.showcmd = true
vim.opt.updatetime = 100
vim.opt.timeout = true
vim.opt.timeoutlen = 500  -- マッピングのタイムアウト（ミリ秒）
vim.opt.ttimeoutlen = 10  -- キーコードのタイムアウト（10msは安全な値）
vim.opt.cmdheight = 2
vim.opt.shortmess:append("c")
vim.opt.signcolumn = "auto"

-- 見た目系
vim.opt.number = true
vim.opt.smartindent = true
vim.opt.visualbell = true
vim.opt.showmatch = true
vim.opt.laststatus = 2
vim.opt.wildmode = "list:longest"
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.background = "dark"

-- Tab系
vim.opt.list = true
vim.opt.listchars = { tab = "▸-" }
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4

-- その他
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

-- ファイル保存時に末尾に改行を追加（POSIX準拠）
vim.opt.fixeol = true  -- ファイル末尾に改行がなければ追加

-- 検索設定
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.incsearch = true
vim.opt.wrapscan = true
vim.opt.hlsearch = true

-- lazy.nvim のブートストラップ
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- プラグイン設定をロード
require("lazy").setup({
  spec = {
    -- LazyVimのデフォルト設定を明示的に無効化
    { "LazyVim/LazyVim", enabled = false },
    { import = "plugins" },
  },
  defaults = {
    lazy = false,
    version = false,
  },
  performance = {
    cache = {
      enabled = true,
    },
    reset_packpath = true,
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  install = {
    colorscheme = { "hybrid" },
  },
})

-- カラースキーム設定
vim.cmd.colorscheme("hybrid")

-- guchio shortcuts
-- 保存
vim.keymap.set("n", ",w", ":w<CR>", { noremap = true })
-- quit
vim.keymap.set("n", ",q", ":q<CR>", { noremap = true })
-- Mason UI を開く
vim.keymap.set("n", ",m", ":Mason<CR>", { noremap = true, desc = "Open Mason UI" })
-- LSP情報を表示
vim.keymap.set("n", ",i", ":LspInfo<CR>", { noremap = true, desc = "Show LSP Info" })
-- ハイライト解除（C-c C-c）
vim.keymap.set("n", "<C-c><C-c>", ":nohlsearch<CR><Esc>", { noremap = true })
-- term insert を esc で終了
vim.keymap.set("t", "<Esc>", "<C-\\><C-n>", { noremap = true })

-- Diagnostic navigation
vim.keymap.set("n", "<C-n>", function()
  vim.diagnostic.jump({
    count = 1,
    severity = { min = vim.diagnostic.severity.WARN },
    float = true,
  })
end, { noremap = true, silent = true, desc = "Next diagnostic" })
vim.keymap.set("n", "<C-p>", function()
  vim.diagnostic.jump({
    count = -1,
    severity = { min = vim.diagnostic.severity.WARN },
    float = true,
  })
end, { noremap = true, silent = true, desc = "Prev diagnostic" })

-- カラーテーマ切り替え機能
vim.api.nvim_create_user_command("ThemeSelect", function()
  local themes = {
    "hybrid",
    "tokyonight-night", "tokyonight-storm", "tokyonight-moon", "tokyonight-day",
    "catppuccin-mocha", "catppuccin-macchiato", "catppuccin-frappe", "catppuccin-latte",
    "gruvbox",
    "kanagawa-wave", "kanagawa-dragon", "kanagawa-lotus",
  }
  
  vim.ui.select(themes, {
    prompt = "Select theme:",
    format_item = function(item)
      return item
    end,
  }, function(choice)
    if choice then
      local ok, _ = pcall(vim.cmd.colorscheme, choice)
      if ok then
        vim.notify("Theme changed to: " .. choice)
      else
        vim.notify("Failed to load theme: " .. choice, vim.log.levels.ERROR)
      end
    end
  end)
end, {})

vim.keymap.set("n", ",t", ":ThemeSelect<CR>", { noremap = true, desc = "Select color theme" })

-- 移動系
-- 折り返し時に表示行単位での移動
vim.keymap.set("n", "j", "gj", { noremap = true })
vim.keymap.set("n", "k", "gk", { noremap = true })
-- 挿入モード中にemacsキーバインドで左右に移動
vim.keymap.set("i", "<C-b>", "<Left>", { noremap = true })
vim.keymap.set("i", "<C-f>", "<Right>", { noremap = true })
