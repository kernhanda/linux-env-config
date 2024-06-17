-- commenting
return {
    "terrortylor/nvim-comment",
    name = "nvim_comment",
    config = true,
    keys = {
        { "<C-/>", "<CMD>CommentToggle<CR>j", mode = { "n" } },
        { "<C-/>", "<C-\\><C-N><CMD>CommentToggle<CR>ji", mode = { "i" } },
        { "<C-/>", ":'<,'>CommentToggle<CR>gv<esc>j", mode = { "v" } },
    },
}
