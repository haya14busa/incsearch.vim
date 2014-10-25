let s:suite = themis#suite('incremental_next_prev')
let s:assert = themis#helper('assert')

" Helper:
function! s:add_line(str)
    put! =a:str
endfunction
function! s:add_lines(lines)
    for line in reverse(a:lines)
        put! =line
    endfor
endfunction
function! s:get_pos_char()
    return getline('.')[col('.')-1]
endfunction

function! s:reset_buffer()
    normal! ggdG
    call s:add_lines(copy(s:line_texts))
    normal! Gddgg0zt
endfunction

function! s:suite.before()
    map /  <Plug>(incsearch-forward)
    map ?  <Plug>(incsearch-backward)
    map g/ <Plug>(incsearch-stay)
    let s:line_texts = [
    \     '0'
    \   , 'pattern1'
    \   , 'pattern2'
    \   , 'pattern3'
    \   , 'pattern4'
    \   , 'pattern5'
    \   , '6'
    \ ]
    call s:reset_buffer()
endfunction

function! s:suite.before_each()
    :1
endfunction

function! s:suite.after()
    call s:reset_buffer()
endfunction

function! s:suite.inc_next_forward()
    call s:assert.equals(s:get_pos_char(), 0)
    exec "normal" "/pattern\\zs\\d\<Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[2])
    :1
    exec "normal" "/pattern\\zs\\d\<Tab>\<Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[3])
endfunction

function! s:suite.inc_next_backward()
    :$
    call s:assert.equals(s:get_pos_char(), 6)
    exec "normal" "?pattern\\zs\\d\<Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[4])
    :$
    exec "normal" "?pattern\\zs\\d\<Tab>\<Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[3])
endfunction

function! s:suite.inc_prev_forward()
    call s:assert.equals(s:get_pos_char(), 0)
    exec "normal" "/pattern\\zs\\d\<Tab>\<S-Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[1])
    :1
    exec "normal" "/pattern\\zs\\d\<Tab>\<Tab>\<S-Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[2])
endfunction

function! s:suite.inc_prev_backward()
    :$
    call s:assert.equals(s:get_pos_char(), 6)
    exec "normal" "?pattern\\zs\\d\<Tab>\<S-Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[5])
    :$
    exec "normal" "?pattern\\zs\\d\<Tab>\<Tab>\<S-Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[4])
endfunction

function! s:suite.inc_next_stay()
    call s:assert.equals(s:get_pos_char(), 0)
    exec "normal" "g/pattern\\zs\\d\<Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[1])
    :1
    exec "normal" "g/pattern\\zs\\d\<Tab>\<Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[2])
endfunction

function! s:suite.inc_prev_stay()
    call s:assert.equals(s:get_pos_char(), 0)
    exec "normal" "g/pattern\\zs\\d\<Tab>\<Tab>\<S-Tab>\<CR>"
    call s:assert.equals(getline('.'), s:line_texts[1])
endfunction
