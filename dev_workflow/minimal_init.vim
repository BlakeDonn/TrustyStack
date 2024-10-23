set nolist
set nonumber
set norelativenumber
set cursorline
set nowrap
set noswapfile
set nobackup
set noundofile
set nohlsearch
set scrolloff=0
set sidescrolloff=0
set signcolumn=no
set colorcolumn=
set background=dark
set termguicolors
syntax off
filetype off

" Disable auto commenting
autocmd BufRead,BufNewFile *.txt setlocal formatoptions-=c formatoptions-=r formatoptions-=o
