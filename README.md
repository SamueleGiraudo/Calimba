# Calimba
A programming language to create music based on the theory of operads and clones.

Copyright (C) 2020 Samuele Giraudo - `samuele.giraudo@u-pem.fr` -
[https://igm.univ-mlv.fr/~giraudo/]


## Versions
+ `0.0010` (2020-12-12)
    + Initial version


## Quick overview and examples
This program offers a complete language allowing to create music in a functional programming
style. It generates and plays pcm files, so that it does not need any specific sound server.


### Main functionalities
1. TODO


### Complete examples
+ TODO


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

+ `./calimba -f Program.cal` plays the music specified by the program;
+ `./calimba -f Program.cal -w` creates the PCM file `Program.pcm` containing the music
  specified by the program;
+ `./calimba -f Program.cal -l` launches a live loop on the program file. This is an
  infinite loop wherein as soon as `Program.cal` is modified, the music specified by the
  program is played from its beginning.
TODO


## Theoretical aspects
TODO


## Bibliography

+ About operads:
    + M. Méndez.
      Set operads in combinatorics and computer science.
      Springer, Cham, SpringerBriefs in Mathematics, xvi+129, 2015.
    + S. Giraudo.
      Nonsymmetric Operads in Combinatorics.
      Springer Nature Switzerland AG, ix+172, 2018.

TODO

