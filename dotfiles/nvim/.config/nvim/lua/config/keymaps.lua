-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.api.nvim_set_keymap('t', '<C-PageUp>', '<C-\\><C-n>', { noremap = true })

-- <leader>gg: hunk.nvim in a jj repo, lazygit everywhere else.
-- jj-managed iff a `.jj` dir exists above the buffer. There we open a Snacks
-- float running `jj diffedit`; jj spawns hunk.nvim as its diff-editor (see
-- lua/plugins/hunk.lua + ~/.jjconfig.toml). Otherwise fall back to LazyVim's
-- default lazygit-at-root. <leader>gG stays lazygit (cwd) as an escape hatch.
-- Overrides the default set in lazyvim.config.keymaps (user keymaps load last).
vim.keymap.set("n", "<leader>gg", function()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.uv.cwd()
  end
  local jj = vim.fs.root(path, ".jj")
  if jj then
    Snacks.terminal.open("jj diffedit", { cwd = jj })
  else
    Snacks.lazygit({ cwd = LazyVim.root.git() })
  end
end, { desc = "Hunk (jj) or Lazygit (Root Dir)" })
