-- autocompletion
return {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
        "hrsh7th/cmp-buffer", -- source for text in buffer
        "hrsh7th/cmp-path", -- source for file system paths
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-cmdline",
        "saadparwaiz1/cmp_luasnip", -- for autocompletion
        "L3MON4D3/LuaSnip",
        "rafamadriz/friendly-snippets", -- useful snippets
        "onsails/lspkind.nvim", -- vs-code like pictograms
    },
    config = function()
        local cmp = require("cmp")

        local luasnip = require("luasnip")

        local lspkind = require("lspkind")

        -- loads vscode style snippets from installed plugins (e.g. friendly-snippets)
        require("luasnip.loaders.from_vscode").lazy_load()

        cmp.setup({
            mapping = {
                ["<CR>"] = cmp.mapping.confirm({ select = false }),
                ["<Up>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
                ["<Down>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
                ["<Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_next_item()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
                ["<S-Tab>"] = cmp.mapping(function(fallback)
                    if cmp.visible() then
                        cmp.select_prev_item()
                    else
                        fallback()
                    end
                end, { "i", "s" }),
            },
            snippet = { -- configure how nvim-cmp interacts with snippet engine
                expand = function(args)
                    luasnip.lsp_expand(args.body)
                end,
            },
            sources = {
                { name = "path" }, -- file system paths
                { name = "nvim_lsp" },
                { name = "buffer" }, -- text within current buffer
                { name = "luasnip" }, -- snippets
            },
            sorting = {
                comparators = {
                    cmp.config.compare.recently_used,
                    cmp.config.compare.sort_text,
                },
            },
            completion = {
                completeopt = "menu,menuone,noselect,noinsert",
            },
            window = {
                completion = { border = "single" },
                documentation = { border = "single" },
            },
            formatting = {
                expandable_indicator = true,
                fields = { "kind", "abbr", "menu" },
                format = require("lspkind").cmp_format({
                    mode = "symbol",
                    maxwidth = 50,
                    ellipsis_char = "...",
                }),
            },
        })
        cmp.setup.cmdline("/", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "buffer", keyword_length = 3 },
            },
        })
        cmp.setup.cmdline(":", {
            mapping = cmp.mapping.preset.cmdline(),
            sources = {
                { name = "path", keyword_length = 3 },
                { name = "cmdline", keyword_length = 3 },
            },
        })
    end,
}
