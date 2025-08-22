return {
  "dnlhc/glance.nvim",
  event = "LspAttach",
  config = function()
    local glance = require("glance")
    local actions = glance.actions

    glance.setup({
      -- VSCode の Peek 風に常時フローティング
      detached = true,
      height = 18,
      preview_win_opts = { number = true, cursorline = true, wrap = true },

      -- 結果 1 件ならウィンドウを出さず即ジャンプ
      hooks = {
        before_open = function(results, open, jump, method)
          if #results == 1 then
            jump(results[1])
          else
            open(results)
          end
        end,
      },

      -- ジャンプ後に自動クローズ
      mappings = {
        list = {
          ["<CR>"] = function()
            actions.jump()
            actions.close()
          end,
          -- お好みで分割やタブジャンプ後も閉じる
          ["s"] = function() actions.jump_split(); actions.close() end,
          ["v"] = function() actions.jump_vsplit(); actions.close() end,
          ["t"] = function() actions.jump_tab(); actions.close() end,
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
    vim.keymap.set("n", "<C-[>", "<Cmd>Glance references<CR>",  { desc = "Peek references (Glance)" })
  end,
}
