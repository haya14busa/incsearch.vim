let s:suite = themis#suite('jumplist')
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

function! s:suite.forward()
    normal! ggdG
    call s:add_lines(['1pattern', '2pattern', '3pattern', '4pattern'])
    normal! gg0
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "/2pattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal" "/3pattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '3')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "/4pattern/e\<CR>"
    call s:assert.equals(s:get_pos_char(), 'n')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '1')
endfunction

function! s:suite.backward()
    normal! ggdG
    call s:add_lines(['1pattern', '2pattern', '3pattern', '4pattern'])
    normal! Gdd0
    call s:assert.equals(s:get_pos_char(), '4')
    exec "normal" "?3pattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '3')
    exec "normal" "?2pattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '3')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '4')
endfunction

function! s:suite.stay_does_not_update_jumplist()
    normal! ggdG
    call s:add_lines(['1pattern', '2pattern', '3pattern', '4pattern'])
    normal! Gddgg0
    normal! m`
    call s:assert.equals(s:get_pos_char(), '1')
    keepjumps normal! 3j
    call s:assert.equals(s:get_pos_char(), '4')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '1')
    normal! m`
    keepjumps normal! j
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal" "g/3pattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '1')
endfunction

function! s:suite.stay_offset()
    call s:assert.skip("because you cannot set {offset} infor with Vim script unless excuting search command")
    normal! ggdG
    call s:add_lines(['1pattern', '2pattern', '3pattern', '4pattern'])
    normal! Gddgg0
    call s:assert.equals(s:get_pos_char(), '1')
    normal! m`
    keepjumps normal! j
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal" "g/3pattern/e\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '1') " -> 2
endfunction

function! s:suite.exit_stay_does_update_jumplist()
    normal! ggdG
    call s:add_lines(['1pattern', '2pattern', '3pattern', '4pattern'])
    normal! Gddgg0
    normal! m`
    call s:assert.equals(s:get_pos_char(), '1')
    keepjumps normal! 3j
    call s:assert.equals(s:get_pos_char(), '4')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '1')
    normal! m`
    keepjumps normal! j
    call s:assert.equals(s:get_pos_char(), '2')
    exec "normal" "g/3pattern\<Tab>\<CR>"
    call s:assert.equals(s:get_pos_char(), '3')
    exec "normal! \<C-o>"
    call s:assert.equals(s:get_pos_char(), '2')
endfunction
