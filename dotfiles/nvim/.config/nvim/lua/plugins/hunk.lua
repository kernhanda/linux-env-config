-- hunk.nvim — interactive diff editor, used as jujutsu's `ui.diff-editor`.
--
-- Two entry points:
--   1. jj spawns `nvim -c "DiffEditor $left $right $output"` for any
--      interactive diff command (diffedit/split/squash -i). Wired in
--      ~/.jjconfig.toml ([ui] diff-editor); lazy-loaded here on :DiffEditor.
--   2. <leader>gg in a jj repo opens a Snacks float running `jj diffedit`,
--      which spawns the throwaway nvim above. See lua/config/keymaps.lua.

return {
  {
    "julienvincent/hunk.nvim",
    cmd = { "DiffEditor" },
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {},
    config = function(_, opts)
      require("hunk").setup(opts)
    end,
  },
}
