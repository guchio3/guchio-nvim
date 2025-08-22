return {
  {
    "ErichDonGubler/lsp_lines.nvim",
    event = "VeryLazy",
    config = function()
      local ok_lines, lsp_lines = pcall(require, "lsp_lines")
      if ok_lines then lsp_lines.setup() end

      -- Icons (fallback to ASCII if Nerd Font isn't available)
      local nerd = vim.g.have_nerd_font ~= false
      local icons = nerd and {
        Error = "", Warn = "", Info = "", Hint = "",
      } or {
        Error = "E", Warn = "W", Info = "I", Hint = "H",
      }

      for type, icon in pairs(icons) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
      end

      -- Diagnostic config
      vim.diagnostic.config({
        signs = true,
        underline = true,
        severity_sort = true,
        update_in_insert = false,
        float = { border = "rounded", source = "if_many", scope = "cursor" },
        virtual_lines = false,
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
          -- show only first line to avoid wrapping
          format = function(d)
            return (d.message:gsub("\n.*$", ""))
          end,
        },
      })

      -- Palette (visible on dark themes)
      local palette = {
        error = "#e86671",
        warn  = "#e5c07b",
        info  = "#61afef",
        hint  = "#98c379",
      }

      local function sethl(name, spec) pcall(vim.api.nvim_set_hl, 0, name, spec) end
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

        -- colored undercurls
        sethl("DiagnosticUnderlineError", { undercurl = true, sp = palette.error })
        sethl("DiagnosticUnderlineWarn",  { undercurl = true, sp = palette.warn })
        sethl("DiagnosticUnderlineInfo",  { undercurl = true, sp = palette.info })
        sethl("DiagnosticUnderlineHint",  { undercurl = true, sp = palette.hint })
      end
      apply_hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = apply_hl })

      -- Toggle virtual lines <-> virtual text
      vim.keymap.set("n", ",x", function()
        local cfg = vim.diagnostic.config()
        local use_lines = not cfg.virtual_lines
        vim.diagnostic.config({
          virtual_lines = use_lines,
          virtual_text  = not use_lines,
        })
        if use_lines and not ok_lines then
          vim.notify("virtual_lines enabled but lsp_lines.nvim missing", vim.log.levels.WARN)
        end
      end, { desc = "Toggle diagnostics: virtual lines <-> virtual text" })
    end,
  },
}
