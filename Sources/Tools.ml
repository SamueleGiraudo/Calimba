(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* To handle syntax errors in parsing. *)
exception SyntaxError of string

(* To handle errors in the values read from parsed files. *)
exception ValueError of string

type color =
    |Black
    |Red
    |Green
    |Yellow
    |Blue
    |Magenta
    |Cyan
    |White

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

let rec suffix_list lst n =
    List.rev (prefix_list (List.rev lst) n)

let factor_list lst i n =
    suffix_list (prefix_list lst (n + i)) n

let rec set_value_list lst i x =
    if i = 0 then
        x :: (List.tl lst)
    else
        (List.hd lst) :: (set_value_list (List.tl lst) (i - 1) x)

(* Tests if the current execution environment admits the string arg as argument. *)
let has_argument arg =
    Array.mem arg Sys.argv

(* Returns the list of at most the nb arguments following the argument arg in the current
 * execution environment. The list can be shorten than nb if there are less that nb such
 * arguments. The list is empty if arg is not an argument of the currect execution
 * environment. *)
let next_arguments arg nb =
    assert (nb >= 1);
    let len = Array.length Sys.argv in
    let args = List.init (len - 1) (fun i -> Sys.argv.(i + 1)) in
    let rec search_suffix args =
        match args with
            |[] -> []
            |x :: args' when x = arg -> args'
            |_ :: args' -> search_suffix args'
    in
    prefix_list (search_suffix args) nb

(* Returns the code for each color corresponding to the coloration code in the terminal. *)
let color_code col =
    match col with
        |Black -> 90
        |Red -> 91
        |Green -> 92
        |Yellow -> 93
        |Blue -> 94
        |Magenta -> 95
        |Cyan -> 96
        |White -> 97

(* Returns the coloration of the string str by the color specified by the color col. *)
let csprintf col str =
    Printf.sprintf "\027[%dm%s\027[39m" (color_code col) str

(* Prints the string str as an error. *)
let print_error str =
    print_string (csprintf Red str);
    print_newline ()

(* Prints the string str as an information. *)
let print_information str =
    print_string (csprintf Blue str);
    print_newline ()

(* Prints the string str as an important information. *)
let print_important str =
    print_string (csprintf Green str);
    print_newline ()

