# Calimba language
This page describes the way to build programs in the Calimba language.


## General conventions
Comments are enclosed into symbols `{` and `}`. Nested comments are allowed.

_Names_ are nonempty strings made of symbols in `a`-`z`, `A`-`Z`, `0`-`9`, or `_`, and
starting with an alphabetic symbol or `_`.


## Elementary notions

### Notes and degrees
A _degree_ is an integer (positive as well as negative) expressed in the decimal numeral
system. Each degree specifies a note in the following way. By default (because this behavior
is configurable, this will be exposed later), `0` is the note $A$ of frequency $440$ Hz, and
each positive (resp. negative) degree `d` specifies a note located `d` steps above (resp.
below) the origin `0` in the diatonic scale. Here is a part of this correspondence

| Degree | Note  |
|--------|-------|
| ...    | ...   |
|  -9    | $F,,$ |
|  -8    | $G,,$ |
|  -7    | $A,$  |
|  -6    | $B,$  |
|  -5    | $C,$  |
|  -4    | $D,$  |
|  -3    | $E,$  |
|  -2    | $F,$  |
|  -1    | $G,$  |
| **0**  | $A$   |
|   1    | $B$   |
|   2    | $C$   |
|   3    | $D$   |
|   4    | $E$   |
|   5    | $F$   |
|   6    | $G$   |
|   7    | $A'$  |
|   8    | $B'$  |
|   9    | $C'$  |
| ...    | ...   |

where for any note $X$, $X'$ (resp. $X,$) is the note $X$ one octave above (resp. below).

In the Calimba language, we handle degrees instead of notes to keep flexibility. Indeed, as
we will see in the following, degrees can be interpreted in the context of different scales
(called layouts here) to be in correspondence with different notes.


### Rests
A rest is specified by a `.` (a period). It is interpreted as an absence of a sound.


### Concatenation
To play notes and rests one after the other, we separate these with the operator `*`, called
_concatenation operator_. Each note and rest lasts one unit of time, which is worth by
default $500$ ms.

For instance,
```
0 * 4 * 0 * 5 * . * 5 * 4
```
is the phrase consisting in the notes $A$, $E$, $A$, and $F$, a rest, and the notes $F$
and $E$ played in this order, one after the other. This phrase lasts $3500$ ms.


### Stacking
To play some notes at the same time, we separate these with the operator `#`, called
_stacking operator_.

For instance,
```
0 # 2 # 4
```
is the phrase consisting in the notes $A$, $C$, and $E$ played at the same time. This phrase
lasts $500$ ms.


### Mixing concatenation and stacking
The concatenation and stacking operators work not only on notes and rests but also on
phrases. Therefore, it is possible to build complex phrases, by using brackets if needed.

For instance,
```
(0 * . * 2) # (. * (-1 # 3) * .) # (7 * 1 * 2)
```
is a correct phrase.

Without brackets, `*` has an higher priority than `#`.

If `phr1` and `phr2` are two phrases having different durations, `phr1 # phr2` is also
well-defined and the result is obtained by extending the shortest phrase by a silence
lasting the right amount of time.


### Durations
Given a degree or a rest `a`, `a<` refers to the same degree or rest but lasts $2$ units of
time instead of $1$. Similarly, `a>` refers to the same degree or rest but lasts $1 / 2$
units of time. These operators `<` and `>` can be stacked so that `<` doubles the duration
and `>` divides it by half. Here are some examples

| Degrees of rests with duration signs | Units of time |
|--------------------------------------|---------------|
| ...                                  | ...           |
| `a>>>`                               | $1 / 8$       |
| `a>>`                                | $1 / 4$       |
| `a>`                                 | $1 / 2$       |
| `a`                                  | $1$           |
| `a<`                                 | $2$           |
| `a<<`                                | $4$           |
| `a<<<`                               | $8$           |
| ...                                  | ...           |

