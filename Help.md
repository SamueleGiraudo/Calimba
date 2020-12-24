# Calimba language
This page describes all the instructions of the calimba language


## General conventions
Comments are enclosed into symbols `{` and `}`. Nested comments are allowed.

Identifiers are strings made of symbols in `a`-`z`, `A`-`Z`, `0`-`9`, or `_`, and starting
with an alphabetic symbol or `_`.


## Elementary notions

### Notes
Any integer (positive as well as negative) expressed in decimal specifies a note. By
default, `0` is the note $A$ of frequency $440$ Hz. Each positive integer `d` specifies a
note located `d` steps above the root `0`. Negative integers specify notes symmetrically.
Here is a part of this correspondence

| ... |  -7 | ... |  -3 |  -2 |  -1 | **0** |   1 |   2 |   3 | ... |   7 |   8 | ... |
|-----|-----|-----|-----|-----|-----|-------|-----|-----|-----|-----|-----|-----|-----|
| ... | $A,$| ... | $E$ | $F$ | $G$ |   $A$ | $B$ | $C$ | $D$ | ... | $A'$| $B'$| ... |

where $A,$ is the note $A$ one octave below, and $A'$ and $B'$ are the notes $A$ and $B$ one
octave above.

Such integers specifying notes are called _shifts_.

### Rests
A rest is specified by a `.`. It is interpreted as an absence of a sound.


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

If `p1` and `p2` are two phrases having different durations, `p1 # p2` is also well-defined
and the result is obtained by adding the right amount of rests after the shorter phrase.


### Durations
Given an atom `a`, `a<` is the same atom but lasting $2$ units of time instead of $1$.
Similarly, `a>` is the same atom but lasting $\frac{1}{2}$ units of time. These operators
`<` and `>` can be stacked so that `<` doubles the duration and `>` divides it by half.

| ... | `a>>>` |`a>>` | `a>` | `a` | `a<` | `a<<` | `a<<<` | ... |
|-----|--------|------|------|-----|------|-------|--------|-----|
| ... |  $1/8$ | $1/4$| $1/2$| $1$ |  $2$ |  $4$  |   $8$  | ... |

These operators can be applied also on phrases to change all their durations. For instance,
```
(0 # 2 # 4) * .< * (0 # 2 # 4)<< * (1< * 2 * 3)>
```
is a phrase wherein an $A$ minor chord is played for $1$ unit of time, then a rest of $2$
units of time, then the same chord is played for $4$ units of time, and finally the sequence
of notes $B$, $C$ and $D$ is played where the first lasts $1$ unit of time and the second
and third last $\frac{1}{2}$ unit of time.


### Octaves
Given a shift `s`, `s'` is the same shift but one octave higher. Similarly, `a,` is the same
shift but one octave below. These operators `'` and `,` can be stacked to express shifts in
different octaves.

These operators can be applied also on phrases to change the octave of their shifts. For
instance,
```
(0 * 2 * 4 * (0' # 4')) * (0 * 2 * 4 * (0' # 4')),,
```
is a phrase wherein a first phrase is played and then the same phrase is played two octaves
below.


## Basic notions

### Begin end
To clarify some parts of a program, it can be useful to have at disposal different kinds of
brackets. For this reason, we can use `begin` and `end`, acting respectively as `(` and `)`.


### Layouts
A _layout_ is formed by a sequence of positive integers specifying an interval structure.
Here are some common layouts in the $12$ tones equal temperament:

