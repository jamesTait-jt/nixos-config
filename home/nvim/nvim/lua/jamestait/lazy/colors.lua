return {
    {
        "sainnhe/everforest",
        version = false,
        lazy = false,
        priority = 1000,
        config = function()
            vim.g.enable_italic = true
            vim.g.everforest_transparent_background = 1
            vim.cmd.colorscheme("everforest")
        end
    }
}
