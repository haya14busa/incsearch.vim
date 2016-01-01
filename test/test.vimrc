" This vimrc is for manual test, is not relavant with themis
" $ vim -N -u test/test.vimrc

set nocompatible
let s:path = expand("<sfile>:h:h")
set runtimepath&
let &runtimepath .= ',' . s:path

map /  <Plug>(incsearch-/)
map ?  <Plug>(incsearch-?)
map g/ <Plug>(incsearch-stay-/)
map g? <Plug>(incsearch-stay-?)
