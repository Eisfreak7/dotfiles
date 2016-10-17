" vim: nowrap foldmethod=marker foldlevel=2
" Plugins {{{1

" Vim-Plug Boilderplate {{{3
" Automatically install vim-plug if it isn't installed
if has('nvim')
	let g:vimdir = $HOME . '/.config/nvim'
	let g:spelldir = $HOME . '/.local/share/nvim/site/spell'
else
	let g:vimdir = $HOME . '/.vim'
	let g:spelldir = g:vimdir . '/spell'
endif

if empty(glob(vimdir.'/autoload/plug.vim'))
	execute "!curl -fLo " . shellescape(vimdir . "/autoload/plug.vim") . " --create-dirs " .
	      \ "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
	autocmd VimEnter * PlugInstall | source $MYVIMRC
endif

" Installed Plugins {{{2
" Filetypes {{{3
call plug#begin(vimdir.'/plugged')
Plug 'vim-pandoc/vim-pandoc'                              " Pandoc
Plug 'vim-pandoc/vim-pandoc-syntax'                       " Pandoc syntax
Plug 'lervag/vimtex'                                      " Latex support
Plug 'artur-shaik/vim-javacomplete2', { 'for': 'java' }    " Java
Plug 'dogrover/vim-pentadactyl', { 'for': 'pentadactyl' } " Pentadactyl
Plug 'rust-lang/rust.vim', { 'for': 'rust' }              " Rust
if executable('cargo')
	Plug 'racer-rust/vim-racer', { 'for': 'rust' }         " Rust Auto-Complete-er
endif
" Colorschemes {{{3
Plug 'morhetz/gruvbox'                                    " Gruvbox
Plug 'chriskempson/base16-vim'                            " Base16
Plug 'fcpg/vim-fahrenheit'
" Appearance {{{3
Plug 'junegunn/rainbow_parentheses.vim'                   " Color matching parentheses
" Misc {{{3
Plug 'godlygeek/csapprox'                                 " Make colorschemes work in terminal
if executable('zeal')
	Plug 'KabbAmine/zeavim.vim'                           " Offline documentation
endif
Plug 'tpope/vim-repeat'                                   " Make custom options repeatable
Plug 'tpope/vim-fugitive'                                 " Git wrapper
Plug 'tpope/vim-surround'                                 " Surrounding things
Plug 'tpope/vim-unimpaired'                               " Mappings
Plug 'tpope/vim-commentary'                               " Comment stuff out
Plug 'airblade/vim-gitgutter'                             " Show git diff in gutter
Plug 'clever-f.vim'                                       " Make F and T repeatable
Plug 'easymotion/vim-easymotion'                          " Highlight possible targets
if has('nvim')
	Plug 'Shougo/deoplete.nvim'                           " Better autocompletion
	Plug 'zchee/deoplete-jedi'                            " Python autocompletion
	Plug 'Shougo/echodoc.vim'                             " Show docstring
else
	Plug 'Valloric/YouCompleteMe', {'do': './install.sh'} " Better autocompletion
endif
Plug 'SirVer/ultisnips'                                   " Snipptes suppert
Plug 'benekastah/neomake'                                 " Linter
Plug 'bling/vim-airline'                                  " Better statusbar
Plug 'junegunn/vim-easy-align'                                 " Alignment
Plug 'vimwiki/vimwiki'                                    " Vimwiki
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'bkad/CamelCaseMotion'                               " Move in CamelCase and snake_case
if exists(':terminal')
	Plug 'kassio/neoterm'                                 " Execute commands in neovims terminal
endif
call plug#end()

" Plugin specific {{{2
" vim-ariline {{{3
let g:airline#extensions#whitespace#mixed_indent_algo = 2

" racer {{{3
let $RUST_SRC_PATH = $HOME . '/.multirust/toolchains/stable-x86_64-unknown-linux-gnu/lib/rustlib/src/rust/src'
silent execute "!mkdir -p " . shellescape($RUST_SRC_PATH)
let g:racer_cmd = '/usr/bin/racer'

" rust.vim {{{3
if executable('rustfmt')
	let g:rustfmt_autosave = 1 " Run rustfmt on save
