-- file explorer
return {
    "nvim-tree/nvim-tree.lua",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
        local nvimtree = require("nvim-tree")

        -- recommended settings from nvim-tree documentation
        vim.g.loaded_netrw = 1
        vim.g.loaded_netrwPlugin = 1

        nvimtree.setup({
            view = {
                width = 35,
                relativenumber = true,
            },
            -- change folder arrow icons
            renderer = {
                indent_markers = {
                    enable = true,
                },
                icons = {
                    glyphs = {
                        folder = {
                            arrow_closed = "",
                            arrow_open = "",
                        },
                    },
                },
            },
            -- disable window_picker for explorer to work well with window splits
            actions = {
                open_file = {
                    window_picker = {
                        enable = false,
                    },
                },
            },
            filters = {
                custom = { ".DS_Store", "^.git$" },
            },
            git = {
                ignore = false,
            },
        })

        local api = require("nvim-tree.api")
        local keymap = vim.keymap

        local nvimTreeFocusOrToggle = function()
            local nvimTree = require("nvim-tree.api")
            local currentBuf = vim.api.nvim_get_current_buf()
            local currentBufFt = vim.api.nvim_get_option_value("filetype", { buf = currentBuf })
            if currentBufFt == "NvimTree" then
                nvimTree.tree.toggle()
            else
                nvimTree.tree.open()
            end
        end

        keymap.set("n", "?", api.tree.toggle_help)
        keymap.set("n", "<leader>ee", nvimTreeFocusOrToggle, { desc = "Toggle file explorer" })
        keymap.set("n", "<leader>ef", "<cmd>NvimTreeFindFile<CR>", { desc = "Toggle file explorer on current file" })
        keymap.set("n", "<leader>ec", "<cmd>NvimTreeClose<CR>", { desc = "Collapse file explorer" })
        keymap.set("n", "<leader>er", "<cmd>NvimTreeRefresh<CR>", { desc = "Refresh file explorer" })

        api.events.subscribe(api.events.Event.FileCreated, function(file)
            vim.cmd("edit " .. file.fname)
        end)
    end,
}
