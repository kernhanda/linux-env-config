-- commenting
return {
    "terrortylor/nvim-comment",
    name = "nvim_comment",
    config = true,
    keys = {
        { "<leader>cc", "<CMD>CommentToggle<CR>j", mode = { "n" } },
        { "<leader>cc", ":'<,'>CommentToggle<CR>gv<esc>j", mode = { "v" } },
    },
}
