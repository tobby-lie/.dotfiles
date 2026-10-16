-- No-op for parsers that are already installed
require('nvim-treesitter').install {
  "python", "javascript", "rust", "c", "lua", "vim", "vimdoc", "query", "go", "terraform",
}

-- Highlighting comes from Neovim itself. start() errors for filetypes
-- without an installed parser, so those are skipped
vim.api.nvim_create_autocmd('FileType', {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