endif

" vimtex {{{3
if has('nvim')
	let g:vimtex_latexmk_progname="nvr"
endif
let g:vimtex_view_method="zathura"
let g:vimtex_quickfix_open_on_warning=0
let latexmk_options = '-pdf -verbose -file-line-error -synctex=1 -interaction=nonstopmode'
command! LatexShellescape let g:vimtex_latexmk_options = latexmk_options . ' -shell-escape'
command! LatexShellescapeOff let g:vimtex_latexmk_options = latexmk_options

" deoplete
let g:deoplete#enable_at_startup = 1
let g:deoplete#enable_ignore_case = 1
let g:deoplete#enable_smart_case = 1
let g:deoplete#enable_camel_case = 1
let g:deoplete#enable_refresh_always = 1
let g:deoplete#enable_fuzzy_completion = 1
let g:deoplete#omni#input_patterns = get(g:,'deoplete#omni#input_patterns',{})
let g:deoplete#omni#input_patterns.java = ['[^. \t0-9]\.\w*',
                                          \'[^. \t0-9]\->\w*',
                                          \'[^. \t0-9]\::\w*',
                                          \]
" Dont auto-import everything I type
let g:deoplete#ignore_sources = {}
let g:deoplete#ignore_sources._ = ['javacomplete2']

" Hide preview window after completion
augroup deoplete_preview
	autocmd!
	autocmd CompleteDone * pclose!
augroup END

" deoplete-jedi {{{3
let g:deoplete#sources#jedi#show_docstring = 1

" vim-racer {{{3
augroup racer-bindings
	autocmd!
	autocmd Filetype rust nmap <buffer> gD <Plug>RacerShowDocumentation
augroup END

" echodoc {{{3
let g:echodoc_enable_at_startup = 1

" java {{{3
let g:JavaComplete_EnableDefaultMappings = 0
augroup java
	autocmd!
	autocmd FileType java setlocal omnifunc=javacomplete#Complete
	" javac defaults to printing its errors to stderr
	autocmd FileType java setlocal shellpipe=2>
	autocmd FileType java setlocal makeprg=javac\ %
	autocmd FileType java setlocal errorformat=%A:%f:%l:\ %m,%-Z%p^,%-C%.%#
	autocmd FileType java nnoremap <buffer> <Leader>ji :silent! call javacomplete#imports#AddMissing()\|call javacomplete#imports#RemoveUnused()<CR>
augroup END

" neoterm {{{3
let g:neoterm_size = 15
let g:neoterm_keep_term_open = 1
let g:run_tests_bg = 1
let g:raise_when_tests_fail = 1
set statusline+=%#NeotermTestRunning#%{neoterm#test#status('running')}%*
set statusline+=%#NeotermTestSuccess#%{neoterm#test#status('success')}%*
set statusline+=%#NeotermTestFailed#%{neoterm#test#status('failed')}%*

" surround {{{3
" surround with latex command
let g:surround_{char2nr('c')} = "\\\1command\1{\r}"

" Neomake {{{3
augroup neomake_plugin
	autocmd!
	if has('nvim')
		autocmd! BufWritePost * Neomake
		autocmd! BufWritePost *.rs Neomake! clippy
	endif
augroup END
let g:neomake_python_enabled_makers = ['python', 'pyflakes', 'pylint']
let g:neomake_tex_enabled_makers = ['chktex'] " no lacheck
let g:neomake_sty_enabled_makers = ['chktex'] " no lacheck
" Disabled warnings:
" - command terminated with space (1) (I *want* to terminate some commands with space)
" - wrong length of dash (8) (may or may not be right)
" - should use \cdots to achieve an ellipsis (11) (I want to decide myself)
" - interword spacing (12) (may or may not be right)
" - intersentence spacing (13) (may or may not be right)
" - mathmode on at end (16) (doesn't work)
" - no ''' (23) (I use ' as a variable differentiator, not just for quoting)
" - might want to put this between {} (25) (is confused by references with _)
" - space before punctuation (26) (i want space before :=)
" - should use space with parenthesis (36) (I don't want to use space)
" - vertical rules in tables (44) (I don't think they are _always_ ugly)
let g:neomake_tex_chktex_args = ['--nowarn=1', '--nowarn=8', '--nowarn=11', '--nowarn=12', '--nowarn=13', '--nowarn=16', '--nowarn=23', '--nowarn=25', '--nowarn=26', '--nowarn=36', '--nowarn=44']

