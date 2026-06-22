-- claudecode.nvim configuration
-- LazyVim's `extras.ai.claudecode` enables the plugin and keymaps;
-- this spec extends it with explicit opts. All values below are the
-- plugin defaults — uncomment and edit what you want to change.

return {
  "coder/claudecode.nvim",
  opts = {
    -- port_range = { min = 10000, max = 65535 },
    -- auto_start = true,
    terminal_cmd = "claude --dangerously-skip-permissions",
    -- env = {},
    -- log_level = "info",
    -- track_selection = true,
    focus_after_send = true,
    -- visual_demotion_delay_ms = 50,
    -- connection_wait_delay = 600,
    -- connection_timeout = 10000,
    -- queue_timeout = 5000,

    diff_opts = {
      -- layout = "vertical",            -- "vertical" | "horizontal"
      -- open_in_new_tab = false,
      -- keep_terminal_focus = false,
      -- hide_terminal_in_new_tab = false,
      -- on_new_file_reject = "keep_empty", -- "keep_empty" | "close_window"
    },

    terminal = {
      -- split_side = "right",           -- "left" | "right"
      -- split_width_percentage = 0.30,
      -- provider = "auto",              -- "auto" | "snacks" | "native" | table
      -- show_native_term_exit_tip = true,
      -- terminal_cmd = nil,
      -- auto_close = true,
      -- env = {},
      -- snacks_win_opts = {},
      -- cwd = nil,
      -- git_repo_cwd = false,
      -- cwd_provider = nil,
      -- provider_opts = {
      --   external_terminal_cmd = nil,  -- string with %s placeholder, or function
      -- },
    },

    -- models = {
    --   { name = "Claude Opus 4.1 (Latest)", value = "opus" },
    --   { name = "Claude Sonnet 4.5 (Latest)", value = "sonnet" },
    --   { name = "Opusplan: Claude Opus 4.1 (Latest) + Sonnet 4.5 (Latest)", value = "opusplan" },
    --   { name = "Claude Haiku 4.5 (Latest)", value = "haiku" },
    -- },
  },

  -- snacks.nvim opens the Claude terminal as a left/right split and pins it
  -- with `winfixwidth`, and only recomputes float geometry on VimResized -- so
  -- the pane keeps a fixed column count when nvim itself is resized (e.g. the
  -- tmux pane grows/shrinks). Re-apply the width fraction ourselves so the
  -- Claude split tracks the editor like every other window.
  init = function()
    local pct = 0.30 -- keep in sync with terminal.split_width_percentage
    vim.api.nvim_create_autocmd("VimResized", {
      group = vim.api.nvim_create_augroup("claudecode_resize", { clear = true }),
      desc = "Keep the Claude Code split proportional on editor resize",
      callback = function()
        local ok, term = pcall(require, "claudecode.terminal")
        if not ok then
          return
        end
        local bufnr = term.get_active_terminal_bufnr()
        if not bufnr then
          return
        end
        -- Run after snacks' own VimResized handler has settled.
        vim.schedule(function()
          for _, win in ipairs(vim.fn.win_findbuf(bufnr)) do
            if vim.api.nvim_win_is_valid(win) and vim.api.nvim_win_get_config(win).relative == "" then
              vim.api.nvim_win_call(win, function()
                vim.cmd("vertical resize " .. math.floor(vim.o.columns * pct))
              end)
            end
          end
        end)
      end,
    })
  end,
}
