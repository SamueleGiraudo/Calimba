# Calimba
`<</\|_`

A programming language to create music based on the theory of operads and clones.

Copyright (C) 2020--2023 [Samuele Giraudo](https://igm.univ-mlv.fr/~giraudo/) -
`giraudo.samuele@uqam.ca` -


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


## First examples
Here are some simple and commentated examples illustrating some features of the language:

+ [A Calimba program](Examples/Example1.cal) playing a harmonic progression.
+ [A Calimba program](Examples/Example2.cal) playing a pattern modified by the composition
  operation (the fundamental operation of the language).


## Versions
Here is the [changelog](Versions.md) of the different versions.


## Installation
The following instructions hold for Linux systems like Debian or Archlinux, after 2022.


### Dependencies
The following programs or libraries are needed:

+ `pkg-config`
+ `make`
+ `ocaml` (Version `>= 5.0.0`. An inferior but not too old version may be suitable.)
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

Calimba program files must have `.cal` as extension. The main command is

```
./calimba [--help] [--version] --file PATH [--verbose] [--bunch START LEN] [--text] [--write] [--draw] [--play]
```

where

+ `--help` prints the short help.
+ `--version` prints the version and other information.
+ `--file PATH` sets `PATH` as the path to the Qlusster program to consider.
+ `--verbose` enables the verbose mode.
+ `--bunch START LEN` specifies the part of the generated signal to consider, with its
  starting time `START` and length `LEN` in seconds.
+ `--text` creates the CAL file containing the processed expression specified the program.
+ `--write` creates the PCM file specified by the program.
+ `--draw` creates the SVG and PNG files specified by the program.
+ `--play` plays the signal specified by the program.


### Standard library
The [standard library](Stdlib) contains definitions of synthesizers (trying to mimic some
existing ones), effects, scales, transformations (repetitions, chords, let ring
constructions), and randomization tools.


### Documentation of the standard library
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

