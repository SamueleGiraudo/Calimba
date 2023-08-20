---
title: The Calimba language
author: Samuele Giraudo
date: August 2022
geometry: "left=3.0cm,right=3.0cm,top=3.0cm,bottom=3.0cm"
output: pdf_document
lang: en
fontsize: 10 pt
---

WARNING: This page is completely out of date. A new updated version is planned in the
medium/long term (August 2023).


This page describes the way to build programs in the Calimba language. This is the official
documentation of the language.


# A first example
Let us consider a commented example, which is a small program specifying a small music.

This is a Calimba program:
```
{Sets the fundamental frequency to 220 Hz.}
scale cycles 220 in

{Sets the unit duration to 0.5 s.}
scale time 0.5 in

{Definition of a note of 220 Hz and 1 s.}
let n1 =
    %1
in

{Definition of a note from n1 by multiplying by 1.25 its frequency.}
let n2 =
    scale cycles 1.25 in
    n1
in

{Definition of a note from n1 by multiplying by 1.5 its frequency.}
let n3 =
    scale cycles 1.5 in
    n1
in

{Definition of a silence.}
let silence =
    scale vertical 0 in
    %1
in

{Definition of a pattern which can be seen as a function admitting two inputs, %1 and %2.
 This pattern uses concatenations "*", octave decrementation ",", and speed doublings ">".}
let pattern =
    %1 * %1 * %2 * %2, * silence * (%1 * %2)> * (%1 * silence * %2 * %2)>>
in

{The phrase to be played, constructed from the pattern, where each %1 is replaced by n1 and
 each %2 is replaced by (scale vertical 0.5 in n2) + (scale vertical 0.5 in n3).}
pattern[n1; (scale vertical 0.5 in n2) + (scale vertical 0.5 in n3)]
```
Let us call it `Example.cal`.

The command
```
./calimba -f Example.cal -p
```
allows us to listen the music specified by the program.


# Calimba programs
The syntax of the Calimba language is presented here.


## First notions
This part presents the elementary notions of the language.


### Expressions
The _expression_ is the main data structure of a Calimba program. In fact, a Calimba program
is an expression. Any expression `expr` specifies a sound, called _sound_ of `expr`. Two
expressions are _equivalent_ if their sounds are equal. Given some expressions, it is
possible to build bigger ones by associating these through operations. We describe in the
sequel how to build such expressions and explain what are their sounds.


### Interpretations
A file containing a Calimba program must have the extension `.cal`. Each `.cal` file
contains an expression `expr` which specifies a file containing an encoding of the sound of
`expr`.

The expression `expr` is first
translated into a simple expression, then as sound encoded by a functional data structure,
and finally into a PCM file, as summarized by the diagram
```
 Input                           Internal processing                         Output
+------+     +--------------------------------------------------------+     +------+
| .cal |     | +------------+     +-------------------+     +-------+ |     | .pcm |
|      | --> | | Expression | --> | Simple expression | --> | Sound | | --> |      |
| file |     | +------------+     +-------------------+     +-------+ |     | file |
+------+     +--------------------------------------------------------+     +------+
```
This process is the _interpretation_ of a `.cal` file.


### General notions and conventions
The language is case sensitive and blank characters (spaces, tabulations, and line breaks)
are not significant.

Comments are enclosed into symbols `{` and `}`. Nested comments are allowed.

Brackets `(` and `)` can be used to disambiguate expressions involving many operators. The
keywords `begin` and `end` are respectively synonyms of `(` and `)`. They can help for
readability.

A _name_ is a token consisting in a nonempty string made of symbols between `a` and `z`,
between `A` and `Z`, between `0` and `9`, or `_`, and starting with an alphabetic symbol.
The length of a name must be at most $255$.


### Beats
A _beat_ is a token of the form `%N` where `N` is an integer between $1$ and $1024$, called
_index_. For instance, `%1`, `%8`, and `%221` are beats. A beat itself is an expression
(and, in fact, it is the simplest possible expression) and its sound consists in a
sinusoidal wave of a certain number of cycles. This value can be specified (this is
explained later) and is $1$ by default. The index of a beat does not intervene in its sound
(its role is explained latter)..

Moreover, by default, the sound of a beat lasts $1$ s and has $1$ as amplitude. In this
way, the default sound of a beat has a frequency of $1$ Hz.


