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

+ `ocaml` (Version `>= 4.11.1`.)
+ `ocamlbuild`
+ `ocaml-findlib`
+ `opam`
+ `extlib` (Available by `opam install extlib`. Do not forget to run `opam init` first.)
+ `rlwrap` (Optional.)


## User guide
This [page](Help.md) contains the description of the Calimba language.

Files containing such instructions must have `cal` as extension. Given such a file
`Program.cal`, the command

+ `./calimba -f Program.cal` plays the file;
+ `./calimba -f Program.cal -w` create the PCM file `Program.pcm`;
+ `./calimba -f Program.cal -l` launches a live loop on the file.


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