| Layout        | Name              | Notes                                               |
|---------------|-------------------|-----------------------------------------------------|
| 2 1 2 2 1 2 2 | Natural minor     | $A$, $B$, $C$, $D$, $E$, $F$, $G$                   |
| 2 2 1 2 2 2 1 | Natural major     | $A$, $B$, $C\sharp$, $D$, $E$, $F\sharp$, $G\sharp$ |
| 2 1 2 2 1 3 1 | Harmonic minor    | $A$, $B$, $C$, $D$, $E$, $F$, $G\sharp$             |
| 1 3 1 2 1 2 2 | Phrygian dominant | $A$, $A\sharp$, $C\sharp$ $D$, $E$, $F$, $G$        |
| 1 3 1 2 1 3 1 | Double harmonic minor | $A$, $A\sharp$, $C\sharp$ $D$, $E$, $F$, $G\sharp$ |
| 3 2 2 3 2     | Pentatonic minor  | $A$, $C$, $D$, $E$, $G$                             |
| 2 2 3 2 3     | Pentatonic major  | $A$, $B$, $C\sharp$, $E$, $F\sharp$                 |
| 2 1 4 1 4     | Hirajoshi         | $A$, $B$, $C$, $E$, $F$                             |
| 4 1 2 4 1     | Ryukyu            | $A$, $C\sharp$, $D$, $E$, $G\sharp$                 |

The default layout is the natural minor one. It is possible to change the underlying layout
with
```
put layout = i1 i2 ... ik in phr
```
where `i1 i2 ... ik` is the desired layout, and `phr` is the phrase on which this layout
applies. For instance
```
put layout = 2 3 2 2 3 in 0< * 4,< * 1> * 2>
*
put layout = 2 1 2 2 1 3 1 in 0< * 4,< * 1> * 2>
```
plays a phrase in the $A$ minor pentatonic layout and then the same phrase in the $A$
harmonic minor layout.


### Root notes
By default, the note specified by the shift `0` is the note $A$ of frequency $440$ Hz. It is
possible to change it with
```
put root = st nst oct in phr
```
where `st` is the step number of the note, `nst` is the number of steps by octave in the
`nst`-tone equal temperament, `oct` is the octave number (this number can be negative to
reach low pitched notes), and `phr` is the phrase on which this root note applies. For
instance,
```
put root = 2 12 -2 in 0 * 1 * 2
*
put root = 3 12 1 in 0 * 1 * 2
```
plays a phrase in the minor layout first with $B$ as root note two octaves below the octave
$0$ and then with $C$ as root note one octave above the octave $0$.


### Time layouts
A _time layout_ is formed by a _time multiplier_ `m` and a _time divider_ `d`. The operator
`<` (resp. `>`) multiplies by `m / d` (resp. `d / m`) the duration of each atom on the
phrase it applies. In the default time layout, the time multiplier is `2` and the time
divider is `1`. It is possible to change the underlying time layout with
```
put time = m d in phr
```
where `m` and `d` specify the time layout and `phr` is a phrase. For instance,
```
put time = 2 1 in 0<< * 0'> * . * 4
*
put time = 3 2 in 0<< * 0'> * . * 4
```
plays first a phrase such that the atom $0$ is played on $(2 / 1)^2 = 4$ times, then $0'$ is
played on $(2 / 1)^{-1} = 1 / 2$ times, then a rest of $(2 / 1)^0 = 1$ time is played, and
the atom $4$ is played on $(2 / 1)^0 = 1$ time. In the second phrase, the atom $0$ is played
on $(3 / 2)^2 = 9 / 4$ times, then $0'$ is played on $(3 / 2)^{-1} = 2 / 3$ times, then a
rest of $(3 / 2)^0 = 1$ times is played, and the atom $4$ is played on $(3 / 2)^0 = 1$
times.


### Transpositions
To transpose a phrase `phr` of `d` degrees (where `d` can be negative), use the _composition
operator_ `@@`.  In `phr @@ d`, each is atom of `phr` is incremented by `d`. For instance,
```
(0 * 2 * 4 @@ 0)
*
(0 * 2 * 4 @@ 3)
*
(0 * 2 * 4 @@ -2)
```
is a phrase wherein `0 * 2 * 4` is played, then `3 * 5 * 7`, and then `-2 * 0 * 2` are
played.


### Let in
TODO


### Built-in structures
TODO



## Intermediate notions

### Synthesizers
TODO


### Effects
TODO


### Compositions
TODO


### Named atoms and compositions
TODO


### Microtonality
TODO


