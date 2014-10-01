let s:suite = themis#suite('visual_behaviors')
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

function! s:suite.before_each()
    normal! ggdG
    call s:add_lines([
    \   '1pattern 2pattern'
    \ , '3pattern 4pattern'
    \ ])
    normal! Gdd
    normal! gg0zt
endfunction

function! s:suite.forward()
    call setreg(v:register, '')
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "v/2pattern\<CR>y"
    call s:assert.equals(getreg(), "1pattern 2")
    normal! gg0
    exec "normal" "V/2pattern\<CR>y"
    call s:assert.equals(getreg(), "1pattern 2pattern\n")
    normal! gg0
    exec "normal" "\<C-v>/4pattern\<CR>y"
    call s:assert.equals(getreg(), "1pattern 2\n3pattern 4")
    normal! gg0
    exec "normal" "v/2pattern/e\<CR>" | normal! y
    call s:assert.equals(getreg(), "1pattern 2pattern")
endfunction

function! s:suite.backward()
    normal! G$
    call setreg(v:register, '')
    exec "normal" "v?3pattern?e\<CR>" | normal! y
    call s:assert.equals(getreg(), 'n 4pattern')
    normal! G$
    exec "normal" "V?3pattern?e\<CR>" | normal! y
    call s:assert.equals(getreg(), "3pattern 4pattern\n")
    normal! G$
    exec "normal" "\<C-v>?2pattern\<CR>y"
    call s:assert.equals(getreg(), "2pattern\n4pattern")
endfunction

function! s:suite.stay()
    call setreg(v:register, '')
    call s:assert.equals(getreg(), '')
    call s:assert.equals(s:get_pos_char(), '1')
    exec "normal" "vg/2pattern\<CR>" | normal! y
    call s:assert.equals(getreg(), '1')
    normal! gg0
    exec "normal" "vg/2pattern\<Tab>\<CR>y"
    call s:assert.equals(getreg(), '1pattern 2')
    normal! gg0
    exec "normal" "veg/3pattern\<CR>" | normal! y
    call s:assert.equals(getreg(), '1pattern')
    normal! gg0
    exec "normal" "Vg/2pattern\<CR>" | normal! y
    call s:assert.equals(getreg(), "1pattern 2pattern\n")
    normal! gg0
    exec "normal" "\<C-v>g/3pattern/e\<Tab>\<CR>" | normal! y
    call s:assert.equals(getreg(), "1pattern\n3pattern")
endfunction
