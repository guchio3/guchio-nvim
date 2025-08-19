-- 既存の診断フロート設定と重複しないよう注意
-- すでにlsp.luaで設定されている場合はこのファイルは不要
-- 重複している場合は、lsp.lua側のautocmdをコメントアウトしてこちらを使用

--[[ カーソル位置だけに診断フロートを表示（行内全部は出さない）
local grp = vim.api.nvim_create_augroup("DiagFloatCursorOnly", { clear = true })
vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
  group = grp,
  callback = function()
    vim.diagnostic.open_float(0, {
      scope = "cursor",   -- 行全体ではなくカーソル直下
      focus = false,
      border = "rounded",
      source = "if_many",
      close_events = { "BufLeave", "CursorMoved", "InsertEnter", "FocusLost" },
      severity_sort = true,
    })
  end,
})
--]]