## Scaling operations
We describe here some operations acting on the number of cycles, the amplitude, or the
duration of an expression.


### Cycles
Given an expression `expr` and a floating point number `X`,
```
scale cycles X in expr
```
is an expression having as sound the sound of `expr` wherein the number of cycles of its
beats are scaled by `X`.

This operation is the _cycle scaling_ by the factor `X`.

For instance,
```
scale cycles 27.5 in %3
```
is an expression having a sound of $27.5$ Hz as frequency, lasting $1$ s, and having $1$ as
amplitude.

Moreover, given an expression `expr`,
```
reset cycles in expr
```
is an expression having as sound the sound of `expr`. The interest of this operation is
that, when the expression `reset cycles in expr` is nested inside cycle scaling operations
like in `scale cycles X in reset cycles in expr` where `X` is a floating point number, the
scaling operation has no effect.

This operation is the _cycle reset_.

For instance,
```
scale cycles 27.5 in
reset cycles in
scale cycles 110 in
%2
```
is an expression having a sound of $110$ Hz as frequency, lasting $1$ s, and having $1$ as
amplitude. The first scaling is reset so that it does not influence the result, and the last
scaling is applied to the beat `%2`. Compare this with the expression
```
scale cycles 27.5 in
scale cycles 110 in
%2
```
which has a sound of $3025$ Hz as frequency ($3025 \ \mathrm{Hz} = 27.5 \times 110 \times 1
\ \mathrm{Hz}$).


### Amplitudes
Given an expression `expr` and a floating point number `X`,
```
scale vertical X in expr
```
is an expression having as sound the sound of `expr` where its amplitude is scaled by `X`.
In other terms, the sound of `expr` is the sound obtained by multiplying by `X` each value
of the wave of the sound of `expr`. If such an obtained value is larger than $1$ (resp.
smaller than $-1$), the obtained value is set to $1$ (resp. $-1$). This mean simply that the
signal is cut so that its amplitude is $1$.

This operation is the _vertical scaling_ by the factor `X`.

For instance,
```
scale cycles 440 in
scale vertical 0.75 in
%1
```
is an expression having a sound of $440$ Hz as frequency, lasting $1$ s, and having $0.75$
as amplitude.

As already explained, the sound of an expression is cut in order to not have an amplitude
greater than $1$ if the absolute value of the scaling factor is to high. For instance
```
scale cycles 440 in
scale vertical 2 in
%1
```
is an expression having a sound of $440$ Hz as frequency, lasting $1$ s, having $1$ as
amplitude, and such that its signal is a clipped sinusoid.


### Durations
Given an expression `expr` and a nonnegative floating point number `X`,
```
scale horizontal X in expr
```
is an expression having as sound the sound of `expr` where its duration is scaled by `X`.

This operation is the _horizontal scaling_ by the factor `X`.

For instance,
```
scale cycles 440 in
scale horizontal 2 in
%1
```
is an expression having a sound of $220$ Hz as frequency, lasting $2$ s, and having $1$ as
amplitude. The frequency of $220$ Hz comes from the fact that since the duration of the
sound of the expression `%1` has been scaled by the factor $2$, the sound lasts $2$ s. Since
the sound has $440$ cycles, its frequency is $220 \ \mathrm{Hz} = 440 \ \mathrm{cycles} \ /
\ 2 \ \mathrm{s}$.


### Times
As we have noticed in the previous section, the horizontal scaling operation modifies the
duration of the sound, but, since this operation preserves the number of cycles of each
beat, the frequency is also modified. Therefore, the horizontal scaling is not enough to
change the speed of the sound of an expression.

Given an expression `expr` and a nonnegative floating point number `X`,
```
scale cycles X in
scale horizontal X in
expr
```
is an expression having as sound the sound of `expr` where its duration is scaled by `X`.
This expression is equivalent to the more concise one
```
scale time X in expr
```

This operation is the _time scaling_ by the factor `X`.

For instance,
```
scale cycles 220 in
scale time 0.5 in
%1
```
is an expression having a sound of $220$ Hz as frequency, lasting $0.5$ s, and having $1$
as amplitude.


### Some syntactical sugar
Given an expression `expr`,
```
expr<
```
is an expression equivalent to
```
scale time 2 in expr
```

Given an expression `expr`,
```
expr>
```
is an expression equivalent to
```
scale time 0.5 in expr
```

