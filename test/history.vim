let s:suite = themis#suite('history')
let s:assert = themis#helper('assert')

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

function! s:suite.before_each()
    set history=5
    " call histdel('search') " Segmentation fault (core dumped)
    exec "normal" "/ \<CR>"
endfunction

function! s:suite.commandline_history_forward()
    call s:assert.equals(histget('search', -1), ' ')
    silent! exec "normal" "/pattern\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern')
    silent! exec "normal" "/pattern/e\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
endfunction

function! s:suite.commandline_history_backward()
    call s:assert.equals(histget('search', -1), ' ')
    silent! exec "normal" "?pattern\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern')
    silent! exec "normal" "?pattern/e\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
endfunction

function! s:suite.commandline_history_stay()
    call s:assert.equals(histget('search', -1), ' ')
    silent! exec "normal" "g/pattern\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern')
    silent! exec "normal" "g/pattern/e\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
    silent! exec "normal" "g/pattern/e\<Tab>\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
endfunction

