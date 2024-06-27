return {
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp" },
    dependencies = {
        "VonHeikemen/lsp-zero.nvim",
        "neovim/nvim-lspconfig",
        "nvim-lua/plenary.nvim",
    },
    config = function()
        local compile_commands_dir = vim.env.COMPILE_COMMANDS_DIR
        local compile_commands_opt = ""
        if compile_commands_dir ~= nil then
            compile_commands_opt = "--compile-commands-dir=" .. compile_commands_dir
        end
        local server_options = require("lsp-zero").build_options("clangd", {
            cmd = {
                "clangd",
                compile_commands_opt,
                "-j=4",
                "--clang-tidy",
                "--background-index",
                "--header-insertion=never",
                "--fallback-style=webkit",
                "--all-scopes-completion",
                "--completion-style=detailed",
                "--pch-storage=memory",
            },
        })
        require("lspconfig").clangd.setup(server_options)
        require("clangd_extensions").setup()
        require("clangd_extensions.inlay_hints").setup_autocmd()
        require("clangd_extensions.inlay_hints").set_inlay_hints()
    end,
}
