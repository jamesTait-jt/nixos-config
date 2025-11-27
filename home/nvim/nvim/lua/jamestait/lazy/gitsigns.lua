return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = function()
		return {
			signs = {
				add = { text = "┃", hl = "GitSignsAdd", numhl = "GitSignsAddNr" },
				change = { text = "┃", hl = "GitSignsChange", numhl = "GitSignsChangeNr" },
				delete = { text = "▁", hl = "GitSignsDelete", numhl = "GitSignsDeleteNr" },
				topdelete = { text = "▔", hl = "GitSignsDelete", numhl = "GitSignsDeleteNr" },
				changedelete = { text = "┇", hl = "GitSignsChange", numhl = "GitSignsChangeNr" },
			},

			-- VS Code–style inline blame
			current_line_blame = true,
			current_line_blame_opts = {
				delay = 300,
				virt_text_pos = "eol",
			},
			current_line_blame_formatter = "<author>, <author_time:%Y-%m-%d> • <summary>",
		}
	end,
}
