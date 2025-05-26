return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"folke/snacks.nvim",
		"nvim-neotest/neotest-jest", -- JavaScript/TypeScript
	},
	config = function()
		require("neotest").setup({
			adapters = {
				require("neotest-jest")({
					jestCommand = "npx jest",
					jestConfigFile = "jest.config.ts",
					jest_test_discovery = true,
				}),
			},
		})
	end,

	cmd = { "NeotestRun", "NeotestSummary" },
	keys = {
		{
			"<leader>tt",
			function()
				require("neotest").run.run({
					command = vim.fn.expand("%"),
					jestCommand = "npx jest",
				})
			end,
			desc = "Neotest: Run unit test suite",
		},
		{
			"<leader>tT",
			function()
				require("neotest").run.run({
					command = vim.fn.expand("%"),
					jestCommand = "npx dotenv -e .env.test.local npx jest",
					jestConfigFile = "jest.e2e.config.ts",
				})
			end,
			desc = "Neotest: Run local E2E test suite",
		},
		{
			"<leader>to",
			function()
				require("neotest").output.open()
			end,
			desc = "Neotest: Open output panel",
		},
		{
			"<leader>tS",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Neotest: Toggle test summary",
		},
	},
}

-- vim.keymap.set("n", "<leader>tP", function()
-- 	local items = {
-- 		{
-- 			text = "Run Nearest",
-- 			action = function()
-- 				require("neotest").run.run()
-- 			end,
-- 		},
-- 		{
-- 			text = "Run File",
-- 			action = function()
-- 				require("neotest").run.run(vim.fn.expand("%"))
-- 			end,
-- 		},
-- 		{
-- 			text = "Run Suite",
-- 			action = function()
-- 				require("neotest").run.run({ suite = true })
-- 			end,
-- 		},
-- 		-- { text = "Show Last Output", action = require("neotest").output.open },
-- 		{ text = "Rerun Last", action = require("neotest").run.run_last },
-- 		{ text = "Toggle Summary", action = require("neotest").summary.toggle },
-- 	}
-- 	require("snacks").picker({
-- 		title = "⏱ Neotest Commands",
-- 		items = items,
-- 		-- confirm must invoke the action:
-- 		confirm = function(picker, item)
-- 			picker:close()
-- 			if type(item.action) == "function" then
-- 				item.action()
-- 			end
-- 		end,
-- 	})
-- end, { desc = "Snacks: Neotest Command Palette" })
