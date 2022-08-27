# Calimba
`<</^\|_`

A programming language to create music based on the theory of operads and clones.

Copyright (C) 2020--2022 [Samuele Giraudo](https://igm.univ-mlv.fr/~giraudo/) -
`samuele.giraudo@univ-eiffel.fr` -


Here is a [Discord server](https://discord.gg/n6Du2Q4QFb) for discussions about this
language, including help for installation, bug reports, feature requests, and sharing some
creations. Welcome!


## Quick overview
This program offers a complete language allowing to create music in a functional programming
style. Musical phrases can be inserted one into another by using operators coming from clone
theory. The program generates and plays PCM files, so that it does not need any specific
sound server. It allows us to synthesize sounds and create effects. This language does no
depend on any heavy external library.

Calimba interprets and plays files written in the Calimba language (see the specifications
[here](Help.md)).


## Examples
TODO


## Versions

+ `0.1010` (2022-08-27)
    + The error management is improved.
    + The syntax is updated and improved.
    + New outputs of signals as images.
    + The possibility to specify bunches in the main command is implemented.

+ `0.1001` (2022-05-30)
    + Infix binary composition is removed.
    + Important code reorganization is performed.
    + Speed optimizations are added.
    + A new Makefile is set.
    + Standard library is improved.

+ `0.1000` (2022-05-10)
    + Infix binary composition is added.
    + A different paradigm is adopted: atoms are only sinusoidal waves with a given number
      number of cycle and with a duration of 1 sec.
    + The vertical and horizontal stretching operations are introduced.
    + The syntax is updated.

+ `0.0111` (2022-01-01)
    + Flags are introduced.
    + Mechanisms to create random music are introduced.
    + The syntax is slightly improved.

+ `0.0110` (2021-12-29)
    + Attack and decay dimensions are suppressed.
    + Modifications of dimensions values are enriched.

+ `0.0101` (2021-08-20)
    + The internal representation of musical phrases is improved.
    + The syntax of the language is completely redesigned.
    + The sound generation process is improved.
    + The output messages are improved.

+ `0.0100` (2021-05-30)
    + The internal representation of phrases is improved.
    + The syntax for introduce effects is improved.

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
The following instructions hold for Linux systems like Debian or Archlinux, after 2022.

### Dependencies
The following programs are needed:

+ `pkg-config`
+ `make`
+ `ocaml` (Version `>= 4.13.1`. An inferior but not too old version may be suitable.)
+ `opam`
+ `ocamlbuild` (Available by `opam install ocamlbuild`.)
+ `ocamlfind` (Available by `opam install ocamlfind`.)
+ `extlib` (Available by `opam install extlib`.)
+ `menhir` (Available by `opam install menhir`.)


### Building
Here are the required steps to build the interpreter `calimba`:

1. Clone the repository somewhere by running
   `git clone https://github.com/SamueleGiraudo/Calimba.git`.

2. Install all dependencies (see the section above).

3. Build the project by running `make`.

This creates an executable `calimba`. The following sections explain how to use it.


## User guide
This [page](Help.md) contains the description of the Calimba language.

Calimba files have `cal` as extension. Given such a file `Program.cal`, the command

+ `./calimba -f Program.cal -p` generates the sound specified by the program and starts
  playing it once the key Enter is pressed;

+ `./calimba -f Program.cal -w` creates the PCM file `Program_N.pcm` containing the sound
  specified by the program. `N` is the smallest decimal value starting from `0` so that the
  target file does not preexist. The default sampling rate is $48000$ Hz and the depth is
  $4$ bytes.

+ `./calimba -f Program.cal -d` creates a SVG file `Program_N.svg` containing the wave of
  the sound specified by the program. `N` is the smallest decimal value starting from `0` so
  that the target file does not preexist.

+ `./calimba -f Program.cal -e` creates a CAL file `Program_N.cal` containing the processed
  version of the expression specified by the program. `N` is the smallest decimal value
  starting from `0` so that the target file does not preexist.

These four commands can be followed by `-b START LENGTH` where START is the starting time
and LENGTH is the length of the desired bunch of the sound. These values are in seconds and
are optional. For instance, `./calimba -f Program.cal -p -b 8 3.5` plays the sound specified
by the program starting from $8$ s and lasting $3.5$ s.


## Miscellaneous
To get the syntax highlighting in the text editor `vim` for the Calimba language, put the
file [cal.vim](Vim/syntax/cal.vim) at `~/.vim/syntax/cal.vim` and the file
[cal.vim](Vim/ftdetect/cal.vim) at `~/.vim/fdetect/cal.vim`.


## Theoretical aspects

### Functional programming style
All are expressions: notes, assemblies of notes, sound transformations, _etc._ For this
reason, it is possible to build complex expressions by nesting some smaller ones, without
any particular restriction. Besides, `let in` expressions can be used to write concise code,
where names have restricted scopes.


### Expressions and compositions
Any expression reduces to a simple expression, the fundamental data structure of Calimba
programs. Simple expressions are then converted into sounds. Given some expressions, it is
possible to assemble these in order to build a bigger expression. This operation is
fundamental in the Calimba language. Following its use, this operation allows us to specify
short patterns and consider some slight touch ups of these in order to include these in full
musical compositions.


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
      An Algebraic Theory of Polymorphic Temporal Media.
      Practical Aspects of Declarative Languages.
      Lecture Notes in Computer Science, vol 3057, 2004.

