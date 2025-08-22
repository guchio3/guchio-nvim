return {
  {
    "neovim/nvim-lspconfig",
    event = "VeryLazy",
    config = function()
      -- Icons: default to ASCII; enable Nerd Font only if explicitly set
      local nerd = (vim.g.have_nerd_font == true)
      local icons = nerd and {
        Error = "", Warn = "", Info = "", Hint = "",
      } or {
        Error = "E",  Warn = "W",  Info = "I",  Hint = "H",
      }

      -- Define diagnostic signs (no numhl/bg fill)
      for type, icon in pairs(icons) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Global diagnostic configuration (built-in handlers)
      vim.diagnostic.config({
        signs = true,
        underline = true,
        severity_sort = true,
        update_in_insert = false,
        float = { border = "rounded", source = "if_many", scope = "cursor" },
        virtual_lines = false, -- default: inline virtual text
        virtual_text = {
          spacing = 1,
          source = "if_many",
          prefix = function(diag)
            local s = diag.severity
            local map = {
              [vim.diagnostic.severity.ERROR] = icons.Error,
              [vim.diagnostic.severity.WARN]  = icons.Warn,
              [vim.diagnostic.severity.INFO]  = icons.Info,
              [vim.diagnostic.severity.HINT]  = icons.Hint,
            }
            return map[s] or "●"
          end,
          -- show only the first line to avoid wrapping
          format = function(d) return (d.message:gsub("\n.*$", "")) end,
        },
      })

        -- Palette (works on dark themes)
        local palette = {
          error = "#e86671", warn = "#e5c07b", info = "#61afef", hint = "#98c379",
        }
        -- Users can opt-out of undercurl via: vim.g.no_undercurl = true
        local function sethl(n, s) pcall(vim.api.nvim_set_hl, 0, n, s) end
        local function apply_hl()
        -- no background blocks; just colored text/signs
        sethl("DiagnosticError", { fg = palette.error, bg = "NONE" })
        sethl("DiagnosticWarn",  { fg = palette.warn,  bg = "NONE" })
        sethl("DiagnosticInfo",  { fg = palette.info,  bg = "NONE" })
        sethl("DiagnosticHint",  { fg = palette.hint,  bg = "NONE" })
        -- virtual text (subtle)
        sethl("DiagnosticVirtualTextError", { fg = palette.error, bg = "NONE", italic = true })
        sethl("DiagnosticVirtualTextWarn",  { fg = palette.warn,  bg = "NONE", italic = true })
        sethl("DiagnosticVirtualTextInfo",  { fg = palette.info,  bg = "NONE", italic = true })
        sethl("DiagnosticVirtualTextHint",  { fg = palette.hint,  bg = "NONE", italic = true })
        -- colored undercurls (fall back to plain underline if disabled)
        local uc = not vim.g.no_undercurl
        sethl("DiagnosticUnderlineError", uc and { undercurl = true, sp = palette.error } or { underline = true })
        sethl("DiagnosticUnderlineWarn",  uc and { undercurl = true, sp = palette.warn }  or { underline = true })
        sethl("DiagnosticUnderlineInfo",  uc and { undercurl = true, sp = palette.info }  or { underline = true })
        sethl("DiagnosticUnderlineHint",  uc and { undercurl = true, sp = palette.hint }  or { underline = true })
      end
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })

      -- Toggle built-in virtual_lines <-> virtual_text
      vim.keymap.set("n", ",x", function()
        local cfg = vim.diagnostic.config() -- returns current config (0.11+)
        local use_lines = not (cfg.virtual_lines or false)
        vim.diagnostic.config({
          virtual_lines = use_lines,
          virtual_text  = not use_lines,
        })
      end, { desc = "Toggle diagnostics: virtual lines <-> virtual text" })
    end,
  },
}
