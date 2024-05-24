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
				"clangd",
				"neocmake",
				"pyright",
				"lua_ls",
				"autotools_ls",
				"markdown_oxide",
				"rust_analyzer",
				"taplo",
				"gitlab_ci_ls",
				"tsserver",
				"html",
				"cssls",
				"marksman",
				"yamlls",
			},

			mason_tool_installer.setup({
				ensure_installed = {
					"prettierd",
					"stylua",
					"isort",
					"black",
					"clang-format",
					"codespell",
				},
			}),
		})
	end,
}
