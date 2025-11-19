return {
	"stevearc/conform.nvim",

	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "ruff_format" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				nix = { "alejandra" },
				-- markdown = { "prettier" },
				sql = { "sqlfmt" },
				bash = { "beautysh" },
				go = { "gofmt" },
				rust = { "rustfmt" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
