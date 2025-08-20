-- lua/guchio/lsp.lua
local M = {}

-- 二重読込ガード
if rawget(_G, "__guchio_lsp_loaded__") then
  return M
end
_G.__guchio_lsp_loaded__ = true

local lspconfig = require("lspconfig")
local util = require("lspconfig.util")

-- nvim-cmp があれば capabilities を上乗せ
local capabilities = vim.lsp.protocol.make_client_capabilities()
pcall(function()
  capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
end)

-- ── 診断 UI（カーソル直下だけフロート） ────────────────────────────────
local function setup_diagnostics_ui()
  vim.diagnostic.config({
    virtual_text = false,
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = { border = "rounded", source = "if_many" },
  })

  local grp = vim.api.nvim_create_augroup("GuchioDiagFloatCursor", { clear = true })
  vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
    group = grp,
    callback = function()
      vim.diagnostic.open_float(0, {
        scope = "cursor",
        focus = false,
        border = "rounded",
        source = "if_many",
        close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
        severity_sort = true,
      })
    end,
  })
end

-- ── Smart <C-]>: 定義 / 定義上なら参照（高速判定） ─────────────────────────
local function pos_in_range(pos, range)
  if not range then return false end
  local l, c = pos[1], pos[2]
  local sL, sC = range.start.line, range.start.character
  local eL, eC = range["end"].line, range["end"].character
  if l < sL or l > eL then return false end
  if l == sL and c < sC then return false end
  if l == eL and c > eC then return false end
  return true
end

local function cursor_at_definition(timeout_ms)
  local params = vim.lsp.util.make_position_params()
  local res = vim.lsp.buf_request_sync(0, "textDocument/definition", params, timeout_ms or 120)
  if not res then return false end
  local cur = vim.api.nvim_win_get_cursor(0)
  cur[1] = cur[1] - 1 -- 0-index
  local cururi = vim.uri_from_bufnr(0)
  for _, r in pairs(res) do
    local v = r and r.result
    if v then
      if v.uri and v.range then
        if v.uri == cururi and pos_in_range(cur, v.range) then return true end
      elseif type(v) == "table" then
        for _, loc in ipairs(v) do
          if loc.targetUri and loc.targetRange then
            if loc.targetUri == cururi and pos_in_range(cur, loc.targetRange) then return true end
          elseif loc.uri and loc.range then
            if loc.uri == cururi and pos_in_range(cur, loc.range) then return true end
          end
        end
      end
    end
  end
  return false
end

-- ── on_attach: キー配置 / basedpyright の診断停止 ─────────────────────────
local function on_attach(client, bufnr)
  -- basedpyright の診断は完全停止（Ruff のみ表示）
  if client and client.name == "basedpyright" then
    client.handlers["textDocument/publishDiagnostics"] = function() end
    -- 既出の診断を全消去（Ruff は直後に再配信される）
    vim.schedule(function() pcall(vim.diagnostic.reset, nil, bufnr) end)
  end

  -- 競合しやすいグローバルの <C-n>/<C-p> を先に削除してから buffer-local を貼る
  pcall(vim.keymap.del, "n", "<C-n>")
  pcall(vim.keymap.del, "n", "<C-p>")

  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
  end

  -- 定義/参照: goto-preview があればフロート、無ければフォールバック
  local function smart_cbracket()
    local ok, gp = pcall(require, "goto-preview")
    if cursor_at_definition(120) then
      if ok and gp.goto_preview_references then return gp.goto_preview_references() end
      return vim.lsp.buf.references()
    else
      if ok and gp.goto_preview_definition then return gp.goto_preview_definition() end
      return vim.lsp.buf.definition()
    end
  end

  map("n", "K",  vim.lsp.buf.hover, "Hover")
  map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
  map("n", "<C-]>", smart_cbracket, "Smart Peek: def / refs")
  map("n", "gr", function()
    local ok, gp = pcall(require, "goto-preview")
    if ok and gp.goto_preview_references then return gp.goto_preview_references() end
    return vim.lsp.buf.references()
  end, "Peek References")
  map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
  map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")

  -- 診断ジャンプ（安定 API・nowait 不使用）
  map("n", "<C-n>", function() vim.diagnostic.goto_next({}) end, "Next diagnostic")
  map("n", "<C-p>", function() vim.diagnostic.goto_prev({}) end, "Prev diagnostic")
  map("n", "]d",   function() vim.diagnostic.goto_next({}) end)
  map("n", "[d",   function() vim.diagnostic.goto_prev({}) end)
end

-- ── Mason / LSP サーバ起動（setup_handlers は 1 箇所・フォールバック有） ───
local function setup_servers_with_mason()
  local ok_mason, mason = pcall(require, "mason")
  if ok_mason then mason.setup() end

  local ok_mlsp, mlsp = pcall(require, "mason-lspconfig")
  if not (ok_mlsp and type(mlsp.setup) == "function") then
    return false
  end

  mlsp.setup({ ensure_installed = { "lua_ls", "basedpyright", "ruff" } })
  if type(mlsp.setup_handlers) ~= "function" then
    return false
  end

  mlsp.setup_handlers({
    function(server)
      local opts = { capabilities = capabilities, on_attach = on_attach }
      if server == "lua_ls" then
        opts.settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            diagnostics = { globals = { "vim" } },
            telemetry = { enable = false },
          },
        }
      elseif server == "basedpyright" then
        opts.root_dir = util.root_pattern("pyproject.toml", "setup.cfg", "requirements.txt", ".git")
        opts.settings = {
          python = {
            analysis = {
              typeCheckingMode = "basic",
              autoSearchPaths = true,
              useLibraryCodeForTypes = true,
              -- 必要なら extraPaths = { "./src", "./scripts" },
            },
          },
          basedpyright = { disableOrganizeImports = true },
        }
      elseif server == "ruff" then
        opts.root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git")
        opts.init_options = { settings = { logLevel = "warning" } }
      end
      lspconfig[server].setup(opts)
    end,
  })
  return true
end

local function setup_servers_plain()
  local function setup_one(name, opts)
    opts = opts or {}
    opts.capabilities = capabilities
    opts.on_attach = on_attach
    lspconfig[name].setup(opts)
  end

  setup_one("lua_ls", {
    settings = {
      Lua = {
        workspace = { checkThirdParty = false },
        diagnostics = { globals = { "vim" } },
        telemetry = { enable = false },
      },
    },
  })

  setup_one("basedpyright", {
    root_dir = util.root_pattern("pyproject.toml", "setup.cfg", "requirements.txt", ".git"),
    settings = {
      python = { analysis = { typeCheckingMode = "basic", autoSearchPaths = true, useLibraryCodeForTypes = true } },
      basedpyright = { disableOrganizeImports = true },
    },
  })

  setup_one("ruff", {
    root_dir = util.root_pattern("pyproject.toml", "ruff.toml", ".git"),
    init_options = { settings = { logLevel = "warning" } },
  })
end

function M.setup()
  setup_diagnostics_ui()

  -- goto-preview（あれば初期化）
  local ok, gp = pcall(require, "goto-preview")
  if ok then
    gp.setup({
      default_mappings = false,
      resizing_mappings = false,
      width = 100,
      height = 18,
      border = "rounded",
      post_open_hook = function(_, win) pcall(vim.api.nvim_win_set_option, win, "winblend", 3) end,
    })
  end

  if not setup_servers_with_mason() then
    setup_servers_plain()
  end
end

return M