(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* To handle syntax errors in parsing. *)
exception SyntaxError of string

(* To handle errors in the values read from parsed files. *)
exception ValueError of string

(* Representation of the 8 terminal colors in order to specify colored text to print. *)
type color =
    |Black
    |Red
    |Green
    |Yellow
    |Blue
    |Magenta
    |Cyan
    |White

(* Return the binary logarithm of x. *)
let log2 x =
    (Float.log x) /. (Float.log 2.0)

(* If x is none, def is returned. Otherwise, the image by the map tr of the value contained
* in x is returned. *)
let transform_option_default tr x def =
    match x with
        |Some x' -> tr x'
        |None -> def

(* Returns the remainder of the Euclidean division of a by b. This value is always
 * positive. *)
let remainder a b =
    let res = a mod b in
    if res >= 0 then res else res + b

(* Returns the prefix of length n of the list lst. *)
let rec prefix_list lst n =
    match lst, n with
        |_, n when n <= 0 -> []
        |[], _ -> []
        |x :: lst', n -> x :: (prefix_list lst' (n - 1))

(* Returns the Cartesian product of the two lists lst1 and lst2. *)
let cartesian_product lst1 lst2 =
    lst1 |> List.map (fun a -> lst2 |> List.map (fun b -> (a, b))) |> List.flatten

(* Returns the list of all occurrences (positions) of x in the list lst. *)
let occurrences lst x =
    lst |> List.fold_left
        (fun (res, i)  a -> if a  = x then (i :: res, i + 1) else (res, i + 1))
        ([], 0)
        |> fst |> List.rev

(* Returns the list of integers such that the i-th value is the number of occurrences of
 * the element first + i in the list of integers lst. The returned list has length
 * last - first + 1. *)
let occurrence_vector lst first last =
    List.init (last - first + 1) (fun i -> i + first) |> List.map
        (fun i -> lst |> List.filter (fun x -> x = i) |> List.length)

(* Returns the accuracy of the observed value observed w.r.t. the expected value expected.
 * These values are floats. *)
let accuracy expected observed =
    (observed -. expected) /. expected

(* Returns -1 (resp. 1) if the value candidate_1 (candidate_2) approximate better than
 * candidate_2 (resp. candidate_1) the value expected. If candidate_1 and candidate_2 are
 * equal, 0 is returned. *)
let compare_accuracies expected candidate_1 candidate_2 =
    compare
        (Float.abs (accuracy expected candidate_1))
        (Float.abs (accuracy expected candidate_2))

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

(* Prints the string str as a success. *)
let print_success str =
    print_string (csprintf Green str);
    print_newline ()

