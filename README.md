# Calimba
A programming language to create music based on the theory of operads and clones.

Copyright (C) 2020 Samuele Giraudo - `samuele.giraudo@u-pem.fr` -
[https://igm.univ-mlv.fr/~giraudo/]


## Versions
+ `0.0010` (2020-12-12)
    + Initial version


## Quick overview and examples
This program offers a complete language allowing to create music in a functional programming
style. Musical phrases can be composed (or inserted one into another) by using operators
coming from operad and clone theory. The program generates and plays pcm files, so that it
does not need any specific sound server It comes with its own synthesizer and its own sound
manipulation tools. This language does no depend on any heavy external library.


### Main functionalities
1. Interprets and plays a file written in Calimba language (see specification below).
1. Offers an environment for live coding.
1. Analyses the music by drawing its signal and printing some information about the used
   layouts.


### Complete examples
1. A simple melody. (TODO)
1. A harmonic progression. (TODO)
1. Three patterns in interaction (TODO)
1. A phasing based music. (TODO)
1. Microtonal exploration. (TODO)


## Building
The following instructions hold for Linux systems like Debian or Archlinux, after 2020.

1. Clone the repository somewhere by running
   `git clone https://github.com/SamueleGiraudo/Calimba.git`.

2. Install all dependencies (see the section below).

3. Build the project by running `chmod +x Compil` and then `./Compil`.

This creates an executable `calimba`.


## Dependencies
The following programs are needed and they are available for most of the Linux systems like
Debian or Archlinux, after 2020.

+ `ocaml` (Version `>= 4.11.1`. Inferior versions may be suitable.)
+ `ocaml-findlib`
+ `opam`
+ `ocamlbuild` (Available by `opam install ocamlbuild`.)
+ `extlib` (Available by `opam install extlib`.)
+ `graphics` (Available by `opam install graphics`.)


## User guide
This [page](Help.md) contains the description of the Calimba language.

Calimba file have `cal` as extension. Given such a file `Program.cal`, the command

+ `./calimba -f Program.cal -p` plays the music specified by the program;
+ `./calimba -f Program.cal -w` creates the PCM file `Program.pcm` containing the music
  specified by the program;
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
All (when well-formed) is an expression: notes, assemblies of notes, context specifications
(layouts, time layouts, synthesizers, _etc._). For this reason, it is possible to build
complex expressions by nesting some smaller ones.
CONTINUE

### Tree patterns and composition
The fundamental data structure is the _tree pattern_. A tree pattern is defined to be,
recursively
+ an atom;
+ the concatenation of two tree patterns;
+ the stacking of two tree patterns;
+ the modification of a tree pattern.
CONTINUE


## Bibliography

+ About operads:
    + M. Méndez.
      Set operads in combinatorics and computer science.
      Springer, Cham, SpringerBriefs in Mathematics, xvi+129, 2015.
    + S. Giraudo.
      Nonsymmetric Operads in Combinatorics.
      Springer Nature Switzerland AG, ix+172, 2018.

TODO (cite Paul Hudak)

