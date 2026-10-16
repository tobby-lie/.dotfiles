vim.g.everforest_background = "medium"

function ColorMyPencils(color)
	color = color or "everforest"
	vim.cmd.colorscheme(color)
end

ColorMyPencils()
