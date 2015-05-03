"=============================================================================
" FILE: autoload/incsearch/cli.vim
" AUTHOR: haya14busa
" License: MIT license
"=============================================================================
scriptencoding utf-8
let s:save_cpo = &cpo
set cpo&vim

let s:V = incsearch#vital()

function! incsearch#cli#get() abort
  try
    " It returns current cli object
    return s:Doautocmd.get_cmdline()
  catch /vital-over(_incsearch) Exception/
    " If there are no current cli object, return default one
    return s:cli
  endtry
endfunction

function! incsearch#cli#make(config) abort
  let cli = s:copy_cli(s:cli)
  let cli._base_key = a:config.command
  let cli._vcount1 = a:config.count1
  let cli._is_expr = a:config.is_expr
  let cli._mode = a:config.mode
  let cli._pattern = a:config.pattern
  for module in a:config.modules
    call cli.connect(module)
  endfor
  return cli
endfunction

"" partial deepcopy() for cli.connect(module) instead of copy()
function! s:copy_cli(cli) abort
  let cli = copy(a:cli)
  let cli.variables = deepcopy(a:cli.variables)
  return cli
endfunction

let s:cli = s:V.import('Over.Commandline').make_default("/")
let s:modules = s:V.import('Over.Commandline.Modules')

" Add modules
call s:cli.connect('BufferComplete')
call s:cli.connect('Cancel')
call s:cli.connect('CursorMove')
call s:cli.connect('Digraphs')
call s:cli.connect('Delete')
call s:cli.connect('DrawCommandline')
call s:cli.connect('ExceptionExit')
call s:cli.connect('LiteralInsert')
call s:cli.connect('AsyncUpdate')
" call s:cli.connect('Exit')
call s:cli.connect(incsearch#over#modules#exit#make())
call s:cli.connect('InsertRegister')
call s:cli.connect('Paste')
let s:Doautocmd = s:modules.get('Doautocmd')
call s:cli.connect(s:Doautocmd.make('IncSearch'))
call s:cli.connect(s:modules.get('ExceptionMessage').make('incsearch.vim: ', 'echom'))
call s:cli.connect(s:modules.get('History').make('/'))
call s:cli.connect(s:modules.get('NoInsert').make_special_chars())

" Dynamic Module Loading Management
let s:KeyMapping = s:modules.get('KeyMapping')
let s:emacs_like = s:KeyMapping.make_emacs()
let s:vim_cmap = s:KeyMapping.make_vim_cmdline_mapping()
let s:smartbackword = s:modules.get('IgnoreRegexpBackwardWord').make()
function! s:emacs_like._condition() abort
  return g:incsearch#emacs_like_keymap
endfunction
function! s:vim_cmap._condition() abort
  return g:incsearch#vim_cmdline_keymap
endfunction
function! s:smartbackword._condition() abort
  return g:incsearch#smart_backward_word
endfunction
call s:cli.connect(incsearch#over#modules#module_management#make([s:emacs_like, s:vim_cmap, s:smartbackword]))
unlet s:KeyMapping s:emacs_like s:vim_cmap s:smartbackword

call s:cli.connect(incsearch#over#modules#pattern_saver#make())
call s:cli.connect(incsearch#over#modules#incsearch#make())

let s:default_keymappings = {
\   "\<Tab>"   : {
\       "key" : "<Over>(incsearch-next)",
\       "noremap" : 1,
\   },
\   "\<S-Tab>"   : {
\       "key" : "<Over>(incsearch-prev)",
\       "noremap" : 1,
\   },
\   "\<C-j>"   : {
\       "key" : "<Over>(incsearch-scroll-f)",
\       "noremap" : 1,
\   },
\   "\<C-k>"   : {
\       "key" : "<Over>(incsearch-scroll-b)",
\       "noremap" : 1,
\   },
\   "\<C-l>"   : {
\       "key" : "<Over>(buffer-complete)",
\       "noremap" : 1,
\   },
\   "\<CR>"   : {
\       "key": "\<CR>",
\       "noremap": 1
\   },
\ }

" https://github.com/haya14busa/incsearch.vim/issues/35
if has('mac')
  call extend(s:default_keymappings, {
  \   '"+gP'   : {
  \       'key': "\<C-r>+",
  \       'noremap': 1
  \   },
  \ })
endif

" FIXME: arguments?
function! s:cli.keymapping(...) abort
  return extend(copy(s:default_keymappings), g:incsearch_cli_key_mappings)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" __END__
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
