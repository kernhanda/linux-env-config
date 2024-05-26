-- mason installer for debugging stuff
return {
	"jay-babu/mason-nvim-dap.nvim",
	dependencies = {
		"williamboman/mason.nvim",
		"mfussenegger/nvim-dap",
	},
	config = function()
		require("mason-nvim-dap").setup({
			automatic_setup = true,
			ensure_installed = {
				"debugpy",
				"bash",
				"codelldb",
				"python",
			},
			handlers = {},
		})
	end,
}
