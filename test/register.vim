let s:suite = themis#suite('register')
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

function! s:suite.unnamed_register()
    call s:add_line('1pattern 2pattern 3pattern 4pattern')
    normal! gg0
    call setreg(v:register, '')
    call s:assert.equals(getreg(v:register), '')
    exec "normal" "d/\\dpattern\<CR>"
    call s:assert.equals(s:get_pos_char(), '2')
    call s:assert.equals(getreg(v:register), '1pattern ')
endfunction

function! s:suite.quote_register()
    call s:add_line('1pattern 2pattern 3pattern 4pattern')
    normal! gg0
    call setreg('a', '')
    call s:assert.equals(getreg('a'), '')
    exec "normal" "\"ad/\\dpattern\<CR>"
    call s:assert.equals(getreg('a'), '1pattern ')
endfunction
