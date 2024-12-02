return {
    "mbbill/undotree",
    lazy = true,
    cmd = "UndotreeToggle", -- Load plugin when this command is executed
    keys = {
        {
            "<leader>u", -- Keybinding for toggling undotree
            ":UndotreeToggle<CR>", -- Command to toggle undotree
            desc = "Toggle Undotree", -- Description for the keybinding
            silent = true,
        },
    },
    config = function()
        -- Optional configurations
        vim.g.undotree_SplitWidth = 30 -- Set the width of the undotree window
        vim.g.undotree_SetFocusWhenToggle = 1 -- Automatically focus undotree window on toggle
        vim.g.undotree_WindowLayout = 3 -- Use a preferred layout
        vim.o.undofile = true -- Enable persistent undo
        vim.o.undodir = vim.fn.stdpath("data") .. "/undo" -- Set undo file directory
    end,
}
