require("jamestait.set")
require("jamestait.remap")
require("jamestait.lazy_init")

local augroup = vim.api.nvim_create_augroup
local JamesGroup = augroup("James", {})

local autocmd = vim.api.nvim_create_autocmd
local yank_group = augroup("HighlightYank", {})

function R(name)
	require("plenary.reload").reload_module(name)
end

autocmd("TextYankPost", {
	group = yank_group,
	pattern = "*",
	callback = function()
		vim.highlight.on_yank({
			higroup = "IncSearch",
			timeout = 200,
		})
	end,
})

autocmd({ "BufWritePre" }, {
	group = JamesGroup,
	pattern = "*",
	command = "%s/\\s\\+$//e",
})

autocmd("BufLeave", {
	group = JamesGroup,
	pattern = "*",
	callback = function()
		if vim.bo.modifiable and vim.bo.modified then
			vim.cmd("silent! write")
		end
	end,
})

require("lualine").setup({
	options = {
		theme = "everforest",
	},
})
