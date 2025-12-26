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
          local lspconfig = require("lspconfig")

          -- Track roots where we've already run the compile commands script
          local processed_roots = {}

          local original_on_attach = opts.on_attach

          local function run_generate_compile_commands(client)
            local root_dir = client.config.root_dir
            if not root_dir then
              vim.notify("No root directory found", vim.log.levels.WARN)
              return
            end

            local script_path = root_dir .. "/bazel/generate-compile-commands.sh"

            if vim.fn.filereadable(script_path) ~= 1 then
              vim.notify("Script not found: " .. script_path, vim.log.levels.WARN)
              return
            end

            vim.notify("Generating compile commands...", vim.log.levels.INFO)

            vim.fn.jobstart({ script_path }, {
              cwd = root_dir,
              on_exit = function(_, exit_code)
                if exit_code == 0 then
                  vim.schedule(function()
                    client.notify("workspace/didChangeWatchedFiles", {
                      changes = {
                        {
                          uri = vim.uri_from_fname(root_dir .. "/compile_commands.json"),
                          type = 2, -- Changed
                        },
                      },
                    })
                    vim.notify("Compile commands regenerated, clangd notified", vim.log.levels.INFO)
                  end)
                else
                  vim.schedule(function()
                    vim.notify("generate-compile-commands.sh failed (exit " .. exit_code .. ")", vim.log.levels.WARN)
                  end)
                end
              end,
            })
          end

          -- Clear processed root on client detach so LspRestart re-runs the script
          vim.api.nvim_create_autocmd("LspDetach", {
            callback = function(args)
              local client = vim.lsp.get_client_by_id(args.data.client_id)
              if client and client.name == "clangd" and client.config.root_dir then
                processed_roots[client.config.root_dir] = nil
              end
            end,
          })

          -- User command to regenerate compile commands
          vim.api.nvim_create_user_command("LspUpdate", function()
            local clients = vim.lsp.get_clients({ name = "clangd" })
            if #clients == 0 then
              vim.notify("No clangd client found", vim.log.levels.WARN)
              return
            end
            run_generate_compile_commands(clients[1])
          end, { desc = "Regenerate compile commands and notify clangd" })

          opts.on_attach = function(client, bufnr)
            if original_on_attach then
              original_on_attach(client, bufnr)
            end

            local root_dir = client.config.root_dir
            if not root_dir then
              return
            end

            -- Keymap to manually regenerate compile commands
            vim.keymap.set("n", "<leader>cc", function()
              run_generate_compile_commands(client)
            end, { buffer = bufnr, desc = "Regenerate compile commands" })

            -- Auto-run on first attach per root
            if processed_roots[root_dir] then
              return
            end

            local script_path = root_dir .. "/bazel/generate-compile-commands.sh"
            if vim.fn.filereadable(script_path) == 1 then
              processed_roots[root_dir] = true
              run_generate_compile_commands(client)
            end
          end

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
