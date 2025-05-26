return {
	{
		"williamboman/mason.nvim",
		build = ":MasonUpdate",
		config = true,
	},
	{
		"neovim/nvim-lspconfig",
		dependencies = { "saghen/blink.cmp" },

		-- example using `opts` for defining servers
		opts = {
			servers = {
				lua_ls = {},
			},
		},
		-- example calling setup directly for each LSP
		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")

			-- lua
			lspconfig["lua_ls"].setup({ capabilities = capabilities })

			-- typescript / javascript
			lspconfig["vtsls"].setup({ capabilities = capabilities })

			-- c#
			lspconfig["csharp_ls"].setup({ capabilities = capabilities })

			-- Markdown
			lspconfig["harper_ls"].setup({
				capabilities = capabilities,
				filetypes = { "markdown" },
				settings = {
					userDictPath = "~/.config/dict.txt",
				},
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},

		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = { "lua_ls", "vtsls", "csharp_ls@0.6.0", "harper_ls" },
				handlers = {
					function(server)
						require("lspconfig")[server].setup({})
					end,
				},
			})
		end,
	},
}
