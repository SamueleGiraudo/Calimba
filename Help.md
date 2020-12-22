# Calimba language
This page describes all the instructions of the calimba language


## General conventions
Comments are enclosed into symbols `{` and `}`. Nested comments are allowed.

Identifiers are strings made of symbols in `a`-`z`, `A`-`Z`, `0`-`9`, or `_`, and starting
with an alphabetic symbol or `_`.


## Elementary notions

### Notes
Any integer (positive as well as negative) expressed in decimal specifies a note. By
default, `0` is the note $A$ of frequency $110$ Hz. Each positive integer `d` specifies a
note located `d` steps above the root `0`. Negative integers specify notes symmetrically.
Here is a part of this correspondence

|  -7 | ... |  -3 |  -2 |  -1 | **0** |   1 |   2 |   3 | ... |   7 |   8 |
|-----|-----|-----|-----|-----|-------|-----|-----|-----|-----|-----|-----|
| $A,$| ... | $E$ | $F$ | $G$ |   $A$ | $B$ | $C$ | $D$ | ... | $A'$| $B'$|

where $A,$ is the note $A$ one octave below, and $A'$ and $B'$ are the notes $A$ and $B$ one
octave above.

Such integers specifying notes are called _shifts_.

### Rests
A rest is specified by a "`.`".


### Atoms
An _atom_ is either a shift of a rest.


### Concatenation
To play notes and rests one after the other, separate them with the operator `*` called
_concatenation operator_. Each note and rest lasts by default $500$ ms.

For instance,
```
0 * 4 * 0 * 5 * . * 5 * 4
```
is the phrase consisting in the notes $A$, $E$, $A$, and $F$, a rest, and the notes $F$
and $E$.


### Composition
To play some notes at the same time, separate them with the operator `#` called
_composition operator_.


For instance,
```
0 # 2 # 4
```
is the phrase consisting in the notes $A$, $C$, and $E$ played at the same time.


### Mixing concatenation and composition
The concatenation and composition operators work not only on notes and rests but also on
phrases. Therefore, it is possible to build more complex phrases, by using brackets if
needed.

For instance,
```
(0 * . * 2) # (. * (-1 # 3) * .) # (7 * 1 * 2)
```
is a correct phrase.

Without brackets, `*` has an higher priority than `#`.

If `p1` and `p2` are two phrases having different durations, `p1 # p2` is also
well-defined and the result is obtained by adding the right amount of rest after the shorter
phrase.


### Durations
TODO


## Basic notions

### Layouts
TODO


### Time layouts
TODO


### Transpositions
TODO


### Let in
TODO


## Intermediate notions

### Synthesizers
TODO


### Compositions
TODO


### Named atoms
TODO



