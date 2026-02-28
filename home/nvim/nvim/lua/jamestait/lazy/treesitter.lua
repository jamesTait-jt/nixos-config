return {
	"nvim-treesitter/nvim-treesitter",
	lazy = false,
	branch = "main",
	build = ":TSUpdate",

	opts = {
		ensure_installed = {
			-- Programming & scripting
			"python",
			"go",
			"lua",
			"vim",
			"vimdoc",
			"regex",
			"bash",
			"ruby",
			"javascript",
			"typescript",
			"tsx",
			"c_sharp",
			"rust",

			-- Markup & configuration
			"yaml",
			"json",
			"toml",
			"markdown",
			"markdown_inline",
			"xml",
			"html",
			"gotmpl",

			-- Infrastructure
			"gitignore",
			"dockerfile",
			"terraform",
			"make",
			"helm",

			-- Query languages
			"query",
			"sql",

			-- Other
			"csv",
		},

		auto_install = true,

		highlight = {
			enable = true,
		},

		indent = {
			enable = true,
		},
	},

	config = function(_, opts)
		-- gotmpl + helm filetype detection
		vim.filetype.add({
			extension = {
				gotmpl = "gotmpl",
				gotpl = "gotmpl",
			},
			pattern = {
				[".*/templates/.*%.tpl"] = "helm",
				[".*/templates/.*%.ya?ml"] = "helm",
				["helmfile.*%.ya?ml"] = "helm",
			},
		})

		require("nvim-treesitter").setup(opts)
	end,
}
