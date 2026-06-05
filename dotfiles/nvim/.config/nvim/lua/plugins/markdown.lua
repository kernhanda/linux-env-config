-- Disable the markdown linter (markdownlint-cli2) pulled in by the
-- lang.markdown extra. Clears the nvim-lint markdown linters so no
-- MD0xx diagnostics fire; LSP, preview, and rendering stay intact.

return {
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {}
      opts.linters_by_ft["markdown.mdx"] = {}
    end,
  },
}
