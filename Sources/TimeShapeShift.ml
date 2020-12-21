(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A time shape shift is an integer value encoding a number increments (resp. decrements) of
 * times when it is positive (resp. negative). For instance, for a time shape with a
 * multiplier equal to 3 and a divider equal to 2, a time shape shift of 5 specifies
 * (3 / 2) ** 5 units of time, and a time shape shift of -3 specifies (2 / 3) ** 3 units of
 * time. *)
type time_shape_shift = int

(* Returns a string representation of the time shape shift s. *)
let to_string tss =
    let str =
        if tss <= 0 then
            String.make (-tss) '<'
        else
            String.make tss '>' in
    Tools.csprintf Tools.Magenta str