These operators can be applied also on phrases to change the durations of all their degrees
and rests. For instance,
```
(0 # 2 # 4) * .< * (0 # 2 # 4)<< * (1< * 2 * 3)>
```
is a phrase wherein an $A$ minor chord is played for $1$ unit of time, then a rest of $2$
units of time, then the same chord is played for $4$ units of time, and finally the sequence
of notes $B$, $C$ and $D$ is played where the first lasts $1$ unit of time, and the second
and third last $1 / 2$ units of time.


### Octaves
Given a degree `d`, `d'` is the degree specifying the same note as the one specified by `d`
but one octave higher. Similarly, `d,` (`d` followed by a comma) specifies the same note as
the one specified by `d` but one octave below. Therefore, since the default layout has $7$
degrees by octave, for any degree `d`, `d'` refers to the degree `d + 7`, and `d,` refers to
the degree `d - 7`. These operators `'` and `,` can be stacked in order to express degrees
in different octaves.

These operators can be applied also on phrases to change the octave of the notes they
specify. For instance,
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
A _layout_ is formed by a sequence of positive integers specifying an interval structure and
thus a scale. Here are some common layouts in the $12$ tones equal temperament:

| Layout        | Name              | Notes                                               |
|---------------|-------------------|-----------------------------------------------------|
| 2 1 2 2 1 2 2 | Natural minor     | $A$, $B$, $C$, $D$, $E$, $F$, $G$                   |
| 2 2 1 2 2 2 1 | Natural major     | $A$, $B$, $C\sharp$, $D$, $E$, $F\sharp$, $G\sharp$ |
| 2 1 2 2 1 3 1 | Harmonic minor    | $A$, $B$, $C$, $D$, $E$, $F$, $G\sharp$             |
| 1 3 1 2 1 2 2 | Phrygian dominant | $A$, $A\sharp$, $C\sharp$ $D$, $E$, $F$, $G$        |
| 1 3 1 2 1 3 1 | Gypsy major       | $A$, $A\sharp$, $C\sharp$ $D$, $E$, $F$, $G\sharp$  |
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
By default, the note specified by the degree `0` is the note $A$ of frequency $440$ Hz. It
is possible to change it with
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
plays a phrase in the natural minor layout first with $B$ as root note two octaves below the
octave $0$ and then with $C$ as root note one octave above the octave $0$.


### Atoms and time degrees
An _atom_ is a degree or a rest together with an integer specifying its duration. This
integer is a _time degree_. Its default value is `0` and its role will be explained in the
next section.


### Time shapes
A _time shape_ is formed by a _time multiplier_ `m` and a _time divider_ `d`. An atom having
`t` as time degree lasts $(m / d)^t$ units of time.

The operator `<` (resp. `>`) increases (resp. decreases) the time degrees of all the atoms
of the phrase on which it applies. Therefore, since the time multiplier of the default time
shape is `2` and the time divider is `1`, `<` (resp. `>`) doubles the durations (resp.
divides by half) of all the atoms of the phrase on which it applies.

It is possible to change the underlying time shape with
```
put time = m d in phr
```
where `m` and `d` specify the time shape and `phr` is a phrase. For instance,
```
put time = 2 1 in 0<< * 0'> * . * 4
*
put time = 3 2 in 0<< * 0'> * . * 4
```
plays first a phrase such that the degree `0` is played on $(2 / 1)^2 = 4$ times, then `0'`
is played on $(2 / 1)^{-1} = 1 / 2$ times, then a rest of $(2 / 1)^0 = 1$ time is played,
and the degree `4` is played on $(2 / 1)^0 = 1$ time. In the second phrase, the degree `0`
is played on $(3 / 2)^2 = 9 / 4$ times, then `0'` is played on $(3 / 2)^{-1} = 2 / 3$ times,
then a rest of $(3 / 2)^0 = 1$ times is played, and the degree `4` is played on $(3 / 2)^0 =
1$ times.


