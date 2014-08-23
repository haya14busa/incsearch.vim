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

function! s:suite.is_duplicate_helptags()
    helptags ./doc
endfunction

