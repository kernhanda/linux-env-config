-- installs and manages lsp dependencies
return {
    "williamboman/mason.nvim",
    dependencies = {
        "williamboman/mason-lspconfig.nvim",
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
        -- import mason
        local mason = require("mason")

        -- import mason-lspconfig
        local mason_lspconfig = require("mason-lspconfig")

        local mason_tool_installer = require("mason-tool-installer")

        local lspconfig = require("lspconfig")

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        mason_lspconfig.setup({
            -- list of servers for mason to install
            ensure_installed = {
                "autotools_ls",
                "clangd",
                "lua_ls",
                "markdown_oxide",
                -- "marksman",
                "ruff",
                "rust_analyzer",
            },
        })

        mason_tool_installer.setup({
            ensure_installed = {
                "clang-format",
                "asm-lsp",
                "black",
                "tree-sitter-cli",
                "prettier",
                "isort",
                "cmake-language-server",
                "tree-sitter-cli",
                "ast-grep",
                "black",
                "clang-format",
                "cmakelang",
                "cmakelint",
                "codespell",
                "isort",
                "jedi-language-server",
                "python-lsp-server",
                "mypy",
                "prettier",
                "prettierd",
                "stylua",
            },
        })

        lspconfig.clangd.setup({
            cmd = {
                "clangd",
                "-j=4",
                "--clang-tidy",
                "--background-index",
                "--header-insertion=never",
                "--fallback-style=webkit",
                "--all-scopes-completion",
                "--completion-style=detailed",
                "--pch-storage=memory",
            }, -- Command for running clangd
            filetypes = { "c", "cpp", "objc", "objcpp" }, -- File types to use clangd for
            root_dir = require("lspconfig").util.root_pattern("compile_commands.json", "compile_flags.txt", ".git"), -- Project root detection
            capabilities = require("cmp_nvim_lsp").default_capabilities(), -- Optional: For nvim-cmp autocompletion support
            on_attach = function(client, bufnr)
                -- Key mappings for LSP commands
                local function buf_set_keymap(...)
                    vim.api.nvim_buf_set_keymap(bufnr, ...)
                end
                local opts = { noremap = true, silent = true }
                buf_set_keymap("n", "gd", "<Cmd>lua vim.lsp.buf.definition()<CR>", opts)
                buf_set_keymap("n", "K", "<Cmd>lua vim.lsp.buf.hover()<CR>", opts)
                buf_set_keymap("n", "gi", "<cmd>lua vim.lsp.buf.implementation()<CR>", opts)
                buf_set_keymap("n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", opts)
                buf_set_keymap("n", "<space>rn", "<cmd>lua vim.lsp.buf.rename()<CR>", opts)
                buf_set_keymap("n", "gr", "<cmd>lua vim.lsp.buf.references()<CR>", opts)
                buf_set_keymap("n", "<space>ca", "<cmd>lua vim.lsp.buf.code_action()<CR>", opts)
            end,
            flags = {
                debounce_text_changes = 150,
            },
        })

        lspconfig.pylsp.setup({
            -- on_attach = on_attach,
            settings = {
                pylsp = {
                    plugins = {
                        ruff = {
                            enabled = true, -- Enable the plugin
                            formatEnabled = true, -- Enable formatting using ruffs formatter
                            executable = ruff_exe, -- Custom path to ruff
                            -- config = "<path_to_custom_ruff_toml>",  -- Custom config for ruff to use
                            extendSelect = { "I" }, -- Rules that are additionally used by ruff
                            -- extendIgnore = { "C90" },  -- Rules that are additionally ignored by ruff
                            format = { "I" }, -- Rules that are marked as fixable by ruff that should be fixed when running textDocument/formatting
                            -- severities = { ["D212"] = "I" },  -- Optional table of rules where a custom severity is desired
                            unsafeFixes = true, -- Whether or not to offer unsafe fixes as code actions. Ignored with the "Fix All" action
                            -- Rules that are ignored when a pyproject.toml or ruff.toml is present:
                            lineLength = 80, -- Line length to pass to ruff checking and formatting
                            -- exclude = { "__about__.py" },  -- Files to be excluded by ruff checking
                            select = { "ALL" }, -- Rules to be enabled by ruff
                            -- Rules to be ignored by ruff:
                            -- D401: imperative docstring.
                            -- D410: blank line after Returns: in docstring.
                            -- COM812: trailing comma missing.
                            -- TD003: missing issue link on the line following this TODO.
                            ignore = { "D401", "D413", "COM812", "TD003" },
                            perFileIgnores = { ["__init__.py"] = "F401" }, -- Rules that should be ignored for specific files
                            preview = true, -- Whether to enable the preview style linting and formatting.
                            targetVersion = "py39", -- The minimum python version to target (applies for both linting and formatting).
                        },
                        jedi = {
                            environment = python_exe,
                            extra_paths = {
                                api_generated_pkgs,
                                api_source_pkgs,
                                pipelines_source_pkgs,
                            },
                        },
                        -- Type checking.
                        pylsp_mypy = {
                            enabled = true,
                            -- overrides = {
                            --     "--python-executable", python_exe,
                            --     "--show-column-numbers",
                            --     "--show-error-codes",
                            --     "--no-pretty",
                            --     true,
                            -- },
                            -- report_progress = true,
                            -- live_mode = true,
                        },
                        pylint = {
                            enabled = false, -- Disable pylint to avoid conflicts
                        },
                        -- import sorting
                        isort = { enabled = true },
                    },
                },
            },
            flags = {
                debounce_text_changes = 200,
            },
            before_init = function(_, config)
                local path_to_append = vim.fn.expand(
                )
                config.env = config.env or {}
                config.env.PYTHONPATH = ((config.env.PYTHONPATH and (config.env.PYTHONPATH .. ":")) or "")
                    .. path_to_append
                config.env.MYPYPATH = ((config.env.MYPYPATH and (config.env.MYPYPATH .. ":")) or "") .. path_to_append
            end,
        })
    end,
}
