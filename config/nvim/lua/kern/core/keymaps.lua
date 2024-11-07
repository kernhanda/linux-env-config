-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- convenience

keymap.set("n", "<leader>//", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "<leader>n", "<cmd>bn<cr>", { desc = "Next buffer" })
keymap.set("n", "<leader>p", "<cmd>bp<cr>", { desc = "Prev buffer" })
keymap.set("n", "<leader>ww", "<cmd>set wrap!<cr>", { desc = "Toggle word wrap" })

keymap.set("n", "<leader>tc", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tw", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>t.", "<cmd>tabn<CR>", { desc = "Next tab" })
keymap.set("n", "<leader>t,", "<cmd>tabp<CR>", { desc = "Prev tab" })
keymap.set("n", "<leader>td", "<cmd>tabnew %<CR>", { desc = "Dupe current buffer in new tab" })


keymap.set("n", "<leader>zz", "<cmd>ObsidianQuickSwitch TODO<cr>", { desc = "Obsidian TODO" })
keymap.set("n", "<leader>zx", "<cmd>ObsidianToday<cr>", { desc = "Obsidian Today" })
keymap.set("n", "<leader>zX", "<cmd>ObsidianYesterday<cr>", { desc = "Obsidian Yesterday" })
keymap.set("n", "<leader>za", "<cmd>ObsidianNew<cr>", { desc = "Obsidian New" })
keymap.set("n", "<leader>zw", "<cmd>ObsidianWorkspace<cr>", { desc = "Obsidian Workspace" })
keymap.set("n", "<leader>zs", "<cmd>ObsidianSearch<cr>", { desc = "Obsidian Search" })

keymap.set("n", "<leader>ev", "<cmd>tabnew $HOME/.config/nvim<cr>", { desc = "Edit $MYVIMRC" })

keymap.set("n", "<leader>bb", "<cmd>ZenMode<cr>", { desc = "ZenMode" })
