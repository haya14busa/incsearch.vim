let s:suite = themis#suite('operator_pending_behavior')
let s:assert = themis#helper('assert')

" NOTE: Also see repetition.vim spec
" :h o_v
" :h o_V
" :h o_CTRL-V

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

function! s:suite.force_exclusive()
    call s:assert.skip("because it seems vim has no variables to restore o_v, o_V, and o_Ctrl-V information")
    " dv/pattern
    call s:add_line('1pattern 2pattern 3pattern 4pattern 5pattern')
    normal! gg0
    call s:assert.equals(getline('.'), '1pattern 2pattern 3pattern 4pattern 5pattern')
    exec "normal" "dv/\\dpattern\<CR>"
    call s:assert.equals(getline('.'), 'pattern 3pattern 4pattern 5pattern')
endfunction

" TODO:
