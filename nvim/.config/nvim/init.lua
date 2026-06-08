-- ~/.config/nvim/init.lua

vim.cmd("filetype plugin on")
vim.cmd("syntax on")
vim.cmd("runtime macros/matchit.vim")

vim.opt.backspace = { "indent", "eol", "start" }
vim.opt.hidden = true
vim.opt.wildmenu = true
vim.opt.scrolloff = 999
vim.opt.background = "dark"
vim.opt.backupcopy = "yes"

vim.opt.incsearch = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.ruler = true
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.colorcolumn = { 80, 93, 121 }

vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.shiftwidth = 4
vim.opt.expandtab = true
vim.opt.autoindent = true

vim.opt.foldmethod = "indent"
vim.opt.foldnestmax = 1
vim.opt.foldlevel = 0

if vim.env.COLORTERM == "truecolor" then
  vim.opt.termguicolors = true
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufFilePre", "BufRead" }, {
  pattern = "*.md",
  command = "setfiletype markdown",
})

vim.api.nvim_create_autocmd("VimEnter", {
  pattern = "*",
  command = "hi Normal guibg=NONE ctermbg=NONE",
})

-- Bootstrap vim-plug
local data_dir = vim.fn.stdpath("data") .. "/site"
local plug_path = data_dir .. "/autoload/plug.vim"

if vim.fn.empty(vim.fn.glob(plug_path)) > 0 then
  vim.fn.system({
    "curl",
    "-fLo",
    plug_path,
    "--create-dirs",
    "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim",
  })

  vim.api.nvim_create_autocmd("VimEnter", {
    pattern = "*",
    command = "PlugInstall --sync | source $MYVIMRC",
  })
end

vim.cmd([[
call plug#begin()
    Plug 'neovim/nvim-lspconfig'
    Plug 'JuliaEditorSupport/julia-vim'
    Plug 'morhetz/gruvbox'
    Plug 'jasonccox/vim-wayland-clipboard'
    Plug 'jpalardy/vim-slime'
call plug#end()
]])

vim.lsp.enable("julials")
vim.g.julia_indent_align_brackets = 0
vim.g.slime_target = "kitty"
vim.g.slime_bracketed_paste = 1

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(event)
    vim.keymap.set("n", "K", vim.lsp.buf.hover, {
      buffer = event.buf,
      desc = "LSP hover",
    })
  end,
})

pcall(vim.cmd.colorscheme, "gruvbox")