Given an expression `expr`,
```
expr,
```
is an expression equivalent to
```
scale cycles 0.5 in expr
```

Given an expression `expr`,
```
expr'
```
is an expression equivalent to
```
scale cycles 2 in expr
```

## Binary operations
We describe here three operations taking as inputs two expressions.


### Concatenation
Given two expressions `expr1` and `expr2`,
```
expr1 * expr2
```
is an expression having as sound the sound of `expr1` followed by the sound of `expr2`. This
operation is associative and noncommutative.

This operation is the _concatenation_.

For instance,
```
(scale cycles 220 in %1)
*
(scale cycles 330 in %1)
```
is an expression having as sound a first sound of $220$ Hz as frequency, lasting $1$ s,
and having $1$ as amplitude, followed by a second sound of $330$ Hz as frequency, lasting
$1$ s, and having $1$ as amplitude. This sound lasts $2$ s.

As another example,
```
scale time 0.5 in
(scale cycles 220 in scale time 3 in %1)
*
(scale cycles 330 in %1)
*
(scale cycles 440 in scale time 0.5 in scale vertical 0.75 in %1)
```
is an expression having as sound a first sound of $220$ Hz as frequency, lasting $1.5$ s,
and having $1$ as amplitude, followed by a second sound of $330$ Hz as frequency, lasting
$0.5$ s, and having $1$ as amplitude, followed by a third sound of $440$ Hz as frequency,
lasting $0.25$ s, and having $0.75$ as amplitude. This sound lasts $2.25$ s. Note that the
first time scaling operation acts on the three subexpressions associated by the
concatenations.


### Addition
Given two expressions `expr1` and `expr2`,
```
expr1 + expr2
```
is an expression having as sound the sound of `expr1` played at the same time with the sound
of `expr2`. If the sounds of `expr1` and `expr2` do not have the same duration, a null
signal is virtually added to the end of the shorter sound. As it is the case for the
vertical scaling operation, the signal of the obtained sound is cut. This operation is
associative and commutative.

This operation is the _addition_.

For instance,
```
scale cycles 110 in
scale time 2.5 in
%1
+
(scale cycles 1.5 in %1)
+
(scale cycles 2 in scale time 2 in %1)
```
is an expression having as sound a sound of $110$ Hz, lasting $2.5$ s, and having $1$ as
amplitude, played at the same time with a sound of $165$ Hz, lasting $2.5$ s, and having $1$
as amplitude, played at the same time with a sound of $220$ Hz, lasting $5$ s, and having
$1$ as amplitude. The two first sounds last virtually $5$ s, where a silent sound is
concatenated at their end. The sound of the expression is distorted since the sum of
amplitudes of the three added sounds is greater than $1$. Note that the first cycle scaling
operation and the first time scaling operation act on the three subexpressions associated by
the additions.

As another example, let us take the previous one by first vertically scaling the three added
expressions in order to not have a distorted sound as result. This is implemented by the
expression
```
scale cycles 110 in
scale time 2.5 in
(scale vertical 0.33 in %1)
+
(scale vertical 0.33 in scale cycles 1.5 in %1)
+
(scale vertical 0.33 in scale cycles 2 in scale time 2 in %1)
```
wherein each sound of the three added ones is vertically scaled by the factor of
approximately $1 / 3$.


### Multiplication
Given two expressions `expr1` and `expr2`,
```
expr1 ^ expr2
```
is an expression having as sound the sound obtained by multplying each value of the wave of
the sound of `expr1` with the value at the same position of the wave of the sound of
`expr2`. If the sounds of `expr1` and `expr2` do not have the same duration, a null signal
is virtually added to the end of the shorter sound. Since all values of the waves of the
sounds of `expr1` and `expr2` are in the range $[-1, 1]$, all values of the wave of the
sound of `expr1 ^ expr2` belong to the same range, so that the resulting sound is
automatically cut. This operation is associative and commutative.

This operation is the _multiplication_.

For instance,
```
scale cycles 110 in
(scale time 2 in %1)
^
(scale cycles 0.0125 in %1)
```
is an expression having as sound a sound of $110$ Hz, lasting $1$ s, and having $1$ as
amplitude, wherein the values of its wave are multiplied by the values of a sound of $1.375$
Hz, lasting $1$ s, and having $1$ as amplitude. The sound of the expression ends with a
silent sound lasting $1$ s, so that its whole duration is $2$ s.


