-- set leader key to space
vim.g.mapleader = " "

local keymap = vim.keymap -- convenience

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear search highlights" })

keymap.set("n", "x", '"_x') -- deletes single character without copying into register

keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" })
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" })

keymap.set("n", "<leader>wv", "<C-w>v", { desc = "Split window vertically" })
keymap.set("n", "<leader>wh", "<C-w>s", { desc = "Split window horizontally" })
keymap.set("n", "<leader>wc", "<cmd>close<CR>", { desc = "Close current split" })

keymap.set("n", "<leader>tn", "<cmd>tabnew<CR>", { desc = "Open new tab" })
keymap.set("n", "<leader>tc", "<cmd>tabclose<CR>", { desc = "Close current tab" })
keymap.set("n", "<leader>ty", "<cmd>tabn<CR>", { desc = "Next tab" })
keymap.set("n", "<leader>tr", "<cmd>tabp<CR>", { desc = "Prev tab" })
keymap.set("n", "<leader>td", "<cmd>tabnew %<CR>", { desc = "Dupe current buffer in new tab" })


