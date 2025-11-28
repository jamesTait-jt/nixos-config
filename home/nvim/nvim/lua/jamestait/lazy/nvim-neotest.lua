return {
	"nvim-neotest/neotest",
	dependencies = {
		"nvim-neotest/nvim-nio",
		"nvim-lua/plenary.nvim",
		"antoinemadec/FixCursorHold.nvim",
		"nvim-treesitter/nvim-treesitter",
		"folke/snacks.nvim",
		"andythigpen/nvim-coverage",
		"nvim-neotest/neotest-jest", -- JavaScript/TypeScript
		{
			"fredrikaverpil/neotest-golang",
			version = "*", -- Optional, but recommended; track releases
			build = function()
				vim.system({ "go", "install", "gotest.tools/gotestsum@latest" }):wait() -- Optional, but recommended
			end,
		},
	},
	opts = {
		discovery = {
			enabled = false,
			concurrent = 1,
		},
		running = {
			concurrent = true,
		},
		summary = {
			animated = true,
		},
	},
	config = function()
		local neotest = require("neotest")

		neotest.setup({
			adapters = {
				require("neotest-jest")({
					jestCommand = "npx jest",
					jestConfigFile = "jest.config.ts",
					jest_test_discovery = true,
				}),
				require("neotest-golang")({
					runner = "go",
					go_test_args = {
						"-v",
						"-race",
						"-count=1",
						"-coverprofile=" .. vim.fn.getcwd() .. "/coverage.out", -- write coverage profile
					},
				}),
			},
		})
	end,

	cmd = { "NeotestRun", "NeotestSummary" },

	keys = {
		{
			"<leader>ta",
			function()
				require("neotest").run.attach()
			end,
			desc = "Neotest: Attach to Test",
		},
		{
			"<leader>tl",
			function()
				require("neotest").run.run_last()
			end,
			desc = "Neotest: Run Last",
		},
		{
			"<leader>to",
			function()
				require("neotest").output.open({ enter = true })
			end,
			desc = "Neotest: Show Output",
		},
		{
			"<leader>tO",
			function()
				require("neotest").output_panel.toggle()
			end,
			desc = "Neotest: Toggle Output Panel",
		},
		{
			"<leader>tr",
			function()
				require("neotest").run.run()
			end,
			desc = "Neotest: Run Nearest",
		},
		{
			"<leader>ts",
			function()
				require("neotest").summary.toggle()
			end,
			desc = "Neotest: Toggle Summary",
		},
		{
			"<leader>tS",
			function()
				require("neotest").run.stop()
			end,
			desc = "Neotest: Stop Running Tests",
		},
		{
			"<leader>tt",
			function()
				require("neotest").run.run(vim.fn.expand("%"))
			end,
			desc = "Neotest: Run File",
		},
		{
			"<leader>tT",
			function()
				require("neotest").run.run(vim.loop.cwd())
			end,
			desc = "Neotest: Run All Test Files",
		},
		{
			"<leader>tw",
			function()
				require("neotest").watch.toggle(vim.fn.expand("%"))
			end,
			desc = "Neotest: Toggle Watch",
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
