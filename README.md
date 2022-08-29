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

Calimba interprets and plays files written in the Calimba language. The specifications and
the documentation of the language are [here](Help.md).


## First example
Here is a commentated [Calimba program](Examples/Example1.cal) playing a harmonic
progression. Here is the corresponding [WAV file](Example1.wav) and [PNG file](Example1.png)
of a picture of the wave of the sound.


## Versions
Here is the [changelog](Versions.md) of the different versions.


## Installation
The following instructions hold for Linux systems like Debian or Archlinux, after 2022.


### Dependencies
The following programs or libraries are needed:

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


### Standard library
The [standard library](Std) contains definitions of synthesizers, effects, scales,
transformations (repetitions, chords, let ring constructions), and randomization tools.


### Examples
TODO


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

