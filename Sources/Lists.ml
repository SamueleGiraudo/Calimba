(* Author: Samuele Giraudo
 * Creation: (jul 2020), jul. 2023
 * Modifications: jul. 2023
 *)

(* Returns the prefix of length n of the list lst. *)
let rec prefix lst n =
    match lst, n with
        |_, n when n <= 0 -> []
        |[], _ -> []
        |x :: lst', n -> x :: (prefix lst' (n - 1))

