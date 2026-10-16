vim.g.everforest_background = "soft"

function ColorMyPencils(color)
	color = color or "everforest"
	vim.cmd.colorscheme(color)
end

ColorMyPencils()