" CamelCaseMotion {{{3
call camelcasemotion#CreateMotionMappings(',')

" Rainbow_Parentheses {{{3
let g:rainbow#pairs = [['(', ')'], ['[', ']'], ['{', '}'], ['<', '>']]

" Ultisnips {{{3
" Trigger configuration. <tab> interferes with YouCompleteMe
let g:UltiSnipsExpandTrigger="<c-j>"
let g:UltiSnipsJumpForwardTrigger="<c-j>"
let g:UltiSnipsJumpBackwardTrigger="<c-k>"
let g:UltiSnipsEditSplit="vertical"
let g:UltiSnipsSnippetsDir=vimdir . "/UltiSnips"
let g:UltiSnipsEnableSnipMate=0

" Vimwiki {{{3
let g:vimwiki_list = [{'path': '~/vimwiki/', 'syntax': 'markdown', 'ext': '.md'}]
" no default mappings please
nnoremap <silent> <leader>zw <Plug>VimwikiIndex
nnoremap <silent> <leader>zt <Plug>VimwikiTabIndex
nnoremap <silent> <leader>zs <Plug>VimwikiUISelect
nnoremap <silent> <leader>zi <Plug>VimwikiDiaryIndex

" EasyAlign {{{3
xmap ga <Plug>(EasyAlign)
nmap ga <Plug>(EasyAlign)

