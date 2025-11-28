return {
	"andythigpen/nvim-coverage",
	version = "*",
	config = function()
		local coverage = require("coverage")

		coverage.setup({
			auto_reload = true,
			commands = true,
		})

		-- Toggle coverage
		local coverage_visible = false

		vim.keymap.set("n", "<leader>cs", function()
			if not coverage_visible then
				coverage.load(true)
				coverage_visible = true
			else
				coverage.hide()
				coverage_visible = false
			end
		end, { desc = "Coverage: Debug Load" })
	end,
}
