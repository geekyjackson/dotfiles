filetype plugin on
syntax on
runtime macros/matchit.vim

set backspace=indent,eol,start
set hidden
set wildmenu
set scrolloff=999
set background=dark
set backupcopy=yes
set incsearch ignorecase smartcase
set ruler number relativenumber colorcolumn=80,93,121
set tabstop=4 softtabstop=4 shiftwidth=4 expandtab autoindent
set foldmethod=indent foldnestmax=1 foldlevel=0

if $COLORTERM == 'truecolor'
    set termguicolors
endif

autocmd BufNewFile,BufFilePre,BufRead *.md setf markdown
autocmd VimEnter * hi Normal guibg=NONE ctermbg=NONE

let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

call plug#begin()
    Plug 'JuliaEditorSupport/julia-vim'
    Plug 'morhetz/gruvbox'
    Plug 'chrisbra/Colorizer'
    Plug 'jasonccox/vim-wayland-clipboard'
    Plug 'jpalardy/vim-slime'
call plug#end()

let g:julia_indent_align_brackets = 0
let g:colorizer_auto_filetype='css,html,conf,json,jsonc,theme,kitty'
let g:slime_target = "kitty"
let g:slime_bracketed_paste = 1

colorscheme gruvbox
