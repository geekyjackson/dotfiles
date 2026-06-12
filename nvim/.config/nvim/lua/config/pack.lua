-- vim-slime reads global variables, so set these before loading plugins.
require("plugins.slime")

vim.pack.add({
  "https://github.com/ellisonleao/gruvbox.nvim",
  "https://github.com/jpalardy/vim-slime",
  "https://github.com/neovim/nvim-lspconfig",
  "https://github.com/folke/which-key.nvim",
}, {
  load = true,
})

require("plugins.gruvbox")
require("plugins.which-key")
