-- Flash.nvim configuration
-- Fast navigation with search labels

local function setupCustomHighlightGroup()
  vim.api.nvim_command("hi clear FlashMatch")
  vim.api.nvim_command("hi clear FlashCurrent")
  vim.api.nvim_command("hi clear FlashLabel")
  vim.api.nvim_command("hi clear FlashBackdrop")

  vim.api.nvim_command("hi FlashMatch guibg=#3b4261 guifg=#7aa2f7 gui=bold")
  vim.api.nvim_command("hi FlashCurrent guibg=#9ece6a guifg=#1a1b26 gui=bold")
  vim.api.nvim_command("hi FlashLabel guibg=#ff9e64 guifg=#1a1b26 gui=bold")
  vim.api.nvim_command("hi FlashBackdrop guibg=NONE guifg=#545c7e")
end

return {
  {
    "folke/flash.nvim",
    opts = {
      rainbow = {
        enabled = true,
        shade = 5,
      },
      highlight = {
        backdrop = true,
        groups = {
          match = "FlashMatch",
          current = "FlashCurrent",
          backdrop = "FlashBackdrop",
          label = "FlashLabel",
        },
      },
    },
    config = function()
      setupCustomHighlightGroup()
    end,
  },
}
