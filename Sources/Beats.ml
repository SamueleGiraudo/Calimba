(* Author: Samuele Giraudo
 * Creation: jul. 2023
 * Modifications: jul. 2023
 *)

(* A type for beats. *)
type beats = Beat of int

(* Returns the index of the beat b. *)
let index b =
    let Beat index = b in
    index

(* Returns a string representation of the beat b. *)
let to_string b =
    Printf.sprintf "%%%d" (index b)

