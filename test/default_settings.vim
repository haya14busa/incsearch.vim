let s:suite = themis#suite('default_settings')
let s:assert = themis#helper('assert')

function! s:suite.loaded()
  call s:assert.exists('g:loaded_incsearch')
  call s:assert.equals(g:loaded_incsearch, 1)
endfunction

function! s:suite.config()
  call s:assert.equals(g:incsearch_cli_key_mappings, {})
  call s:assert.equals(g:incsearch#emacs_like_keymap, 0)
  call s:assert.equals(g:incsearch#highlight, {})
  call s:assert.equals(g:incsearch#separate_highlight, 0)
  call s:assert.equals(g:incsearch#consistent_n_direction, 0)
  call s:assert.equals(g:incsearch#vim_cmdline_keymap, 1)
  call s:assert.equals(g:incsearch#smart_backward_word, 1)
  call s:assert.equals(g:incsearch#do_not_save_error_message_history, 0)
  call s:assert.equals(g:incsearch#auto_nohlsearch, 0)
  call s:assert.equals(g:incsearch#magic, '')
  call s:assert.equals(g:incsearch#no_inc_hlsearch, 0)
endfunction

function! s:suite.mappings()
  " Main:
  call s:assert.match(maparg('<Plug>(incsearch-forward)', 'nv'), "<SNR>\\d\\+_mode_wrap('forward')")
  call s:assert.match(maparg('<Plug>(incsearch-backward)', 'nv'), "<SNR>\\d\\+_mode_wrap('backward')")
  call s:assert.match(maparg('<Plug>(incsearch-stay)', 'nv'), "<SNR>\\d\\+_mode_wrap('stay')")
  call s:assert.equals(maparg('<Plug>(incsearch-forward)', 'o'), 'incsearch#forward_expr()')
  call s:assert.equals(maparg('<Plug>(incsearch-backward)', 'o'), 'incsearch#backward_expr()')
  call s:assert.equals(maparg('<Plug>(incsearch-stay)', 'o'), 'incsearch#stay_expr()')
  " Additional:
  call s:assert.equals(maparg('<Plug>(incsearch-nohl)', 'nvo'), 'incsearch#auto_nohlsearch(1)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl0)', 'nvo'), 'incsearch#auto_nohlsearch(0)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl-n)' , 'nvo'), '<Plug>(incsearch-nohl)<Plug>(_incsearch-n)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl-N)' , 'nvo'), '<Plug>(incsearch-nohl)<Plug>(_incsearch-N)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl-*)' , 'nvo'), '<Plug>(incsearch-nohl)<Plug>(_incsearch-*)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl-#)' , 'nvo'), '<Plug>(incsearch-nohl)<Plug>(_incsearch-#)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl-g*)', 'nvo'), '<Plug>(incsearch-nohl)<Plug>(_incsearch-g*)')
  call s:assert.equals(maparg('<Plug>(incsearch-nohl-g#)', 'nvo'), '<Plug>(incsearch-nohl)<Plug>(_incsearch-g#)')
  " Alias To The Default:
  call s:assert.equals(maparg('<Plug>(_incsearch-n)' , 'nvo'), 'n')
  call s:assert.equals(maparg('<Plug>(_incsearch-N)' , 'nvo'), 'N')
  call s:assert.equals(maparg('<Plug>(_incsearch-*)' , 'nvo'), '*')
  call s:assert.equals(maparg('<Plug>(_incsearch-#)' , 'nvo'), '#')
  call s:assert.equals(maparg('<Plug>(_incsearch-g*)', 'nvo'), 'g*')
  call s:assert.equals(maparg('<Plug>(_incsearch-g#)', 'nvo'), 'g#')
endfunction

function! s:suite.command_exist()
  augroup incsearch-themis
    autocmd!
    autocmd VimEnter call s:assert.exists('IncSearchNoreMap')
    autocmd VimEnter call s:assert.exists('IncSearchMap')
  augroup END
endfunction

function! s:suite.highlight()
  call s:assert.equals(hlexists('IncSearchMatch')        , 1)
  call s:assert.equals(hlexists('IncSearchMatchReverse') , 1)
  call s:assert.equals(hlexists('IncSearchCursor')       , 1)
  call s:assert.equals(hlexists('IncSearchOnCursor')     , 1)
  call s:assert.equals(hlexists('IncSearchUnderline')    , 1)
endfunction

function! s:suite.test_autoload_function()
  try
    " load autoload functions
    runtime autoload/*.vim
  catch
  endtry
  call s:assert.exists('*incsearch#forward')
  call s:assert.exists('*incsearch#backward')
  call s:assert.exists('*incsearch#stay')
  call s:assert.exists('*incsearch#parse_pattern')
endfunction

function! s:suite.is_duplicate_helptags()
  helptags ./doc
endfunction

" https://github.com/haya14busa/incsearch.vim/issues/69
function! s:suite.handle_keymapping_option()
  call s:assert.equals(g:incsearch_cli_key_mappings, {})
  let d = copy(incsearch#cli().keymapping())
  let g:incsearch_cli_key_mappings['a'] = 'b'
  call s:assert.equals(incsearch#cli().keymapping(), extend(copy(d), {'a': 'b'}))
  unlet g:incsearch_cli_key_mappings['a']
  call s:assert.equals(incsearch#cli().keymapping(), d)
endfunction
