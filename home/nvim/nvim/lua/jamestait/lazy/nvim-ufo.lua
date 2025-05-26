return {
    "kevinhwang91/nvim-ufo",
    dependencies = { "kevinhwang91/promise-async", "nvim-treesitter/nvim-treesitter" },
    init = function()
        vim.o.foldcolumn = "1"
        vim.o.foldlevel = 99
        vim.o.foldlevelstart = 99
        vim.o.foldenable = true
    end,
    config = function()
        require("ufo").setup {
            provider_selector = function(_, _, _)
                return { "treesitter", "indent" }
            end,
        }
    end,
    event = "BufReadPost",
}
