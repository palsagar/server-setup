-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Python-specific keymaps
vim.api.nvim_create_autocmd("FileType", {
  pattern = "python",
  callback = function()
    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = true, desc = desc })
    end

    -- Ruff: Fix all issues
    map("n", "<leader>rf", function()
      vim.lsp.buf.code_action({
        filter = function(action)
          return action.title:match("Fix all") or action.title:match("Ruff")
        end,
        apply = true,
      })
    end, "Ruff: Fix all")

    -- Ruff: Organize imports
    map("n", "<leader>ro", function()
      vim.lsp.buf.code_action({
        filter = function(action)
          return action.title:match("Organize imports") or action.title:match("Import")
        end,
        apply = true,
      })
    end, "Ruff: Organize imports")

    -- Format with Ruff
    map("n", "<leader>cf", function()
      require("conform").format({
        lsp_format = "never",
      })
    end, "Format with Ruff")
  end,
  desc = "Set Python keymaps",
})
