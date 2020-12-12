(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* To handle syntax errors in parsing. *)
exception SyntaxError of string

(* To handle errors in the values read from parsed files. *)
exception ValueError of string

(* If x is none, def is returned. Otherwise, the image by the map tr of the value contained
* in x is returned. *)
let transform_option_default tr x def =
    match x with
        |Some x' -> tr x'
        |None -> def

(* Returns the prefix of length n of the list lst. *)
let rec prefix_list lst n =
    match lst, n with
        |_, n when n <= 0 -> []
        |[], _ -> []
        |x :: lst', n -> x :: (prefix_list lst' (n - 1))

(* Tests if the current execution environment admits the string arg as argument. *)
let has_argument arg =
    Array.mem arg Sys.argv

(* Returns an option of the argument following the argument arg of the current execution
 * environment. Returns None if arg is not an argument or if there is no argument following
 * it. *)
let next_argument arg =
    let len = Array.length Sys.argv in
    let index = List.init (len - 1) Fun.id |> List.find_opt (fun i -> Sys.argv.(i) = arg) in
    transform_option_default
        (fun i -> if i + 1 < len then Some Sys.argv.(i + 1) else None)
        index
        None

