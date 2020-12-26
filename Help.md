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
To play some notes at the same time, separate them with the operator `#` called _composition
operator_.

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
Similarly, `a>` is the same atom but lasting $1 / 2$ units of time. These operators
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
and third last $1 / 2$ units of time.


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
operator_ `@@`. In `phr @@ d`, each is atom of `phr` is incremented by `d`. For instance,
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
Given a phrase, it is possible to give it a name in order to play it when wanted and
possibly several times by referring to it by its name. One achieves this with
```
let name = phr1 in phr2
```
where `name` is a name, and `phr1` and `phr2` are two phrases. This plays the phrase `phr2`
wherein all free occurrences of `name` are replaced by `phr1`.
For instance,
```
let arpeggio = 0 * 2 * 4 in
arpeggio, * 0'> * arpeggio
```
attaches the name `arpeggio` to the phrase `0 * 2 * 4` and plays this phrase one octave
below, then `0'>`, and finally `arpeggio`. This phrase is equivalent to
```
(0 * 2 * 4), * 0'> * (0 * 2 * 4)
```

It is possible to next these constructions. For instance, the phrase
```
let arpeggio1 = 0 * 2 * 4 * 0' in
let arpeggio2 = arpeggio1 @@ 2 in
let sequence = arpeggio1> * arpeggio2 * arpeggio1 in
sequence * (arpeggio1 # arpeggio2)
```
is equivalent to the phrase
```
(0 * 2 * 4 * 0')> * (2 * 4 * 6 * 2') * (0 * 2 * 4 * 0')
    * ((0 * 2 * 4 * 0') # (2 * 4 * 6 * 2'))
```

Let us clarify what is meant by replacing all free occurrences. In the phrase
```
let x = 1 * 3 in
x * (let x = 0 # 2 in x * 0)
```
the first occurrence of `x` (first character of the second line) is replaced by `1 * 3`, but
the second one (fourth character starting from the end of the second line) is not replaced
by `1 * 3` since this occurrence of `x` in the phrase `let x = 0 # 2 in x * 0` is not free.
It is indeed captured by the second `let in`. For these reasons, this phrase is equivalent
to
```
(1 * 3) * ((0 # 2) * 0)
```

### Built-in structures
There are three other main built-in structures. In what follows, `phr` is any phrase.


#### Repeat
The phrase
```
repeat k phr
```
where `k` is a positive integer plays `k` times `phr`.


#### Reverse
The phrase
```
reverse phr
```
plays `phr` from the end to the beginning.


#### Complement
The phrase
```
complement phr
```
plays `phr` wherein all its shifts are complemented. The _complement_ of a shift `s` is the
unique shift `sc` such that `s + sc = 0`.

For instance, the phrases
```
1 * -1' * 3,
```
and
```
-1 * 1, * -3'
```
are equivalent.


## Intermediate notions

### Synthesizers
Phrases are played by using synthesizers whose characteristics make it possible to model
totally different sounds. A synthesizer is specified by

1. the maximal duration `m` of the sound in ms;
1. the duration `a` of the attack of the sound in ms;
1. the duration `d` of the decay of the sound in ms;
1. the power `p` of the sound, which is a floating number between $0$ and $1$;
1. the geometric ratio `r` for of the coefficients of the harmonics of the sound, which is a
  floating number strictly between $0$ and $1$.

The first tree components describe the _shape_ of the sound. Given an atom of duration
`t` ms, the shape modifies the associated sounds as depicted here
```
---___ /         \
      /--___      \
     /%%%%%%---___ \
    /%%%%%%%%%%%%%--\___
   /%%%%%%%%%%%%%%%%%\  ---___
  /%%%%%%%%%%%%%%%%%%%\       ---___
 /%%%%%%%%%%%%%%%%%%%%%\            ---___
/%%%%%%%%%%%%%%%%%%%%%%%\                 ---___
+-------------------m--------------------------+
+---a--+         +--d---+
+-----------t-----------+
```
More precisely, this diagram is obtained by drawing the following segments: a first
connecting $(0, 0)$ and $(a, 1)$, a second connecting $(t - d, 1)$ and $(t, 0)$, and a third
connecting $(0, 1)$ and $(m, 0)$. The area under these three segments (containing the `%` in
the picture) is applied to the signal of the sound in order to obtain a signal having
specified form.

Let us consider some examples:

+ If $(m, a, d, t) = (1000, 250, 125, 500)$, we obtain the diagram
```
---___    _/       \
      ---/--___     \
       _/%%%%%%---___\
      /%%%%%%%%%%%%%--\___
    _/%%%%%%%%%%%%%%%%%\  ---___
   /%%%%%%%%%%%%%%%%%%%%\       ---___
 _/%%%%%%%%%%%%%%%%%%%%%%\            ---___
/%%%%%%%%%%%%%%%%%%%%%%%%%\                 ---___
+-------------------1000-------------------------+
+---250----+       +--125-+
+-----------500-----------+
```

