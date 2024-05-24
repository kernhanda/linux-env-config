-- statusline (has two theme options, figure out which one i want to keep)
return {
	"nvim-lualine/lualine.nvim",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"meuter/lualine-so-fancy.nvim",
	},
	opts = {
		options = {
			component_separators = { left = "", right = "" },
			section_separators = { left = "", right = "" },
			globalstatus = true,
			refresh = {
				statusline = 100,
			},
		},
		sections = {
			lualine_a = {
				{ "fancy_mode" },
			},
			lualine_b = {
				{ "fancy_branch", color = { fg = "#ffffff" } },
				{ "fancy_diff" },
			},
			lualine_c = {
				{ "fancy_cwd" },
			},
			lualine_x = {
				{ "fancy_macro" },
				{ "fancy_diagnostics" },
				{ "fancy_searchcount" },
				{ "fancy_location" },
			},
			lualine_y = {
				{ "fancy_filetype", color = { fg = "#ffffff" } },
			},
			lualine_z = {
				{ "fancy_lsp_servers" },
			},
		},
	},
	-- config = function()
	-- 	local lualine = require("lualine")
	-- 	local lazy_status = require("lazy.status") -- to configure lazy pending updates count
	--
	-- 	local colors = {
	-- 		blue = "#65D1FF",
	-- 		green = "#3EFFDC",
	-- 		violet = "#FF61EF",
	-- 		yellow = "#FFDA7B",
	-- 		red = "#FF4A4A",
	-- 		fg = "#c3ccdc",
	-- 		bg = "#112638",
	-- 		inactive_bg = "#2c3043",
	-- 	}
	--
	-- local my_lualine_theme = {
	-- 	normal = {
	-- 		a = { bg = colors.blue, fg = colors.bg, gui = "bold" },
	-- 		b = { bg = colors.bg, fg = colors.fg },
	-- 		c = { bg = colors.bg, fg = colors.fg },
	-- 	},
	-- 	insert = {
	-- 		a = { bg = colors.green, fg = colors.bg, gui = "bold" },
	-- 		b = { bg = colors.bg, fg = colors.fg },
	-- 		c = { bg = colors.bg, fg = colors.fg },
	-- 	},
	-- 	visual = {
	-- 		a = { bg = colors.violet, fg = colors.bg, gui = "bold" },
	-- 		b = { bg = colors.bg, fg = colors.fg },
	-- 		c = { bg = colors.bg, fg = colors.fg },
	-- 	},
	-- 	command = {
	-- 		a = { bg = colors.yellow, fg = colors.bg, gui = "bold" },
	-- 		b = { bg = colors.bg, fg = colors.fg },
	-- 		c = { bg = colors.bg, fg = colors.fg },
	-- 	},
	-- 	replace = {
	-- 		a = { bg = colors.red, fg = colors.bg, gui = "bold" },
	-- 		b = { bg = colors.bg, fg = colors.fg },
	-- 		c = { bg = colors.bg, fg = colors.fg },
	-- 	},
	-- 	inactive = {
	-- 		a = { bg = colors.inactive_bg, fg = colors.semilightgray, gui = "bold" },
	-- 		b = { bg = colors.inactive_bg, fg = colors.semilightgray },
	-- 		c = { bg = colors.inactive_bg, fg = colors.semilightgray },
	-- 	},
	-- }
	--
	-- -- configure lualine with modified theme
	-- lualine.setup({
	-- 	options = {
	-- 		theme = my_lualine_theme,
	-- 	},
	-- 	sections = {
	-- 		lualine_x = {
	-- 			{
	-- 				lazy_status.updates,
	-- 				cond = lazy_status.has_updates,
	-- 				color = { fg = "#ff9e64" },
	-- 			},
	-- 			{ "encoding" },
	-- 			{ "fileformat" },
	-- 			{ "filetype" },
	-- 		},
	-- 	},
	-- })
	-- end,
}
