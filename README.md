# Calimba
`<</^\|_`

A programming language to create music based on the theory of operads and clones.

Copyright (C) 2020--2021 [Samuele Giraudo](https://igm.univ-mlv.fr/~giraudo/) -
`samuele.giraudo@u-pem.fr` -


Here is a [Discord server](https://discord.gg/n6Du2Q4QFb) for discussions about this
language, including help for installation, bug reports, feature requests, and sharing some
creations. Welcome!


## Quick overview and examples
This program offers a complete language allowing to create music in a functional programming
style. Musical phrases can be inserted one into another by using operators coming from
operad and clone theory. The program generates and plays PCM files, so that it does not need
any specific sound server. It comes with its own synthesizer and its own sound manipulation
tools. This language does no depend on any heavy external library.


### Main functionalities
1. Interprets and plays a file written in the Calimba language (see the specifications
   [here](Help.md)).
1. Offers an environment for live coding.
1. Analyses the music by drawing its signal and printing some information about the used
   layouts.


### Complete examples
1. A [simple melody](Examples/SimpleMelody.cal).
1. A [harmonic progression](Examples/HarmonicProgression.cal).
1. Some [phrases in interaction](Examples/PhrasesInteraction.cal).
1. A [phasing based music](Examples/Phasing.cal).
1. Some [microtonal explorations](Examples/MicrotonalExplorations.cal).
1. A [sound modifier](Examples/SoundModifier.cal).

## Versions
+ `future` (from 2021-01-02)
    + The internal representation of phrases is improved.
    + The syntax for introduce effects is improved.
    + TODO

+ `0.0011` (2021-01-01)
    + A first [documentation](Help.md) is written.
    + A mode to print layout analysis is added.
    + Built-in for [transpositions](Help.md#transpositions) are added.
    + Built-in for integer insertion is removed.
    + The robustness of inputs and outputs is improved.
    + Some internal optimizations and reorganizations are added.

+ `0.0010` (2020-12-12)
    + Initial version.


## Installation
The following instructions hold for Linux systems like Debian or Archlinux, after 2020.

### Dependencies
The following programs are needed:

+ `pkg-config`
+ `ocaml` (Version `>= 4.11.1`. An inferior but not too old version may be suitable.)
+ `opam`
+ `ocamlbuild` (Available by `opam install ocamlbuild`.)
+ `ocamlfind` (Available by `opam install ocamlfind`.)
+ `graphics` (Available by `opam install graphics`.)
+ `extlib` (Available by `opam install extlib`.)
+ `menhir` (Available by `opam install graphics`.)


### Building
Here are the required steps to build the interpreter `calimba`:

1. Clone the repository somewhere by running
   `git clone https://github.com/SamueleGiraudo/Calimba.git`.
2. Install all dependencies (see the section below).
3. Build the executable by running `chmod +x Compil` and then `./Compil`.

This creates an executable `calimba`. The following sections explain how to use it.


## User guide
This [page](Help.md) contains the description of the Calimba language.

Calimba files have `cal` as extension. Given such a file `Program.cal`, the command

+ `./calimba -f Program.cal -p` plays the music specified by the program;
+ `./calimba -f Program.cal -w` creates the PCM file `Program.pcm` containing the music
  specified by the program. The default sampling rate is $480000$ Hz and the depth is $32$
  bits.
+ `./calimba -f Program.cal -l` launches a live loop on the program file. This is an
  infinite loop wherein as soon as `Program.cal` is modified, the music specified by the
  program is played from its beginning.
+ `./calimba -f Program.cal -d start duration` draws in a graphical window the fragment of
  the signal of the music specified by the program, starting from `start` ms and lasting
  `duration` ms.
+ `./calimba -f Program.cal -a` prints some analysis information about the used layouts in
  the program.


## Theoretical aspects

### Functional programming style
All (when well-formed) are expressions: notes, assemblies of notes, context specifications
(layouts, time layouts, synthesizers, _etc._). For this reason, it is possible to build
complex expressions by nesting some smaller ones, without any particular restriction.
Besides, `let in` expressions can be used to write concise code, where names have restricted
scopes.


### Tree patterns and insertion
Any expression reduces to a [tree pattern](Help.md#tree-patterns), the fundamental data
structure of Calimba programs. Tree patterns are then converted into sounds. Given two tree
patterns, it is possible to assemble these in order to build a bigger tree pattern. This
operation is fundamental in the Calimba language. Following its use, this operation allows
us to specify short patterns and consider some slight touch ups of these in order to include
these in full musical compositions.


### Bibliography

+ About operads:
    + M. Méndez.
      Set operads in combinatorics and computer science.
      Springer, Cham, SpringerBriefs in Mathematics, xvi+129, 2015.
    + S. Giraudo.
      Nonsymmetric Operads in Combinatorics.
      Springer Nature Switzerland AG, ix+172, 2018.

+ About representation of music:
    + P. Hudak,
      An Algebraic Theory of Polymorphic Temporal Media
      Practical Aspects of Declarative Languages.
      Lecture Notes in Computer Science, vol 3057, 2004.

