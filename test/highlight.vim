let s:suite = themis#suite('highlight')
let s:assert = themis#helper('assert')

map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)

" Helper:
function! AddLine(str)
    put! =a:str
endfunction
function! AddLines(lines)
    for line in reverse(a:lines)
        put! =line
    endfor
endfunction

function! s:suite.hlsearch()
    call AddLines(['pattern1 pattern2 pattern3',
                \  'pattern4 pattern5 pattern6'])
    " FIXME:
    for keyseq in ['/', '?', 'g/']
        nohlsearch
        call s:assert.equals(v:hlsearch, 0)
        exec "normal" keyseq . "pattern\<CR>"
        call s:assert.equals(v:hlsearch, 1)
    endfor
    nohlsearch
    call s:assert.equals(v:hlsearch, 0)
    exec "normal!" "hl" | " dummy
    call s:assert.equals(v:hlsearch, 0)
endfunction
