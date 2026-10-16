vim.g.everforest_background = "hard"

function ColorMyPencils(color)
	color = color or "everforest"
	vim.cmd.colorscheme(color)
end

ColorMyPencils()
