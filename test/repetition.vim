let s:suite = themis#suite('repetition')
let s:assert = themis#helper('assert')

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

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

function! s:suite.repetition_forward()
    call s:add_line('1pattern 2pattern 3pattern 4pattern')
    normal! gg0
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "d/\\dpattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    normal! .
    call s:assert.equals(s:get_pos_char(), '3')
    normal! .
    call s:assert.equals(s:get_pos_char(), '4')
endfunction

function! s:suite.repetition_backward()
    call s:add_line('pattern4 pattern3 pattern2 pattern1')
    normal! gg$
    call s:assert.equals(getline('.'), 'pattern4 pattern3 pattern2 pattern1')
    exec "normal" "d?pattern\<CR>"
    call s:assert.equals(getline('.'), 'pattern4 pattern3 pattern2 1')
    normal! .
    call s:assert.equals(getline('.'), 'pattern4 pattern3 1')
    normal! .
    call s:assert.equals(getline('.'), 'pattern4 1')
    normal! .
    call s:assert.equals(getline('.'), '1')
endfunction

function! s:suite.stay()
    call s:add_line('1pattern 2pattern 3pattern 4pattern')
    normal! gg0
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "dg/\\dpattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "dg/\\dpattern\<Tab>\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    normal! .
    call s:assert.equals(s:get_pos_char(), '3')
    normal! .
    call s:assert.equals(s:get_pos_char(), '4')
endfunction

function! s:suite.count_forward()
    call s:add_line('1pattern 2pattern 3pattern 4pattern 5pattern')
    normal! gg0
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "2d/\\dpattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '3')
    normal! .
    call s:assert.equals(s:get_pos_char(), '5')
endfunction

function! s:suite.count_backward()
    call s:add_line('pattern5 pattern4 pattern3 pattern2 pattern1')
    normal! gg$
    call s:assert.equals(getline('.'), 'pattern5 pattern4 pattern3 pattern2 pattern1')
    exec "normal" "2d?pattern\<CR>"
    call s:assert.equals(getline('.'), 'pattern5 pattern4 pattern3 1')
    normal! .
    call s:assert.equals(getline('.'), 'pattern5 1')
endfunction