### Mixing binary operations
An expression using concatenations, additions, and multiplications without brackets is
equivalent to the bracketed expression wherein multiplications have higher priority than
concatenations, and concatenations have higher priority than additions.


## Meta constructions
Aliases, inclusions, compositions, and flags are presented. All expressions using these
constructions are equivalent to expressions using only the previous ones, namely beats,
cycle scaling, cycle reset, vertical scaling, horizontal scaling, concatenation, addition,
and multiplication.


### Aliases
Given a name `NAME` and two expressions `expr1` and `expr2`,
```
let NAME = expr1 in expr2
```
is an expression equivalent to the one obtained by replacing all free occurrences of `NAME`
in `expr2` by `expr1`.

This allows us to name an expression (here `expr1`, with the name `NAME`) and use it in
another expression (here `expr2`), possibly several times. The name `NAME` is an _alias_ for
the expression `expr1`.

For instance,
```
let note_1 =
    scale cycles 220 in %1
in
note_1 * note_1' * note_1<
```
is an expression equivalent to
```
(scale cycles 220 in %1) * (scale cycles 220 in %1)' * (scale cycles 220 in %1)<
```

It is of course possible to nest these constructions. For instance,
```
let note_1 =
    scale cycles 220 in %1
in
let note_2 =
    scale cycles 1.5 in note_1
in
let phrase =
    let sub_phrase = note_1 * note_2 in
    sub_phrase * sub_phrase> * sub_phrase>>
in
phrase
```
is an expression equivalent to
```
(scale cycles 220 in %1) * (scale cycles 1.5 in scale cycles 220 in %1)
*
((scale cycles 220 in %1) * (scale cycles 1.5 in scale cycles 220 in %1))>
*
((scale cycles 220 in %1) * (scale cycles 1.5 in scale cycles 220 in %1))>>
```

Let us clarify what is meant by "replacing all free occurrences". Consider the expression
```
let note_1 =
    scale cycles 220 in %1
in
let note_2 =
    scale cycles 1.5 in note_1
in
let x =
    note_1 * note_2
in
x
*
begin
    let x =
        (scale vertical 0.5 in note_1)
        +
        (scale vertical 0.5 in note_2)
    in
    x * note_1
end
```
This expression is equivalent to the one where the first occurrence of the alias `x` (in the
10-th line) is replaced by `note_1 * note_2`. On the contrary, this expression is not
equivalent to the one where the second occurrence of the alias `x` (in the 18-th line) is
replaced by `note_1 * note_2` since this occurrence of `x` is not free. It is indeed
captured by the second `let x = ... in ... `. This expression is equivalent to the one where
this occurrence of `x` is replaced by the expression `(scale vertical 0.5 in note_1) +
(scale vertical 0.5 in note_2)`. For these reasons, this expression is equivalent to
```
(scale cycles 220 in %1)
*
(scale cycles 1.5 in scale cycles 220 in %1)
*
((scale vertical 0.5 in scale cycles 220 in %1)
+
(scale vertical 0.5 in scale cycles 1.5 in scale cycles 220 in %1))
*
(scale cycles 220 in %1)
```


### Inclusions
Given a path `PATH` to file containing a Calimba program,
```
put PATH
```
is an expression equivalent to the one obtained by replacing it by the expression inside the
Calimba program located at `PATH`. This is the _inclusion_ of `PATH`.

The path `PATH` is the path without the extension `.cal` relative to the file from which the
inclusion is made to a file containing Calimba program. The length of a path is at most
$255$. A path is made of alphanumerical characters or characters `_`, `.`, or `/`.

For instance, if `Sequence.cal` and `Main.cal` are two files belonging to a same directory
and with the respective following contents
```
{Sequence.cal}
let note_1 =
    scale cycles 220 in
    %1
in
let note_2 =
    scale cycles 1.5 in
    note_1
in
note_1 * note_2 * note_1' * (note_1 * note_2,)>

```
and
```
{Main.cal}
let seq = put Sequence in
seq * seq< * seq>>
```
then the expression contained in `Main.cal` is equivalent to the one obtained by replacing
each occurrence of the alias `seq` by the expression contained in `Sequence.cal`.


