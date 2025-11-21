return {
	{
		"sainnhe/gruvbox-material",
		enabled = true,
		priority = 1000,
		config = function()
			vim.g.gruvbox_material_transparent_background = 1
			vim.g.gruvbox_material_better_performance = 1
			vim.g.gruvbox_material_foreground = "soft"
			vim.g.gruvbox_material_background = 'soft'
			vim.g.gruvbox_material_ui_contrast = "soft"
			vim.g.gruvbox_material_float_style = "soft"
			vim.g.gruvbox_material_statusline_style = "material"
			vim.g.gruvbox_material_cursor = "auto"
			vim.g.gruvbox_material_colors_override = {
				-- possible key: https://github.com/sainnhe/gruvbox-material/blob/master/autoload/gruvbox_material.vim
				green = {'#a9b665', '100'},
				bg_green = {'#a9b665', '100'},
				-- aqua =  {'#F9BE33', '100'}
			}
			vim.cmd.colorscheme("gruvbox-material")
		end,
	},
	{ "thimc/gruber-darker.nvim" },
}
