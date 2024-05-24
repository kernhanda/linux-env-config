-- allows for window maximization/restore
return {
  "szw/vim-maximizer",
  keys = {
    { "<leader>wm", "<cmd>MaximizerToggle<CR>", desc = "Maximize/minimize a split" },
  },
}