### Compositions
Given an expression `expr` and expressions `expr_1`, ..., `expr_N`,
```
expr[expr_1; ...; expr_N]
```
is an expression equivalent to the one obtained by replacing, for all indices $i$ between
$1$ and $N$, all occurrences of the beats `%i` by the expressions `expr_i`.

This operation is the _composition_.

For instance,
```
let note_1 =
    scale cycles 220 in
    %1
in
let note_2 =
    scale cycles 1.5 in
    note_1
in
let pattern =
    %1 * ((scale vertical 0.5 in %1) + scale vertical 0.5 in %2) * (%2 * %1)> * %3
in
pattern[note_1; note_2; note_1 * note_2]
```
is an expression equivalent to
```
let note_1 =
    scale cycles 220 in
    %1
in
let note_2 =
    scale cycles 1.5 in
    note_1
in
note_1
*
((scale vertical 0.5 in note_1) + scale vertical 0.5 in note_2)
*
(note_2 * note_1)>
*
(note_1 * note_2)
```

The composition operation is the reason for existence of the indices of the beats. It allow
us to build easily complex expressions and brings a high-level dimension to the language.


### Flags
A _flag_ is a token of the form `$NAME` where `NAME` is a name. A _flag status_ is either
`on`, `off`, or `random`.

Given a flag status `st`, a flag `$fl`, and an expression `expr`,
```
set st $fl in expr
```
is the expression `expr` wherein the flag `$fl` is

+ on if `st` is `on`;
+ off if `st` is `off`;
+ has probability $1 / 2$ to be on and probability $1 / 2$ to be off if `st` is `random`.

The interest of flags comes with the following construction. Given a flag status `st`, a
flag `$fl`, and two expressions `expr1` and `expr2`,
```
if st $fl then
    expr1
else
    expr2
```
is an expression equivalent to

+ `expr1` if `st` is `on` and `$fl` is on, or `st` is off and `$fl` is off;
+ `expr2` if `st` is `on` and `$fl` is off, or `st` is off and `$fl` is on;
+ `expr1` with a probability $1 / 2$ and `expr2` with a probability $1 / 2$ if `st` is
`random`.

For instance,
```
scale cycles 220 in
set on $flag1 in
set on $flag2 in
if off $flag2 then
    %1
else begin
    (scale cycles 1.5 in %1) * %1
end
```
is an expression equivalent to
```
scale cycles 220 in
set on $flag1 in
set on $flag2 in
(scale cycles 1.5 in %1) * %1
```
Moreover,
```
scale cycles 220 in
set on $flag1 in
set on $flag2 in
if random $flag2 then
    %1
else begin
    (scale cycles 1.5 in %1) * %1
end
```
has probability $1 / 2$ to be equivalent to the previous expression and probability $1 / 2$
to be equivalent to
```
scale cycles 220 in
set on $flag1 in
set on $flag2 in
%1
```


# Constructions

## Elementary constructions

### Silences
A _silence_ is an expression having as sound a silence sound. The expression
```
{Silence_1}
scale vertical 0 in
%1
```
is a silence.


### Repetitions
A _repetitor_ is an expression `expr` such that, when composed with another expression
`expr_1`, is equivalent to the expression `expr_1` concatenated with itself a certain number
of times. The expression
```
{Repetitor_2}
%1 * %1
```
is a repetitor as well as the expressions
```
{Repetitor_3}
%1 * %1 * %1
```
and
```
{Repetitor_4}
%1 * %1 * %1 * %1
```


### Chords
A _chord_ is an expression `expr` such that, when composed with other expressions
`expr_1`, ..., `expr_n`, is equivalent to the expression where `expr_1`, ..., `expr_n` are
added after to be vertically scaled in order to do not provoke any distortion. The
expression
```
{Chord_2}
(scale vertical 0.5 in %1)
+
(scale vertical 0.5 in %2)
```
is a chord, as well as the expression

```
{Chord_3}
(scale vertical 0.333 in %1)
+
(scale vertical 0.333 in %2)
+
(scale vertical 0.333 in %3)

```


### Let ring
TODO


## Building synthesizers

### Timbres
TODO


### Envelopes
TODO

## Building effects

### Octavers
TODO

### Delays
TODO

### Detuners
TODO

## Scales
TODO

### Definitions
TODO

### Transpositions
TODO

## Randomizations
TODO


# Examples
TODO

