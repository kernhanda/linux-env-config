-- since this is just an example spec, don't actually load anything here and return an empty spec
-- stylua: ignore
-- if true then return {} end
-- ~/.config/nvim/lua/plugins/lsp.lua
local function setupCustomHighlightGroup()
	vim.api.nvim_command("hi clear FlashMatch")
	vim.api.nvim_command("hi clear FlashCurrent")
	vim.api.nvim_command("hi clear FlashLabel")
    vim.api.nvim_command("hi clear FlashBackdrop")

	vim.api.nvim_command("hi FlashMatch guibg=#3b4261 guifg=#7aa2f7 gui=bold")
	vim.api.nvim_command("hi FlashCurrent guibg=#9ece6a guifg=#1a1b26 gui=bold")
	vim.api.nvim_command("hi FlashLabel guibg=#ff9e64 guifg=#1a1b26 gui=bold")
    vim.api.nvim_command("hi FlashBackdrop guibg=NONE guifg=#545c7e")
end

return {
  {
    "folke/flash.nvim",
    opts = {
      rainbow = {
        enabled = true,
        shade = 5,
      },
      highlight = {
        backdrop = true,
        groups = {
          match = "FlashMatch",
          current = "FlashCurrent",
          backdrop = "FlashBackdrop",
          label = "FlashLabel",
        },
      },
    },
    config = function()
      setupCustomHighlightGroup()
    end,
  },
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
          cmd = { "mojo-lsp-server", "-I", "open-source/max/mojo/stdlib/stdlib" },
        },
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
      ensure_installed = { "cpp", "c", "python" }, -- Ensure C++ and C parsers are installed
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
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
  },
  {
    "xTacobaco/cursor-agent.nvim",
    config = function()
      vim.keymap.set("n", "<leader>zz", ":CursorAgent<CR>", { desc = "Cursor Agent: Toggle terminal" })
      vim.keymap.set("v", "<leader>zz", ":CursorAgentSelection<CR>", { desc = "Cursor Agent: Send selection" })
      vim.keymap.set("n", "<leader>zZ", ":CursorAgentBuffer<CR>", { desc = "Cursor Agent: Send buffer" })
    end,
  },
}
