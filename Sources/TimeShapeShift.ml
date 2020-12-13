(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A time shape shift is an integer value encoding the number of wanted increments (resp.
 * decrements) of times if it is positive (resp. negative). *)
type time_shape_shift = int

(* Returns a string representation of the time shape shift s. *)
let to_string tss =
    if tss <= 0 then
        String.make (-tss) '<'
    else
        String.make tss '>'

