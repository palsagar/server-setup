return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left split/pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to below split/pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to above split/pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right split/pane" },
      { "<C-\\>", "<cmd>TmuxNavigatePrevious<cr>", desc = "Go to previous split/pane" },
    },
  },
}
