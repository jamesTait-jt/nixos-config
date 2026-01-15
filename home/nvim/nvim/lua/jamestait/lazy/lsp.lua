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

		config = function()
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			-- lua
			vim.lsp.config.lua_ls = {
				capabilities = capabilities,
			}

			-- typescript / javascript
			vim.lsp.config.vtsls = {
				capabilities = capabilities,
			}

			-- c#
			vim.lsp.config.omnisharp = {
				capabilities = capabilities,
			}

			-- Markdown
			vim.lsp.config.harper_ls = {
				capabilities = capabilities,
				filetypes = { "markdown" },
				settings = {
					userDictPath = "~/.config/dict.txt",
				},
			}

			-- bash
			vim.lsp.config.bashls = {
				capabilities = capabilities,
			}

			-- Go
			vim.lsp.config.gopls = {
				capabilities = capabilities,
			}

			-- Rust
			vim.lsp.config.rust_analyzer = {
				capabilities = capabilities,
			}

			vim.lsp.enable({
				"lua_ls",
				"vtsls",
				"omnisharp",
				"harper_ls",
				"bashls",
				"gopls",
				"rust_analyzer",
			})
		end,
	},
	{
		"williamboman/mason-lspconfig.nvim",
		dependencies = {
			"williamboman/mason.nvim",
			"neovim/nvim-lspconfig",
		},
		opts = {
			ensure_installed = {
				"lua_ls",
				"vtsls",
				"omnisharp",
				"harper_ls",
				"bashls",
				"gopls",
				"rust_analyzer",
			},
		},
	},
}
