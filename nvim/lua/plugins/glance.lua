return {
  "dnlhc/glance.nvim",
  event = "LspAttach",
  config = function()
    local glance = require("glance")
    local actions = glance.actions

    local function jump_and_close(fn)
      return function(...)
        fn(...)
        vim.schedule(function()
          if glance.is_open() then
            actions.close()
          end
        end)
      end
    end

    glance.setup({
      -- VSCode の Peek 風に常時フローティング
      detached = true,
      height = 18,
      preview_win_opts = { number = true, cursorline = true, wrap = true },

      -- 結果 1 件ならウィンドウを出さず即ジャンプ
      hooks = {
        before_open = function(results, open, jump, method)
          if method == "references" then
            local uri = vim.uri_from_bufnr(0)
            local pos = vim.api.nvim_win_get_cursor(0)
            local line, col = pos[1] - 1, pos[2]
            local filtered = {}
            for _, res in ipairs(results) do
              local r_uri = res.uri or res.targetUri
              local r_range = res.range or res.targetSelectionRange
              if not (r_uri == uri and r_range.start.line == line and r_range.start.character == col) then
                table.insert(filtered, res)
              end
            end
            results = filtered
          end

          if #results == 0 then
            return
          elseif #results == 1 then
            jump(results[1])
          else
            open(results)
          end
        end,
      },

      -- ジャンプ後に自動クローズ
      mappings = {
        list = {
          ["<CR>"] = jump_and_close(actions.jump),
          -- お好みで分割やタブジャンプ後も閉じる
          ["s"] = jump_and_close(actions.jump_split),
          ["v"] = jump_and_close(actions.jump_vsplit),
          ["t"] = jump_and_close(actions.jump_tab),
          ["q"] = actions.close,
          ["<Esc>"] = actions.close,
        },
        preview = {
          ["q"] = actions.close,
          ["<Esc>"] = actions.close,
        },
      },
    })

    -- 既存の UX を維持しつつ Glance に切り替え
    vim.keymap.set("n", "<C-]>", "<Cmd>Glance definitions<CR>", { desc = "Peek definitions (Glance)" })
    vim.keymap.set("n", "<C-[>", "<Cmd>Glance references<CR>", { desc = "Peek references (Glance)" })
  end,
}
