incsearch.vim
=============

TODO: cool gif!

Introduction
------------
Incrementally highlight __ALL__ pattern matches unlike default 'incsearch'.
You can use incsearch.vim as improved `/` & `?`.

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

### Emacs-like incsearch: move the cursor while incremental searching
TODO: cool gif!

```vim
IncSearchNoreMap <Tab>   <Inc>(next)
IncSearchNoreMap <S-Tab> <Inc>(prev)
```
Move the cursor to next and previous matches while incremental searching like Emacs.

Author
------
haya14busa (https://github.com/haya14busa)

Special thanks
--------------
osyo-manga(https://github.com/osyo-manga), the author of https://github.com/osyo-manga/vital-over
library which is custome command line library and incsearch.vim heavily depends on.

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