" fzf {{{3
" Ignore non-text filetypes / generated files
let fzf_ignores = ''
for ign in ['class', 'pdf', 'fdb_latexmk', 'aux', 'fls', 'synctex.gz', 'zip']
	let fzf_ignores = fzf_ignores . ' --ignore=''*.'.ign.''''
endfor
let $FZF_DEFAULT_COMMAND = 'ag --nocolor'.fzf_ignores.' --files-with-matches --follow --depth=-1 --hidden --search-zip -g "" 2>/dev/null'

augroup fzf
	autocmd!
	" BufEnter isn't triggered when the terminal is first opened
	autocmd TermOpen term://*fzf* tunmap <ESC><ESC>
	autocmd BufEnter term://*fzf* tunmap <ESC><ESC>
	autocmd BufLeave term://*fzf* tnoremap <silent> <ESC><ESC> <C-\><C-n>G:call search(".", "b")<CR>$
augroup END

nnoremap <silent> <leader>f :Files<CR>
nnoremap <silent> <leader>a :Buffers<CR>
nnoremap <silent> <leader>; :BLines<CR>
nnoremap <silent> <leader>. :Lines<CR>
nnoremap <silent> <leader>o :BTags<CR>
nnoremap <silent> <leader>O :Tags<CR>
nnoremap <silent> <leader>: :Commands<CR>
nnoremap <silent> <leader>? :History<CR>
nnoremap <silent> <leader>/ :execute 'Ag ' . input('Ag/')<CR>
nnoremap <silent> <leader>K :call SearchWordWithAg()<CR>
vnoremap <silent> <leader>K :call SearchVisualSelectionWithAg()<CR>
nnoremap <silent> <leader>gl :Commits<CR>
nnoremap <silent> <leader>ga :BCommits<CR>

imap <C-x><C-f> <plug>(fzf-complete-file-ag)
imap <C-x><C-l> <plug>(fzf-complete-line)

function! SearchWordWithAg()
	execute 'Ag' expand('<cword>')
endfunction

function! SearchVisualSelectionWithAg() range
	let old_reg = getreg('"')
	let old_regtype = getregtype('"')
	let old_clipboard = &clipboard
	set clipboard&
	normal! ""gvy
	let selection = getreg('"')
	call setreg('"', old_reg, old_regtype)
	let &clipboard = old_clipboard
	execute 'Ag' selection
endfunction

" General {{{1
" Settings {{{2
" Misc {{{3
filetype plugin indent on
if &compatible | set nocompatible | endif
set history=5000
set number
set relativenumber
set cursorline
set ruler
set cmdheight=2
set splitright
set splitbelow
set nofoldenable
set hidden
set autoindent
set backspace=indent,eol,start
set hlsearch
set wildignore+=*~,*.pyc,*.swp,*.class,*.pdf,*.aux,*.fdb_latexmk,*.dfls,*.toc,*.synctex.gz
set tabstop=4
set shiftwidth=4                       " Shiftwidth equals tabstop
set wrap
if has('linebreak')
	set linebreak
	set breakindent
endif
set textwidth=99
set colorcolumn=+0
set showmatch
set ignorecase
set smartcase
set directory-=.
set backupdir-=.
set nobackup
if has('nvim')
	silent execute "!mkdir -p " . &backupdir
endif
set mouse+=a
set copyindent                         " Keep spaces used for alignment
set preserveindent
" Remember undos {{{3
if has('persistent_undo')
	silent call system('mkdir -p $HOME/tmp/vim/undo')
	if !has("nvim")
		set undodir=$HOME/tmp/vim/undo
	endif
	set undolevels=100000
	set undoreload=100000
	set undofile
endif

" Prevent Vim from keeping the contents of tmp files on the system {{{3
" Don't backup files in temp directories or shm
if exists('&backupskip')
set backupskip+=/tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,*/shm/*
endif

" Don't keep swap files in temp directories or shm
if has('autocmd')
augroup swapskip
	autocmd!
	silent! autocmd BufNewFile,BufReadPre
	              \ /tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,*/shm/*
	              \ setlocal noswapfile
augroup END
endif

" Don't keep undo files in temp directories or shm
if has('persistent_undo') && has('autocmd')
augroup undoskip
	autocmd!
	silent! autocmd BufWritePre
	              \ /tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,*/shm/*
	              \ setlocal noundofile
augroup END
endif

" Don't keep viminfo for files in temp directories or shm
if has('viminfo')
if has('autocmd')
	augroup viminfoskip
		autocmd!
		silent! autocmd BufNewFile,BufReadPre
		              \ /tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,*/shm/*
		              \ setlocal viminfo=
	augroup END
endif
endif

" Helper functions {{{3
" Execute macro over visual selection {{{3
" https://github.com/stoeffel/.dotfiles/blob/master/vim/visual-at.vim
xnoremap @ :<C-u>call ExecuteMacroOverVisualRange()<CR>

function! ExecuteMacroOverVisualRange()
	echo "@".getcmdline()
	execute ":'<,'>normal @".nr2char(getchar())
endfunction

" Appearance {{{3
if has ("multi_byte_encoding")
	if !has("nvim")
		set encoding=utf-8
	endif
endif
set list
set listchars=tab:▸\ ,eol:¬,trail:␣
set background=dark
" Colorscheme (if available)
let g:gruvbox_italic = 1 " Use italic
let g:gruvbox_contrast_dark = "hard" " Hard contrast
silent! colorscheme gruvbox
let cur_colorscheme = ''
redir => cur_colorscheme
silent colorscheme
redir END
if !has("gui_running")
	if split(cur_colorscheme, "\n")[0] != 'gruvbox' || &t_Co < 88
		silent! colorscheme darkblue
	endif
endif
syntax enable
" Formating {{{3
set formatoptions-=t                   " Don't autowrap text
set formatoptions-=c                   " Don't autowrap comments
set formatoptions-=o                   " Don't insert comment-leader
let g:netrw_dirhistmax = 0 " Don't save a file history in the .vim folder

" Email-Settings {{{3
autocmd FileType mail execute 'normal G' | set formatoptions-=t

" Use ack/ag if available
if executable ('ag')
	set grepprg=ag\ --nogroup\ --nocolor
elseif executable ('ack')
	set grepprg=ack\ --nogroup\ --nocolor
endif

" Mappings {{{2
" Use space as leader {{{3
map <Space> <leader>

" Quickly use the system keyboard by saving 2 (!) keys {{{3
vmap <Leader>y "+y
vmap <Leader>d "+d
nmap <Leader>p "+p
nmap <Leader>P "+P
vmap <Leader>p "+p
vmap <Leader>P "+P

" Location List
nnoremap <silent> <Leader>e :lopen<CR>
nnoremap <silent> <Leader>E :copen<CR>
nnoremap <silent> <Leader>ln :lprevious<CR>
nnoremap <silent> <Leader>lp :lnext<CR>
nnoremap <silent> <Leader>cn :cnext<CR>
nnoremap <silent> <Leader>cp :cprevious<CR>

" search for TODO comments {{{3
nnoremap <Leader>t :silent grep TODO<CR>

" close {{{3
nnoremap <Leader>q :quit<CR>
nnoremap <Leader>Q :qall<CR>

" make C-u in insert mode undoable
inoremap <C-U> <C-G>u<C-U>

" Save {{{3
nnoremap <silent> <Leader>w :write<CR>

" Visual star search
xnoremap * :<C-u> call <SID>VSetSearch()<CR>/<C-R>=@/<CR><CR>
xnoremap # :<C-u> call <SID>VSetSearch()<CR>?<C-R>=@/<CR><CR>

function! s:VSetSearch()
	let temp = @s
	norm! gv"sy
	let @/ = '\V' . substitute(escape(@s, '/\'), '\n', '\\n', 'g')
	let @s = temp
endfunction

" Make Y consistent with other commands
nnoremap Y y$

" Command-line navigation (no arrow keys) {{{3
cnoremap <C-p> <Up>
cnoremap <C-n> <Down>
cnoremap <C-h> <Left>
cnoremap <C-j> <Down>
cnoremap <C-k> <Up>
cnoremap <C-l> <Right>
cnoremap <C-S-h> <S-Left>
cnoremap <C-S-l> <S-Right>

" Expand %% to the folder of the currently edited file {{{3
cnoremap %% <C-R>=expand('%:h').'/'<CR>

" Resize {{{3
nnoremap <silent> <Leader>- :resize -3<CR>
nnoremap <silent> <Leader>+ :resize +3<CR>
nnoremap <silent> <Leader>< :vertical resize -3<CR>
nnoremap <silent> <Leader>> :vertical resize +3<CR>

" Move through soft wraps {{{3
nnoremap j gj
nnoremap k gk
nnoremap gj j
nnoremap gk k
nnoremap 0 g^
nnoremap $ g$

" Spellchecking {{{3
nnoremap <silent> <leader>s :set spell!<CR>
nnoremap <silent> <leader>sd :set spell spelllang=de_20<CR>
nnoremap <silent> <leader>se :set spell spelllang=en_us<CR>

" search/replace the word under the cursor {{{3
nnoremap <leader>s :let @z = expand("<cword>")<cr>q:i%s/\C\v<<esc>"zpa>//g<esc>hi

" Stop highlighting the last search {{{3
nnoremap <silent> <leader>c :nohlsearch<CR>

" Navigate between split views with <CTRL>-[h/j/k/l]
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Move splits
nnoremap <C-M-h> <C-w>H
nnoremap <C-M-j> <C-w>J
nnoremap <C-M-k> <C-w>K
nnoremap <C-M-l> <C-w>L

" Alignment with tab {{{3
inoremap <S-Tab> <Space><Space><Space><Space>

" Terminal mode {{{3
if exists(':terminal')
	" Leave terminal mode and jump to the last line
	" (This mapping is removed and later restored in fzf buffers, see the fzf
	" configuration for that)
	tnoremap <silent> <ESC><ESC> <C-\><C-n>G:call search(".", "b")<CR>$
	" Navigation
	tnoremap <C-h> <C-\><C-n><C-w>h
	tnoremap <C-j> <C-\><C-n><C-w>j
	tnoremap <C-k> <C-\><C-n><C-w>k
	tnoremap <C-l> <C-\><C-n><C-w>l
	nnoremap <leader>vt :vs term://zsh<CR>i
	" Re-run last command
	tnoremap <C-r> <Up><Cr>

	augroup terminal
		autocmd!
		" Don't show listchars in terminals
		" Don't list terminals in the buffer list
		" Delete terminals when no active buffer shows them
		autocmd TermOpen * setlocal nolist nobuflisted bufhidden=delete
		" Enter insert mode when switching to a terminal
		autocmd BufEnter term://* startinsert
	augroup END
endif

" Autocommands {{{2
" Initialize (reset) autocommands {{{3
augroup vimrc
	autocmd!
augroup END

" Don't list location-list / quickfix windows {{{3
augroup nonEditableBuffers
	autocmd!
	" Don't list location-list / quickfix windows
	" (since I don't want to switch with them with :bnext & co)
	" Also, close them with q
	autocmd BufWinEnter * if &buftype == 'quickfix'
			\| setlocal nobuflisted
			\| nnoremap <silent> <buffer> q :bd<CR>
		\| endif
augroup END

" SML comments {{{3
autocmd vimrc FileType sml setlocal commentstring=(*%s*)

" Use vim help instead of man in vim files when K is pressed {{{3
autocmd vimrc FileType vim setlocal keywordprg=:help

" Continue pandoc enumerations when hitting return in insert mode {{{3
autocmd vimrc FileType pandoc call Pandocsettings()

function! Pandocsettings()
	setlocal comments +=:-
	setlocal formatoptions +=r
	setlocal colorcolumn=0
	setlocal spelllang=hun-de-DE
endfun

" Transparent editing of gpg encrypted files {{{3
" By Wouter Hanegraaff
augroup encrypted
	autocmd!
	" First make sure nothing is written to ~/.viminfo while editing
	" an encrypted file.
	autocmd BufReadPre,FileReadPre *.gpg set viminfo=
	" We don't want a various options which write unencrypted data to disk
	autocmd BufReadPre,FileReadPre *.gpg set noswapfile noundofile nobackup

	" Switch to binary mode to read the encrypted file
	autocmd BufReadPre,FileReadPre *.gpg set bin
	autocmd BufReadPre,FileReadPre *.gpg let ch_save = &ch|set ch=2
	autocmd BufReadPost,FileReadPost *.gpg '[,']!gpg --decrypt 2> /dev/null

	" Switch to normal mode for editing
	autocmd BufReadPost,FileReadPost *.gpg set nobin
	autocmd BufReadPost,FileReadPost *.gpg let &ch = ch_save|unlet ch_save
	autocmd BufReadPost,FileReadPost *.gpg execute ":doautocmd BufReadPost " . expand("%:r")

	" Convert all text to encrypted text before writing
	autocmd BufWritePre,FileWritePre *.gpg '[,']!gpg --default-recipient-self -ae 2>/dev/null
	" Undo the encryption so we are back in the normal text, directly
	" after the file has been written.
	autocmd BufWritePost,FileWritePost *.gpg u
augroup END


" Commands {{{2
" Delete buffer but keep window {{{3
command! Bd setlocal bufhidden=delete | bnext

" Automatically preview pandoc files {{{3
command! -nargs=? PanPreview call PanPreview()
function! PanPreview()
	let tmpfile=system('mktemp --suffix=.pdf')
	let tmpfile=strpart(tmpfile, 0, len(tmpfile) - 1) " Strip trailing <CR>

	let pandoccmd='pandoc --template=nicolin --to=latex ' . shellescape(expand('%:p'), 1) . ' --output ' . shellescape(tmpfile, 1)
	let readercmd='xdg-open ' . shellescape(tmpfile, 1) . ' &'
	execute 'silent !' . pandoccmd . ' && ' .readercmd

	" Reload on save
	augroup panpreview
		autocmd!
	augroup END
	execute 'autocmd panpreview BufWritePost <buffer> silent !' . pandoccmd
endfunction

" Edit a tmp file {{{3
command! -nargs=? TmpFile call TmpFile('<args>')
function! TmpFile(args)
	let args=a:args
	let tmpfile=system('mktemp --suffix=' . args)
	execute "edit ".tmpfile
endfunction

" Save as root {{{3
command! -nargs=? Swrite :w !sudo tee %
