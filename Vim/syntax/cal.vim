" Author: Samuele Giraudo
" Creation: mar. 2022
" Modifications: mar. 2022, may 2022, aug. 2022

" Syntax file of the Calimba language.
" This file has to be at ~/.vim/syntax/cal.vim

if exists("b:current_syntax")
    finish
endif

" Turns off spell checking.
set nospell

" Structure keywords.
syn keyword Structure begin
syn keyword Structure end
syn keyword Structure let
syn keyword Structure in
syn match Structure "="

" Unary operators keywords.
syn keyword Operator scale
syn keyword Operator reset

" Attributes of unary operators keywords.
syn keyword Special cycles
syn keyword Special vertical
syn keyword Special horizontal
syn keyword Special time

" Flag management keywords.
syn keyword Structure if
syn keyword Structure then
syn keyword Structure else
syn keyword Structure set

" Attributes of flag management keywords.
syn keyword Special on
syn keyword Special off
syn keyword Special random

" Inclusion keyword.
syn keyword Include put

" Composition symbols.
syn match Macro "\["
syn match Macro "\]"
syn match Macro ";"

" Operator symbols.
syn match Operator "+"
syn match Operator "*"
syn match Operator "\^"
syn match Operator ","
syn match Operator "'"
syn match Operator "<"
syn match Operator ">"

" Variables.
syn match Constant "%\d\+"

" Numbers.
syn match Number "\d\+\.\?\d*"

" Flags.
syn match Identifier "$[a-zA-Z]\+[a-zA-Z0-9_]*"

" Aliases.
syn match Normal "[a-zA-Z]\+[a-zA-Z0-9_]*"

" Comments.
syn region Comment start="{" end="}"

