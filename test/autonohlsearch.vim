let s:suite = themis#suite('autonlsearch')
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

function! s:reset_buffer()
    normal! ggdG
    call s:add_lines(['1pattern_a', '2pattern_b', '3pattern_c', '4pattern_d', '5pattern_e'])
    normal! G
    call s:add_lines(range(100))
    normal! Gddgg0zt
endfunction

function! s:suite.before()
    map n  <Plug>(incsearch-nohl-n)
    map N  <Plug>(incsearch-nohl-N)
    map *  <Plug>(incsearch-nohl-*)
    map #  <Plug>(incsearch-nohl-#)
    map g* <Plug>(incsearch-nohl-g*)
    map g# <Plug>(incsearch-nohl-g#)
endfunction

function! s:suite.before_each()
    call s:reset_buffer()
    silent! autocmd! incsearch-auto-nohlsearch
    let g:incsearch#auto_nohlsearch = 1
    call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
endfunction

function! s:suite.after()
    let g:incsearch#auto_nohlsearch = 0
    unmap n
    unmap N
    unmap *
    unmap #
    unmap g*
    unmap g#
endfunction

function! s:suite.function_works()
    let g:incsearch#auto_nohlsearch = 0
    call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
    call incsearch#auto_nohlsearch(1)
    call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
    let g:incsearch#auto_nohlsearch = 1
    call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
    call incsearch#auto_nohlsearch(1)
    call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 1)
endfunction

function! s:suite.work_with_search()
    for key in ['/', '?', 'g/']
        silent! autocmd! incsearch-auto-nohlsearch
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
        exec "normal" key . "pattern\<CR>"
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 1)
    endfor
endfunction

function! s:suite.work_with_search_offset()
    for key in ['/', '?', 'g/']
        silent! autocmd! incsearch-auto-nohlsearch
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
        exec "normal" key . "pattern/e\<CR>"
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 1)
    endfor
endfunction

function! s:suite.work_with_other_search_mappings()
    for key in ['n', 'N', '*', '#', 'g*', 'g#']
        silent! autocmd! incsearch-auto-nohlsearch
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
        exec "normal!" key
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 0)
        exec "normal" key
        call s:assert.equals(exists('#incsearch-auto-nohlsearch#CursorMoved'), 1)
    endfor
endfunction