### Unit duration
The _unit duration_ is the duration in ms of the unit of time. It is possible to change the
unit duration with
```
put duration = t in phr
```
where `t` is is a duration in ms and `phr` is a phrase. This sets to `t` the unit duration
for the phrase `phr`. For instance,
```
put duration = 250 in 0 * 4> * 2> * 6
*
put duration = 125 in 0 * 4> * 2> * 6
```
plays twice the phrase `0 * 4> * 2> * 6`, one time with `250` ms for the unit duration and a
second time with `125` ms as unit duration.


### Transpositions
If `phr` is a phrase, then `phr+` is the phrase obtained from `phr` by incrementing all its
degrees. Similarly, `phr-` is the phrase obtained from `phr` by decrementing all its
degrees.
These operators `+` and `-`, called _transposition operators_ can be stacked in order to
transpose phrases.

For instance,
```
0 * 2 * 4 * (0 * 2 * 4)+++ * (0 * 2 * 4)--
```
is a phrase wherein `0 * 2 * 4` is played, then `3 * 5 * 7`, and then `-2 * 0 * 2` are
played.


### Let in
Given a phrase, it is possible to assign it a name in order to play it when wanted and
possibly several times by referring to it by its name. We achieve this with
```
let name = phr1 in phr2
```
where `name` is a name, and `phr1` and `phr2` are two phrases. This plays the phrase `phr2`
wherein all free occurrences of `name` are replaced by `phr1`. For instance,
```
let arp = 0 * 2 * 4 in
arp, * 0'> * arp
```
attaches the name `arp` to the phrase `0 * 2 * 4` and plays this phrase one octave below,
then `0'>`, and finally `arp`. This phrase is equivalent to
```
(0 * 2 * 4), * 0'> * (0 * 2 * 4)
```

It is possible to nest these constructions. For instance, the phrase
```
let arp1 = 0 * 2 * 4 * 0' in
let arp2 = arp1++ in
let seq = arp1> * arp2 * arp1 in
seq * (arp1 # arp2)
```
is equivalent to the phrase
```
(0 * 2 * 4 * 0')> * (2 * 4 * 6 * 2') * (0 * 2 * 4 * 0')
    * ((0 * 2 * 4 * 0') # (2 * 4 * 6 * 2'))
```

Let us clarify what is meant by "replacing all free occurrences". In the phrase
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
plays `phr` wherein all its degrees are complemented. The _complement_ of a degree `d` is
the degree `-d`.

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
Phrases are played by using synthesizers whose characteristics make it possible to model a
wide range of totally different sounds. A synthesizer is specified by

1. the maximal duration `m` in ms of the produced sounds;
1. the duration `a` of the attack in ms of the produced sounds;
1. the duration `d` of the decay in ms of the produced sounds;
1. the power `p` of the produced sounds, which is a floating number between $0$ and $1$;
1. the geometric ratio `r` for of the coefficients of the harmonics of the produced sounds,
   which is a floating number strictly between $0$ and $1$.

The first three components describe the _shape_ of the sound. Given a degree of duration `t`
ms, the shape modifies the associated sounds as depicted here
```
---___ /         \
      /--___      \
     /XXXXXX---___ \
    /XXXXXXXXXXXXX--\___
   /XXXXXXXXXXXXXXXXX\  ---___
  /XXXXXXXXXXXXXXXXXXX\       ---___
 /XXXXXXXXXXXXXXXXXXXXX\            ---___
/XXXXXXXXXXXXXXXXXXXXXXX\                 ---___
+--------------------m-------------------------+
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
---___    _/    \
      ---/__     \
       _/XXX---___\
      /XXXXXXXXXXX-\-___
    _/XXXXXXXXXXXXXX\   ---___
   /XXXXXXXXXXXXXXXXX\        ---___
 _/XXXXXXXXXXXXXXXXXXX\             ---___
/XXXXXXXXXXXXXXXXXXXXXX\                  ---___

+--------------------1000----------------------+
+----250---+    +--125-+
+----------500---------+
```

