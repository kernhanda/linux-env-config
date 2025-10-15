-- since this is just an example spec, don't actually load anything here and return an empty spec
-- stylua: ignore
-- if true then return {} end
-- ~/.config/nvim/lua/plugins/lsp.lua
return {
  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        clangd = {
          cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=bundled" },
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
          root_dir = require("lspconfig.util").root_pattern(
            ".clangd",
            ".clang-tidy",
            ".clang-format",
            "compile_commands.json",
            "compile_flags.txt",
            ".git"
          ),
          settings = {
            clangd = {
              InlayHints = {
                Enabled = true,
                ParameterNames = true,
                DeducedTypes = true,
              },
              fallbackFlags = { "-std=c++20" }, -- Adjust C++ standard as needed
            },
          },
        },
        mojo = {
                cmd = {"mojo-lsp-server", "-I", "open-source/max/mojo/stdlib/stdlib"},
        }
      },
      setup = {
        clangd = function(_, opts)
          -- Optional: Add custom keymaps or settings for clangd
          local lspconfig = require("lspconfig")
          lspconfig.clangd.setup(opts)
        end,
        mojo = function(_, opts) end,
      },
    },
  },

  -- Treesitter Configuration
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = { "cpp", "c" }, -- Ensure C++ and C parsers are installed
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-Space>",
          node_incremental = "<C-Space>",
          scope_incremental = "<C-s>",
          node_decremental = "<C-Backspace>",
        },
      },
    },
  },

  -- Mason DAP
  {
  "jay-babu/mason-nvim-dap.nvim",
  dependencies = "mason.nvim",
  cmd = { "DapInstall", "DapUninstall" },
  opts = {
    -- Makes a best effort to setup the various debuggers with
    -- reasonable debug configurations
    automatic_installation = true,

    -- You can provide additional configuration to the handlers,
    -- see mason-nvim-dap README for more information
    handlers = {},

    -- You'll need to check that you have the required things installed
    -- online, please don't ask me how to install them :)
    ensure_installed = {
      -- Update this to ensure that you have the debuggers for the langs you want
                "codelldb",
    },
  },
  -- mason-nvim-dap is loaded when nvim-dap loads
  config = function() end,
}
}
