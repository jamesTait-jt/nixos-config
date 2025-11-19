return {
	{
		"Hoffs/omnisharp-extended-lsp.nvim",
	},
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
			-- lspconfig["csharp_ls"].setup({ capabilities = capabilities })
			lspconfig["omnisharp"].setup({ capabilities = capabilities })

			-- Markdown
			lspconfig["harper_ls"].setup({
				capabilities = capabilities,
				filetypes = { "markdown" },
				settings = {
					userDictPath = "~/.config/dict.txt",
				},
			})

			-- SQL
			-- lspconfig["sqlls"].setup({ capabilities = capabilities })

			-- bash
			lspconfig["bashls"].setup({ capabilities = capabilities })

			-- Go
			lspconfig["gopls"].setup({ capabilities = capabilities })

			-- Rust
			lspconfig["rust_analyzer"].setup({ capabilities = capabilities })
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
				ensure_installed = {
					"lua_ls",
					"vtsls",
					"omnisharp",
					"harper_ls",
					"bashls",
					"gopls",
					"rust_analyzer",
				},
				handlers = {
					function(server)
						require("lspconfig")[server].setup({})
					end,
				},
			})
		end,
	},
}
