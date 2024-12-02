return {
    "akinsho/bufferline.nvim",
    version = "v4.*", -- Automatically pulls the latest stable version
    lazy = false, -- Load the plugin immediately
    dependencies = { "nvim-tree/nvim-web-devicons" }, -- Optional: for file icons
    config = function()
        require("bufferline").setup({
            options = {
                mode = "tabs",
                numbers = "none", -- Can be "none", "ordinal", "buffer_id", or "both"
                close_command = "bdelete! %d", -- Command to close a buffer
                indicator = { icon = "▎", style = "icon" }, -- Visual indicator for the active buffer
                buffer_close_icon = "",
                modified_icon = "●",
                left_trunc_marker = "",
                right_trunc_marker = "",
                max_name_length = 18, -- Truncate buffer names
                max_prefix_length = 15, -- Truncate file path prefixes
                tab_size = 18,
                diagnostics = "nvim_lsp", -- Show diagnostics (or set to "coc", "ale", etc.)
                diagnostics_indicator = function(count, level)
                    local icon = level:match("error") and "" or ""
                    return " " .. icon .. count
                end,
                offsets = {
                    {
                        filetype = "NvimTree",
                        text = "File Explorer", -- Text to display next to the offset
                        text_align = "center",
                        separator = true,
                    },
                },
                show_buffer_icons = true, -- Show file type icons
                show_buffer_close_icons = true, -- Show close icons on each buffer
                show_close_icon = true, -- Show close icon in the bufferline
                separator_style = "slant", -- Options: "slant", "padded_slant", "thick", "thin", etc.
                enforce_regular_tabs = false, -- Ensure all tabs are the same width
                always_show_bufferline = true, -- Show bufferline even with one buffer
            },
        })
    end,
    keys = {
        { "<Tab>", ":BufferLineCycleNext<CR>", desc = "Next buffer", silent = true },
        { "<S-Tab>", ":BufferLineCyclePrev<CR>", desc = "Previous buffer", silent = true },
        { "<leader>bp", ":BufferLinePick<CR>", desc = "Pick buffer" },
        { "<leader>bc", ":BufferLinePickClose<CR>", desc = "Pick and close buffer" },
    },
}
