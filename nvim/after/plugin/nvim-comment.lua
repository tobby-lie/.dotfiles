-- Setup nvim-comment
require('nvim_comment').setup()

-- Set commentstring for Terraform files
vim.api.nvim_create_autocmd("FileType", {
  pattern = "terraform",
  callback = function()
    vim.bo.commentstring = "# %s"
  end,
})
