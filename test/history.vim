let s:suite = themis#suite('history')
let s:assert = themis#helper('assert')

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

function! s:suite.commandline_history_forward()
    set history=5
    call histdel('/')
    call s:assert.equals(histget('search', -1), '')
    exec "normal" "/pattern\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern')
    exec "normal" "/pattern/e\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
endfunction

function! s:suite.commandline_history_backward()
    set history=5
    call histdel('/')
    call s:assert.equals(histget('search', -1), '')
    exec "normal" "?pattern\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern')
    exec "normal" "?pattern/e\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
endfunction

function! s:suite.commandline_history_stay()
    set history=5
    call histdel('/')
    call s:assert.equals(histget('search', -1), '')
    exec "normal" "g/pattern\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern')
    exec "normal" "g/pattern/e\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
    exec "normal" "g/pattern/e\<Tab>\<CR>"
    call s:assert.equals(histget('search', -1), 'pattern/e')
endfunction