+ If $(m, a, d, t) = (1000, 250, 125, 250)$, we obtain the diagram
```
---_\     /
     \---/___
      \_/    ---___
      /\           ---___
    _/%%\                ---___
   /%%%%%\                     ---___
 _/%%%%%%%\                          ---___
/%%%%%%%%%%\                               ---____
+-------------------1000-------------------------+
+---250----+
    +--125-+
+---250----+
```

+ If $(m, a, d, t) = (1000, 250, 125, 1500)$, we obtain the diagram
```
---___    _/                                                      \
      ---/--___                                                    \
       _/%%%%%%---___                                               \
      /%%%%%%%%%%%%%---___                                           \
    _/%%%%%%%%%%%%%%%%%%%%---___                                      \
   /%%%%%%%%%%%%%%%%%%%%%%%%%%%%---___                                 \
 _/%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%---___                            \
/%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%---___                       \
+-------------------1000-------------------------+                        \
+---250----+                                                       +--125-+
+---------------------------------1500------------------------------------+
```


The fourth and fifth components `p` and `r` describe the coefficients of the harmonics of
the sounds produced by additive synthesis. Let us denote by $\lambda_i$ the coefficient of
the $i$-th harmonics of the produced sound. Then, we have $\alpha_{i + 1} = r \alpha_i$ and
$\alpha_1 = p$. Only harmonics having coefficient smaller than or equal as $2^{-16}$ are
considered.

A sound with an high value for `p` is more powerful but has more chances to saturated (for
instance when several atoms are stacked). A sound with an high value for `r` has more
harmonics and seems more aggressive.

Here are some examples of the first harmonics coefficients given some values for `p` and
`r`:

|  `p`  |  `r`  | Harmonics coefficients                                                   |
|-------|-------|--------------------------------------------------------------------------|
| $1.0$ | $0.1$ | $1.0$, $0.1$, $0.01$, $0.001$, $0.0001$                                  |
| $0.5$ | $0.1$ | $0.5$, $0.05$, $0.005$, $0.0005$, $0.0001$                               |
| $1.0$ | $0.2$ | $1.0$, $0.2$, $0.04$, $0.008$, $0.0016$, $0.0003$, $0.0001$              |
| $1.0$ | $0.3$ | $1.0$, $0.3$, $0.09$, $0.027$, $0.0081$, $0.0024$, $7.10^{-4}$, $2.10^{-4}$, $10^{-4}$, $\sim 0.0$

### Effects
If `phr` is a phrase, the phrase
```
put effect = eff a1 ... ak in phr
```
plays it under the effect `eff` with the arguments `a1 ... ak`. Let us list the available
effects.


#### Scale
The _scale effect_ `scale` admits one argument `s` which is a nonnegative floating number.
This multiplies by `s` the signal of the sound specified by `phr`. If the amplitude of the
signal is too high at some parts, this amplitude is reduced to a maximal threshold. For this
reason, a scaling can produce some interesting clipping effects. Here is an example:
```
put effect = scale 1.5 in 1 * 1 * (0 # 4)
```


#### Delay
The _delay effect_ `delay` admits two arguments: a first `d` which is a nonnegative integer
and a second `s` which a nonnegative floating number. This stacks to the sound specified by
`phr` the same sound delayed by `d` ms and scaled by `s`. Here is an example:
```
put effect = delay 100 0.75 in
0 * (0 # 4) * 1 * 2
```


#### Clip
The _clip effect_ `clip` admits one argument `s` which is a floating number strictly between
$0$ and $1$. This reduce to `s` the amplitude of the signal of the sound specified by `phr`.
Depending of the original sound of `phr`, an adequate value for `s` can produce some
distortion effects. Here is an example:
```
put effect = clip 0.7 in
0 * (0 # 4 # 0, # 4')<, * 0
```


#### Tremolo
The _tremolo effect_ `tremolo` admits two arguments: a first `t` which is a positive integer
and a second `v` which is a floating number between $0$ and $1$. This changes the sound
specified by `phr` in order to introduce a tremolo effect so that, periodically each `t` ms,
the volume of the sound decreases and increases to its original value. The sound decreases
to the value specified by `v`: if `v` is close to `1.0`, the tremolo effect is slight, and
if `v` is close to `0.0`, the tremolo effect becomes more pronounced. Here is an example:
```
put effect = tremolo 125 0.7 in
0 * 2 * 4 * (0 # 2 # 4)< * (-1 # 1 # 3)<
```


### Compositions
TODO


### Named atoms and compositions
TODO


### Microtonality
TODO


