let s:suite = themis#suite('util')
let s:assert = themis#helper('assert')

function! s:suite.after_each()
    set ignorecase& smartcase&
endfunction

function! s:suite.parse_pattern()
    call s:assert.equals(
    \   incsearch#parse_pattern('pattern/e', '/'),  ['pattern', 'e'])
    call s:assert.equals(
    \   incsearch#parse_pattern('{pattern\/pattern}/{offset}', '/'),
    \   ['{pattern\/pattern}', '{offset}'])
    call s:assert.equals(
    \   incsearch#parse_pattern('{pattern}/;/{newpattern} :h //;', '/'),
    \   ['{pattern}', ';/{newpattern} :h //;'])
    call s:assert.equals(
    \   incsearch#parse_pattern('pattern?e', '?'),  ['pattern', 'e'])
    call s:assert.equals(
    \   incsearch#parse_pattern('pattern?e', '/'),  ['pattern?e', ''])
    call s:assert.equals(
    \   incsearch#parse_pattern('{pattern\?pattern}?{offset}', '?'),
    \   ['{pattern\?pattern}', '{offset}'])
endfunction

function! s:suite.convert_with_case()
    set noignorecase nosmartcase
    call s:assert.equals(incsearch#convert_with_case('pattern'), '\Cpattern')
    call s:assert.equals(incsearch#convert_with_case('PatterN'), '\CPatterN')
    set ignorecase nosmartcase
    call s:assert.equals(incsearch#convert_with_case('pattern'), '\cpattern')
    call s:assert.equals(incsearch#convert_with_case('PatterN'), '\cPatterN')
    set noignorecase smartcase
    call s:assert.equals(incsearch#convert_with_case('pattern'), '\Cpattern')
    call s:assert.equals(incsearch#convert_with_case('PatterN'), '\CPatterN')
    set ignorecase smartcase
    call s:assert.equals(incsearch#convert_with_case('pattern'), '\cpattern')
    call s:assert.equals(incsearch#convert_with_case('PatterN'), '\CPatterN')
endfunction

function! s:suite.convert_with_case_ignore_uppercase_escaped_letters()
    set noignorecase nosmartcase
    call s:assert.equals(incsearch#convert_with_case('\Vpattern'), '\C\Vpattern')
    call s:assert.equals(incsearch#convert_with_case('\VPatterN'), '\C\VPatterN')
    set ignorecase nosmartcase
    call s:assert.equals(incsearch#convert_with_case('\Vpattern'), '\c\Vpattern')
    call s:assert.equals(incsearch#convert_with_case('\VPatterN'), '\c\VPatterN')
    set noignorecase smartcase
    call s:assert.equals(incsearch#convert_with_case('\Vpattern'), '\C\Vpattern')
    call s:assert.equals(incsearch#convert_with_case('\VPatterN'), '\C\VPatterN')
    set ignorecase smartcase
    call s:assert.equals(incsearch#convert_with_case('\Vpattern'), '\c\Vpattern')
    call s:assert.equals(incsearch#convert_with_case('\VPatterN'), '\C\VPatterN')
endfunction

function! s:suite.convert_with_case_explicit_flag()
    set noignorecase nosmartcase
    call s:assert.equals(incsearch#convert_with_case('\cpattern'), '\c\cpattern')
    call s:assert.equals(incsearch#convert_with_case('\Cpattern'), '\C\Cpattern')
    call s:assert.equals(incsearch#convert_with_case('\CPatterN'), '\C\CPatterN')
    call s:assert.equals(incsearch#convert_with_case('\cPatterN'), '\c\cPatterN')
    set ignorecase nosmartcase
    call s:assert.equals(incsearch#convert_with_case('\cpattern'), '\c\cpattern')
    call s:assert.equals(incsearch#convert_with_case('\Cpattern'), '\C\Cpattern')
    call s:assert.equals(incsearch#convert_with_case('\CPatterN'), '\C\CPatterN')
    call s:assert.equals(incsearch#convert_with_case('\cPatterN'), '\c\cPatterN')
    set noignorecase smartcase
    call s:assert.equals(incsearch#convert_with_case('\cpattern'), '\c\cpattern')
    call s:assert.equals(incsearch#convert_with_case('\Cpattern'), '\C\Cpattern')
    call s:assert.equals(incsearch#convert_with_case('\CPatterN'), '\C\CPatterN')
    call s:assert.equals(incsearch#convert_with_case('\cPatterN'), '\c\cPatterN')
    set ignorecase smartcase
    call s:assert.equals(incsearch#convert_with_case('\cpattern'), '\c\cpattern')
    call s:assert.equals(incsearch#convert_with_case('\Cpattern'), '\C\Cpattern')
    call s:assert.equals(incsearch#convert_with_case('\CPatterN'), '\C\CPatterN')
    call s:assert.equals(incsearch#convert_with_case('\cPatterN'), '\c\cPatterN')
endfunction

function! s:suite.detect_case()
    set ignorecase smartcase
    call s:assert.equals(incsearch#detect_case('\%Cpattern'), '\c')
    call s:assert.equals(incsearch#detect_case('\%Vpattern'), '\c')
    call s:assert.equals(incsearch#detect_case('\%Upattern'), '\c')
    call s:assert.equals(incsearch#detect_case('\%Apattern'), '\C')
    call s:assert.equals(incsearch#detect_case('\%V\%Vpattern'), '\c')
    call s:assert.equals(incsearch#detect_case('\V\Vpattern'), '\c')
endfunction
