-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- convenience

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

keymap.set("n", "<leader>n", "<cmd>bn<cr>", { desc = "Next buffer" })
keymap.set("n", "<leader>p", "<cmd>bp<cr>", { desc = "Prev buffer" })
keymap.set("n", "<leader>ww", "<cmd>set wrap!<cr>", { desc = "Toggle word wrap" })

keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>ty", "<cmd>tabn<CR>", { desc = "Next tab" })
keymap.set("n", "<leader>tr", "<cmd>tabp<CR>", { desc = "Prev tab" })
keymap.set("n", "<leader>td", "<cmd>tabnew %<CR>", { desc = "Dupe current buffer in new tab" })

keymap.set("n", "<leader>!!", "<cmd>Hardtime toggle<cr>", { desc = "Toggle hardtime" })