+ If $(m, a, d, t) = (1000, 250, 125, 250)$, we obtain the diagram
```
---_\_    _/
     \---/__
      \_/   ---___
      /\          ---___
    _/XX\               ---___
   /XXXXX\                    ---___
 _/XXXXXXX\                         ---___
/XXXXXXXXXX\                              ---___

+--------------------1000----------------------+
+----250---+
    +--125-+
+---250----+
```

+ If $(m, a, d, t) = (1000, 250, 125, 1500)$, we obtain the diagram
```
---___    _/                                                    \
      ---/--___                                                  \
       _/XXXXXX---___                                             \
      /XXXXXXXXXXXXX---___                                         \
    _/XXXXXXXXXXXXXXXXXXXX---___                                    \
   /XXXXXXXXXXXXXXXXXXXXXXXXXXXX---___                               \
 _/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX---___                          \
/XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX---___                     \

+--------------------1000------------------------+
+----250---+                                                    +--125-+
+---------------------------------1500---------------------------------+
```


The fourth and fifth components `p` and `r` describe the coefficients of the harmonics of
the sounds produced by additive synthesis. Let us denote by $\lambda_i$ the coefficient of
the $i$-th harmonics of the produced sound. Then, we have $\lambda_{i + 1} = r \lambda_i$
and $\lambda_1 = p$. Only the harmonics having coefficients smaller than or equal as
$2^{-16}$ are considered (the coefficients smaller than this value are set to $0$).

A sound with an high value for `p` is more powerful but has more chances to be saturated
(for instance when several phrases are stacked). A sound with an high value for `r` has more
harmonics and seems more aggressive.

Here are some examples of the first harmonics coefficients given some values for `p` and
`r`:

|  `p`  |  `r`  | Harmonics coefficients                                                   |
|-------|-------|--------------------------------------------------------------------------|
| $1.0$ | $0.1$ | $1.0$, $0.1$, $0.01$, $0.001$, $0.0001$                                  |
| $0.5$ | $0.1$ | $0.5$, $0.05$, $0.005$, $0.0005$, $0.0001$                               |
| $1.0$ | $0.2$ | $1.0$, $0.2$, $0.04$, $0.008$, $0.0016$, $0.0003$, $0.0001$              |
| $0.5$ | $0.2$ | $0.5$, $0.1$, $0.02$, $0.004$, $0.0008$, $0.0002$, $0.00003$             |

The default synthesizer has the following parameters:

+ `m = 4000`;
+ `a = 40`;
+ `d = 20`;
+ `p = 0.28`;
+ `r = 0.29`.


### Effects
If `phr` is a phrase, the phrase
```
put effect = eff a1 ... ak in phr
```
plays it under the effect `eff` with the arguments `a1 ... ak`. Let us list the available
effects.


#### Scale
The _scale effect_ `scale` admits one argument `c` which is a nonnegative floating number.
This multiplies by `c` the signal of the sound specified by `phr`. If the amplitude of the
signal is too high at some parts, this amplitude is reduced to a maximal threshold. For this
reason, a scaling can produce some interesting clipping effects. Here is an example:
```
put effect = scale 1.5 in 1 * 1 * (0 # 4)
```


#### Clip
The _clip effect_ `clip` admits one argument `c` which is a floating number strictly between
$0$ and $1$. This reduce to `c` the amplitude of the signal of the sound specified by `phr`.
Depending of the original sound of `phr`, an adequate value for `c` can produce some
distortion effects. Here is an example:
```
put effect = clip 0.7 in
0 * (0 # 4 # 0, # 4')<, * 0
```


#### Delay
The _delay effect_ `delay` admits two arguments: a first `t` which is a nonnegative integer
and a second `c` which a nonnegative floating number. This stacks to the sound specified by
`phr` the same sound delayed by `t` ms and scaled by `c`. Here is an example:
```
put effect = delay 100 0.75 in
0 * (0 # 4) * 1 * 2
```


