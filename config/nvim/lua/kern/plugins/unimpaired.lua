return {
    "tpope/vim-unimpaired",
    lazy = true, -- Lazy load the plugin
    keys = {
        { "[b", desc = "Previous buffer" },
        { "]b", desc = "Next buffer" },
        { "[e", desc = "Move to the previous file in the quickfix list" },
        { "]e", desc = "Move to the next file in the quickfix list" },
        { "[q", desc = "Move to the previous item in the quickfix list" },
        { "]q", desc = "Move to the next item in the quickfix list" },
        { "[<Space>", desc = "Add a blank line above" },
        { "]<Space>", desc = "Add a blank line below" },
    },
    init = function()
        -- Optional: Add any additional setup here
        -- For example, configuring custom keybindings if needed.
        vim.g.unimpaired_no_default_key_mappings = false -- Use default mappings
    end,
}
