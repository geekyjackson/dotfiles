-- vim.opt.clipboard = "unnamedplus"
vim.loader.enable()

vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.hidden = true
vim.opt.wildmenu = true
vim.opt.background = "dark"
vim.opt.backupcopy = "yes"

vim.opt.scrolloff = 999
-- vim.opt.scrolloffpad = 1

-- vim.opt.hlsearch = false
vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.ruler = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = { 80, 93, 121 }
vim.opt.signcolumn = "yes"

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.foldmethod = "indent"
vim.opt.foldnestmax = 1
vim.opt.foldlevel = 0

vim.opt.background = "dark"
vim.opt.termguicolors = vim.env.COLORTERM == "truecolor" or vim.env.COLORTERM == "24bit"
