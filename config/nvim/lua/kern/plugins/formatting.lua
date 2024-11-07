-- formatting
return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")

        conform.setup({
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                cpp = { "clang-format" },
                rust = { "rustfmt" },
            },
            format_on_save = {
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
            },
            -- Set the log level. Use `:ConformInfo` to see the location of the log file.
            log_level = vim.log.levels.ERROR,
            -- Conform will notify you when a formatter errors
            notify_on_error = true,
        })

        vim.keymap.set({ "n", "v" }, "<leader>mp", function()
            conform.format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
            })
        end, { desc = "Format file or range (in visual mode)" })

        vim.keymap.set({ "n", "v" }, "<leader>ms", function()
            conform.format({
                formatters = { "codespell" },
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
            })
        end, { desc = "Spellcheck file or range (in visual mode)" })
    end,
}
