"NEOVIM config file

"---------------------------
" Start dein Settings.
"---------------------------
" install dein.vim
let $CACHE = expand('~/.cache')
if !isdirectory($CACHE)
  call mkdir($CACHE, 'p')
endif
if &runtimepath !~# '/dein.vim'
  let s:dein_dir = fnamemodify('dein.vim', ':p')
  if !isdirectory(s:dein_dir)
    let s:dein_dir = $CACHE .. '/dein/repos/github.com/Shougo/dein.vim'
    if !isdirectory(s:dein_dir)
      execute '!git clone https://github.com/Shougo/dein.vim' s:dein_dir
    endif
  endif
  execute 'set runtimepath^=' .. substitute(
        \ fnamemodify(s:dein_dir, ':p') , '[/\\]$', '', '')
endif

if &compatible
  set nocompatible               " Be iMproved
endif

" reset augroup
augroup MyAutoCmd
  autocmd!
augroup END


" Required:
set runtimepath+=~/.config/nvim/repos/github.com/Shougo/dein.vim


" neovim 用 python 環境指定
" let g:python_host_prog=$PYENV_ROOT.'/versions/neovim-2/bin/python'
" let g:python_host_prog=$CONDA_PREFIX_1.'/envs/neovim-2/bin/python'
" let g:python_host_prog=$HOME.'/anaconda3/envs/neovim-2/bin/python'
let g:python_host_prog='python'
" let g:python3_host_prog=$PYENV_ROOT.'/versions/neovim-3/bin/python'
" let g:python3_host_prog=$CONDA_PREFIX_1.'/envs/neovim-3/bin/python'
" let g:python3_host_prog=$HOME.'/anaconda3/envs/neovim-3/bin/python'
let g:python3_host_prog='python3'

" leader 変更 (default は \)
let mapleader = ","


" Required:
if dein#load_state('~/.config/nvim')
  " XDG base direcory compartible
  let g:dein#cache_directory = $HOME . '/.cache/dein'

  call dein#begin('~/.config/nvim')
  " プラグインリストを収めた TOML ファイル
  " 予め TOML ファイルを用意しておく
  let g:rc_dir    = expand("~/.config/nvim/")
  let s:toml      = g:rc_dir . '/dein.toml'
  let s:lazy_toml = g:rc_dir . '/dein_lazy.toml'

  " TOML を読み込み、キャッシュしておく
  call dein#load_toml('~/.config/nvim/dein.toml',     {'lazy' : 0})
  call dein#load_toml('~/.config/nvim/dein_lazy.toml', {'lazy' : 1})
  call dein#load_toml('~/.config/nvim/dein_python.toml',   {'lazy': 1})
  " call dein#load_toml('~/.config/nvim/dein_go.toml',   {'lazy': 1})
  " call dein#load_toml('~/.config/nvim/dein_cpp.toml',   {'lazy': 1})

  " Let dein manage dein
  " Required:
  call dein#add('~/.config/nvim/repos/github.com/Shougo/dein.vim')

  " Add or remove your plugins here:
  call dein#add('Shougo/neosnippet.vim')
  call dein#add('Shougo/neosnippet-snippets')

  " You can specify revision/branch/tag.
  call dein#add('Shougo/deol.nvim', { 'rev': 'a1b5108fd' })

  " Add based on https://github.com/Shougo/dein.vim/issues/11
  call dein#add('Shougo/vimproc.vim', {'build': 'make'})

  " Required:
  call dein#end()
  call dein#clear_state()
  call dein#save_state()

  " color
  colorscheme hybrid
endif

" Required:
filetype plugin indent on
syntax enable

" If you want to install not installed plugins on startup.
if dein#check_install()
  call dein#install()
endif

"---------------------------
" End dein Settings.
"---------------------------


"カーソル位置保存 (for mac)
if has("autocmd")
  augroup redhat
    " In text files, always limit the width of text to 78 characters
    autocmd BufRead *.txt set tw=78
    " When editing a file, always jump to the last cursor position
    autocmd BufReadPost *
    \ if line("'\"") > 0 && line ("'\"") <= line("$") |
    \   exe "normal! g'\"" |
    \ endif
    " always use NERDTree
    " autocmd vimenter * NERDTree
  augroup END
endif


" 色設定
set t_Co=256
" 文字コードをUFT-8に設定
set fenc=utf-8
set fileencodings=iso-2022-jp,euc-jp,sjis,utf-8
" UTF-8 でエンコード
set encoding=UTF-8
" バックアップファイルを作らない
set nobackup
" スワップファイルを作らない
set noswapfile
" 編集中のファイルが変更されたら自動で読み直す
set autoread
" バッファが編集中でもその他のファイルを開けるように
set hidden
" 入力中のコマンドをステータスに表示する
set showcmd
" クリップボードを有効に
"set clipboard=unnamed,autoselect


" 見た目系
" 行番号を表示
set number
" インデントはスマートインデント
set smartindent
" ビープ音を可視化
set visualbell
" 括弧入力時の対応する括弧を表示
set showmatch
" ステータスラインを常に表示
set laststatus=2
" コマンドラインの補完
set wildmode=list:longest
" 折り返し時に表示行単位での移動できるようにする
nnoremap j gj
nnoremap k gk


"移動系
"挿入モード中にemacsキーバインドで左右に移動
inoremap <C-b> <Left>
inoremap <C-f> <Right>

" Tab系
" 不可視文字を可視化(タブが「▸-」と表示される)
set list listchars=tab:\▸\-
" Tab文字を半角スペースにする
set expandtab
" 行頭以外のTab文字の表示幅（スペースいくつ分）
set tabstop=4
" 行頭でのTab文字の表示幅
set shiftwidth=4


" 検索系
" 検索文字列が小文字の場合は大文字小文字を区別なく検索する
set ignorecase
" 検索文字列に大文字が含まれている場合は区別して検索する
set smartcase
" 検索文字列入力時に順次対象文字列にヒットさせる
set incsearch
" 検索時に最後まで行ったら最初に戻る
set wrapscan
" 検索語をハイライト表示
set hlsearch
" ESC連打でハイライト解除
nmap <C-c><C-c> :nohlsearch<CR><Esc>


" guchio shortcuts
" 保存
nmap ,w :w<CR>
" quit
nmap ,q :q<CR>
" term insert を esc で終了
tnoremap <Esc> <C-\><C-n>


" Load all plugins now.
" Plugins need to be added to runtimepath before helptags can be generated.
packloadall
" Load all of the helptags now, after plugins have been loaded.
" All messages and errors will be ignored.
silent! helptags ALL
