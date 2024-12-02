return {
    "ThePrimeagen/harpoon",
    lazy = false, -- Load immediately for quick access
    dependencies = { "nvim-lua/plenary.nvim" }, -- Required dependency
    config = function()
        local harpoon = require("harpoon")
        local mark = require("harpoon.mark")
        local ui = require("harpoon.ui")

        harpoon.setup({
            global_settings = {
                save_on_toggle = true, -- Save the harpoon list when toggling the menu
                save_on_change = true, -- Automatically save changes to the harpoon list
                enter_on_sendcmd = false, -- Stay in the menu after sending a command
                excluded_filetypes = { "NvimTree" }, -- Exclude certain filetypes
                mark_branch = true, -- Separate marks by Git branch
            },
        })

        -- Keybindings
        vim.keymap.set("n", "<leader>ha", mark.add_file, { desc = "Add file to Harpoon" })
        vim.keymap.set("n", "<leader>hm", ui.toggle_quick_menu, { desc = "Toggle Harpoon menu" })
        vim.keymap.set("n", "<leader>1", function()
            ui.nav_file(1)
        end, { desc = "Navigate to Harpoon file 1" })
        vim.keymap.set("n", "<leader>2", function()
            ui.nav_file(2)
        end, { desc = "Navigate to Harpoon file 2" })
        vim.keymap.set("n", "<leader>3", function()
            ui.nav_file(3)
        end, { desc = "Navigate to Harpoon file 3" })
        vim.keymap.set("n", "<leader>4", function()
            ui.nav_file(4)
        end, { desc = "Navigate to Harpoon file 4" })
    end,
}
