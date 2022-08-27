(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020, may 2021, aug. 2021, nov. 2021,
 * dec. 2021, may 2022, aug. 2022
 *)

(* About numbers. *)

(* Returns the rounded integer version of the float x. *)
let to_rounded_int x =
   int_of_float (Float.round x)

(* Returns the integer being the truncation of the float x. If x is too big or to small to
 * be converted into an integer, then max_int or min_int is returned. *)
let bounded_int_of_float x =
    if x >= float_of_int max_int then
        max_int
    else if x <= float_of_int min_int then
        min_int
    else
        Float.to_int x


(* About optional values. *)

(* Returns def if the optional value opt is None. Otherwise, returns the value carried by
 * opt. *)
let option_value opt def =
    match opt with
        |Some x -> x
        |None -> def


(* About lists. *)

(* Returns the prefix of length n of the list lst. *)
let rec prefix_list lst n =
    match lst, n with
        |_, n when n <= 0 -> []
        |[], _ -> []
        |x :: lst', n -> x :: (prefix_list lst' (n - 1))


(* About characters and strings. *)

(* Returns the string obtained by indenting each line of the string str by k spaces. *)
let indent k str =
    assert (k >= 0);
    let ind = String.make k ' ' in
    str |> String.fold_left
        (fun (res, c') c ->
            let s = String.make 1 c in
            if c' = Some '\n' then (res ^ ind ^ s, Some c) else (res ^ s, Some c))
        (ind, None)
        |> fst

(* Tests if the character c is an alphabetic character. *)
let is_alpha_character c =
    ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')

(* Tests if the character c is a character allowed in aliases. *)
let is_plain_character c =
     (is_alpha_character c) || ('0' <= c && c <= '9') || c = '_'


(* About strings representing paths. *)

(* Returns the extension of the file at path path. Raises Not_found if path has no
 * extension. *)
let extension path =
    let i = String.rindex path '.' in
    String.sub path i ((String.length path) - i)

(* Tests if the file at path path has the extension ext (with the point). *)
let has_extension ext path =
    if not (String.contains path '.') then
        false
    else
        extension path = ext

(* Returns the string obtained from the path path by removing its file extension, including
 * the '.'. *)
let remove_extension path =
    assert (String.contains path '.');
    let i = String.rindex path '.' in
    String.sub path 0 i

(* Returns the path obtained by suppressing the last part of the path path, by keeping the
 * `/`. For instance, if path is "aa/ab/abc", then "aa/ab/" is returned. If path has no
 * occurrence of '/', the empty path is returned. *)
let trim_path path =
    try
        let i = String.rindex path '/' in
        String.sub path 0 (i + 1)
    with
        |Not_found -> ""

(* Returns the path obtained from the path path by simplifying the "..". For instance, if
 * path is "a/b/c/../../d/e/..", then "a/d" is returned. *)
let simplify_path path =
    let tmp = String.split_on_char '/' path in
    tmp |> List.fold_left
        (fun res u -> if u = ".." then List.tl res else u :: res)
        []
     |> List.rev |> String.concat "/"

(* Returns a path that does not correspond to any existing file by adding a string "_N"
 * just before the extension of the path path, where N is an adequate number. *)
let new_file_name path =
    let path' = remove_extension path and ext' = extension path in
    let rec aux i =
        let res_path = Printf.sprintf "%s_%d%s" path' i ext' in
        if Sys.file_exists res_path then
            aux (i + 1)
        else
            res_path
    in
    aux 0


(* About program arguments. *)

(* Tests if the current execution environment admits the string arg as argument. *)
let has_argument arg =
    Array.mem arg Sys.argv

(* Returns the list of at most the nb arguments following the argument arg in the current
 * execution environment. The list can be shorten than nb if there are less that nb such
 * arguments. The list is empty if arg is not an argument of the current execution
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


(* About files. *)

(* A type to represent positions in a file. *)
type file_position = {
    path: string;
    line: int;
    column: int
}

(* Returns the file position having path as path, line a line number and column as column
 * number. *)
let construct_file_position path line column =
    assert (path <> "");
    assert (0 <= line);
    assert (0 <= column);
    {path = path; line = line; column = column}

(* Returns the file position specified by the lexing position pos. *)
let position_to_file_position pos =
    {path = pos.Lexing.pos_fname;
    line = pos.Lexing.pos_lnum;
    column = pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1}

(* Returns a string representation of the file position fp. *)
let file_position_to_string fp =
    Printf.sprintf "@%s L%d C%d" fp.path fp.line fp.column


(* About colors and inputs/outputs. *)

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
    flush stdout

(* Prints the string str as an information. *)
let print_information_1 str =
    print_string (csprintf Blue str);
    flush stdout

(* Prints the string str as an information. *)
let print_information_2 str =
    print_string (csprintf Magenta str);
    flush stdout

(* Prints the string str as an information. *)
let print_information_3 str =
    print_string (csprintf Yellow str);
    flush stdout

(* Prints the string str as a success. *)
let print_success str =
    print_string (csprintf Green str);
    flush stdout

