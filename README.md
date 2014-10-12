incsearch.vim: Improved incremental searching
=============================================
[![Build Status](https://travis-ci.org/haya14busa/incsearch.vim.svg?branch=master)](https://travis-ci.org/haya14busa/incsearch.vim)
[![Build status](https://ci.appveyor.com/api/projects/status/ks6gtsu46c1djoo6/branch/master)](https://ci.appveyor.com/project/haya14busa/incsearch-vim/branch/master)

![](https://cloud.githubusercontent.com/assets/3797062/3866249/573444b2-1fc8-11e4-859a-7e5fb940c1bb.gif)

Introduction
------------
incsearch.vim incrementally highlight __ALL__ pattern matches unlike default
'incsearch'.

Concepts
--------

### 1. Simple
incsearch.vim provide simple improved incremental searching.

### 2. Comfortable
You can use it comfortably like default search(`/`, `?`).
It supports all mode (normal, visual, operator-pending mode), dot-repeat `.`,
`{offset}` flags, and so on.

### 3. Useful
incsearch.vim aims to be simple, but at the same time, it offers useful feature.

#### Incremental regular expression editing
You can see all matched pattern by given regular expression at all once while
incremental searching.

Usage
-----

See `:h incsearch.txt` for detail

### Basic usage
```vim
map /  <Plug>(incsearch-forward)
map ?  <Plug>(incsearch-backward)
map g/ <Plug>(incsearch-stay)
```

`<Plug>(incsearch-stay)` doesn't move the cursor.

### Additional usages

#### Automatic :nohlsearch

![](https://cloud.githubusercontent.com/assets/3797062/4518938/f3c11110-4ca6-11e4-88c6-708f510a0c3c.gif)

Farewell, `nnoremap <Esc><Esc> :<C-u>nohlsearch<CR>`!
This feature turns 'hlsearch' off automatically after searching related motions.

```vim
" :h g:incsearch#auto_nohlsearch
set hlsearch
let g:incsearch#auto_nohlsearch = 1
map n  <Plug>(incsearch-nohl-n)
map N  <Plug>(incsearch-nohl-N)
map *  <Plug>(incsearch-nohl-*)
map #  <Plug>(incsearch-nohl-#)
map g* <Plug>(incsearch-nohl-g*)
map g# <Plug>(incsearch-nohl-g#)
```

#### Consistent n and N direction
`n` and `N` directions are always forward and backward respectively even after performing `<Plug>(incsearch-backward)`.

```vim
let g:incsearch#consistent_n_direction = 1
```

#### Improved 'magic' option
- `:h 'magic'`
- `:h g:incsearch#magic`

You can set very magic option with no portability problem

```vim
let g:incsearch#magic = '\v'
```

### Command Line Interface Keymappings
incsearch.vim use custom command line interface, so it provides custom
keymapping interface(`IncSearchNoreMap`) like `cnoremap`. To use this command
in your vimrc, please call it by `VimEnter`.

```vim
augroup incsearch-keymap
    autocmd!
    autocmd VimEnter call s:incsearch_keymap()
augroup END
function! s:incsearch_keymap()
    IncSearchNoreMap <C-f> <Right>
    IncSearchNoreMap <C-b> <Left>
endfunction
```

#### Emacs-like keymappings

If you want to set emacs-like keymappings, just set `g:incsearch#emacs_like_keymap`
to 1 and basic emacs-like keymappings will be set.

```vim
let g:incsearch#emacs_like_keymap = 1
```

#### Emacs-like keymapping table

| {lhs}    | {rhs}      |
|--------- |----------- |
| `<C-f>`  | `<Right>`  |
| `<C-b>`  | `<Left>`   |
| `<C-n>`  | `<Down>`   |
| `<C-p>`  | `<Up>`     |
| `<C-a>`  | `<Home>`   |
| `<C-e>`  | `<End>`    |
| `<C-d>`  | `<Del>`    |
| `<A-d>`  | `<C-w>`    |


### Emacs-like incsearch: move the cursor while incremental searching

![](https://cloud.githubusercontent.com/assets/3797062/3866152/40e11c48-1fc4-11e4-8cfd-ace452a19f90.gif)

Move the cursor to next/previous matches while incremental searching like Emacs.

| Mapping                  | description                       |
| ------------------------ | --------------------------------- |
| `<Over>(incsearch-next)` | to next match. default: `<Tab>`   |
| `<Over>(incsearch-prev)` | to prev match. default: `<S-Tab>` |

### Scroll-like feature while incremental searching

![](https://cloud.githubusercontent.com/assets/3797062/3931538/36979326-245a-11e4-9565-bd3d91e699d5.gif)

| Mapping                      | description                                         |
| ------------------------     | ---------------------------------                   |
| `<Over>(incsearch-scroll-f)` | scroll to the next page match. default: `<C-j>`     |
| `<Over>(incsearch-scroll-b)` | scroll to the previous page match. default: `<C-k>` |


### BufferCompletion

![](https://cloud.githubusercontent.com/assets/3797062/3866279/2ce7939c-1fca-11e4-8851-d83773dff4a0.gif)

| Mapping                   | description                         |
| ------------------------- | ----------------------------------  |
| `<Over>(buffer-complete)` | buffer completion. default: `<C-l>` |


### Highlight

#### highlight group

| highlight group         | description                                                         |
| -------------------     | -----------------------------------------------------------         |
| `IncSearchMatch`        | For all matched pattern. default: `Search`                          |
| `IncSearchMatchReverse` | For all matched pattern in reverse direction.  default: `IncSearch` |
| `IncSearchOnCursor`     | For the matched pattern on the cursor. default: `IncSearch`         |
| `IncSearchCursor`       | For cursor position. default: `Cursor`                              |
| `IncSearchUnderline`    | It's not used by default. Just for the customization                |

#### custom highlight

Change cursor color to red

```vim
highlight IncSearchCursor ctermfg=0 ctermbg=9 guifg=#000000 guibg=#FF0000
```

Or use the `g:incsearch#highlight` option like this.

```vim
let g:incsearch#highlight = {
\   'match' : {
\     'group' : 'IncSearchUnderline',
\     'priority' : '10'
\   },
\   'on_cursor' : {
\     'priority' : '100'
\   },
\   'cursor' : {
\     'group' : 'ErrorMsg',
\     'priority' : '1000'
\   }
\ }
```

Author
------
haya14busa (https://github.com/haya14busa)

Special thanks
--------------
osyo-manga(https://github.com/osyo-manga), the author of
https://github.com/osyo-manga/vital-over which is custom command line library
and incsearch.vim heavily depends on.

License
-------

MIT License

```
Copyright (c) 2014 haya14busa

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do so,
subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR
THE USE OR OTHER DEALINGS IN THE SOFTWARE.
```
