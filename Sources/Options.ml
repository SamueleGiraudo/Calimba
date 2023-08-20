(* Author: Samuele Giraudo
 * Creation: (jul. 2020), jul. 2023
 * Modifications: jul. 2023
 *)

(* Returns def if the optional value opt is None. Otherwise, returns the value carried by
 * opt. *)
let value def opt =
    match opt with
        |Some x -> x
        |None -> def

(* Returns the image by the map f of the value of the optional value of opt if any. None
 * is returned otherwise. *)
let bind f opt =
    match opt with
        |None -> None
        |Some x -> f x