#### Tremolo
The _tremolo effect_ `tremolo` admits two arguments: a first `t` which is a positive integer
and a second `c` which is a floating number between $0$ and $1$. This changes the sound
specified by `phr` in order to introduce a tremolo effect so that, periodically each `t` ms,
the volume of the sound decreases and increases to its original value. The sound decreases
to the value specified by `c`: if `c` is close to `1.0`, the tremolo effect is slight, and
if `c` is close to `0.0`, the tremolo effect becomes more pronounced. Here is an example:
```
put effect = tremolo 125 0.7 in
0 * 2 * 4 * (0 # 2 # 4)< * (-1 # 1 # 3)<
```


## Advanced notions

### Tree patterns
The fundamental data structure under the hood of the Calimba language is the tree pattern.
Formally, a _tree pattern_ is either

1. a leaf containing an atom;
1. or a binary node containing the concatenation symbol and having two tree patterns as
   children;
1. or a binary node containing the stacking symbol and having two tree patterns as children;
1. or a unary node containing a performance and having a tree pattern as child;
1. or a unary node containing an effect and having a tree pattern as child.

A _performance_ is a map sending each atom to a sound (depending on the layout, the root
note, the time shape, the unit duration, and the synthesizer). An _effect_ is a map sending
a sound to a sound (adding for instance a delay or a tremolo effect).

Each phrase translates into a tree pattern before to be converted into a sound.


### Named degrees
It is possible to give a name `u` to a degree `d` in a phrase by writing `s:u`. For
instance, in
```
(0 * 1 * 4:d1) # 7:d2<
```
the third degree `4` is named as `d1` and the fourth degree `7` is named as `d2`. These two
degrees are _named degrees_.


### Compositions

#### Named compositions
Given two phrases `phr1` and `phr2`, and a name `u`,
```
phr1 @u phr2
```
is the phrase obtained by replacing each degree of `phr1` having `u` as name by a slightly
modified version of `phr2`. More precisely, if `d` is a named degree of `phr1` with name
`u`, this degree is replaced by the phrase `phr2` wherein each degree is incremented by `d`
and each atom has its time degree incremented by the time degree of the atom of `d`.

For instance, the phrase
```
(1:d1 * 0:d2 * 2:d1 * 2:d1<) @d1 (1 # 3)
```
is equivalent to the phrase
```
(2 # 4) * 0:d2 * (3 # 5) * (3< # 5<)
```


#### Compositions
Given two phrases `phr1` and `phr2`, and an integer `i`,
```
phr1 @i phr2
```
is the phrase obtained by replacing the `i`-th degree of the tree pattern specified by
`phr1` by `phr2` (subjected to the same modifications as for the case of named
compositions). If there is no `i`-th degree in `phr1`, this gives `phr1`.

For instance, the phrase
```
(repeat 2 (1 * 2<)) @3 (2< * .)
```
is equivalent to the phrase
```
1 * 2< * (3< * .) * 2<
```

#### Binary compositions
Given two phrases `phr1` and `phr2`,
```
phr1 @@ phr2
```
is the phrase obtained by replacing each degree of `phr1` by `phr2` (subjected to the same
modifications as for the case of named compositions and compositions).

For instance, the phrase
```
(2< * 3 * . * 0) @@ ((0 # 4) * 1)
```
is equivalent to the phrase
```
((2< # 6<) * 3<) * ((3 # 7) * 4) * . * ((0 # 4) * 1)
```

The effects of the transposition operators `+` and `-` can be emulated with suitable binary
compositions. Indeed, for any phrase `phr`, the phrase `phr+` (resp. `phr-`) is equivalent
to the phrase `phr @@ 1` (resp. `phr @@ -1`).


### Microtonality
There is no particular restrictions on the used layouts: it is indeed possible to consider
layouts wherein the octave is divided into any number `n` of steps, provided that `n` is
positive. It is therefore possible to compose music in the `n` tones equal temperament.
In this case, it is important to specify a root note living in the same equal temperament.

For instance,
```
put layout = 2 3 3 2 3 3 3 in
put root = 0 19 -2 in
0 # 2 # 4
```
plays a chord of the layout `2 3 3 2 3 3 3` of the `19` tones equal temperament where the
root is the note at step `0` of the octave `-2`.


