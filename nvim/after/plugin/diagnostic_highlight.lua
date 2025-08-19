-- VS Code風の診断配色（背景色付き）
local sethl = vim.api.nvim_set_hl

-- フロートのベース背景
sethl(0, "NormalFloat", { bg = "#1f1f1f" })
sethl(0, "FloatBorder", { fg = "#3B3B3B", bg = "#1f1f1f" })

-- VS Code風の色
sethl(0, "DiagnosticError", { fg = "#F14C4C" })
sethl(0, "DiagnosticWarn",  { fg = "#CCA700" })
sethl(0, "DiagnosticInfo",  { fg = "#3794FF" })
sethl(0, "DiagnosticHint",  { fg = "#10B981" })

-- 下線
sethl(0, "DiagnosticUnderlineError", { undercurl = true, sp = "#F14C4C" })
sethl(0, "DiagnosticUnderlineWarn",  { undercurl = true, sp = "#CCA700" })
sethl(0, "DiagnosticUnderlineInfo",  { undercurl = true, sp = "#3794FF" })
sethl(0, "DiagnosticUnderlineHint",  { undercurl = true, sp = "#10B981" })

-- フロート用（背景色つき）
sethl(0, "DiagnosticFloatingError", { fg = "#F14C4C", bg = "#2a1e1e" })
sethl(0, "DiagnosticFloatingWarn",  { fg = "#CCA700", bg = "#2a281a" })
sethl(0, "DiagnosticFloatingInfo",  { fg = "#3794FF", bg = "#1e2430" })
sethl(0, "DiagnosticFloatingHint",  { fg = "#10B981", bg = "#152a22" })

-- サイン列
vim.fn.sign_define("DiagnosticSignError", { text = "●", texthl = "DiagnosticError" })
vim.fn.sign_define("DiagnosticSignWarn",  { text = "●", texthl = "DiagnosticWarn" })
vim.fn.sign_define("DiagnosticSignInfo",  { text = "●", texthl = "DiagnosticInfo" })
vim.fn.sign_define("DiagnosticSignHint",  { text = "●", texthl = "DiagnosticHint" })