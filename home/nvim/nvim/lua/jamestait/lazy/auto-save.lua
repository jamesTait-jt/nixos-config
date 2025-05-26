return {
	"pocco81/auto-save.nvim",
	config = function()
		require("auto-save").setup({
			-- Optional configuration
			enabled = true,
			trigger_events = { "InsertLeave" },
			write_all_buffers = false, -- Set to true if you want all open buffers saved
		})
	end,
}
