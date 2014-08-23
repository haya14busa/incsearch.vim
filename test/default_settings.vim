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
endfunction

function! s:suite.mappings()
    call s:assert.equals(maparg('<Plug>(incsearch-forward)', 'nvo'), 'incsearch#forward()')
    call s:assert.equals(maparg('<Plug>(incsearch-backward)', 'nvo'), 'incsearch#backward()')
    call s:assert.equals(maparg('<Plug>(incsearch-stay)', 'nvo'), 'incsearch#stay()')
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
    call s:assert.exists('*incsearch#convert_with_case')
endfunction

function! s:suite.is_duplicate_helptags()
    helptags ./doc
endfunction
