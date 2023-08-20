(* Author: Samuele Giraudo
 * Creation: (jul 2020), jul. 2023
 * Modifications: jul. 2023
 *)

(* Management of arguments.
 *
 * Here are some definitions:
 *
 *    - An ARGUMENT is any word following the executable name when the executable is
 *      launched.
 *      For instance, if the executable name is x and the executable is launched with
 *          x -o v1 v2 --opt2 v3
 *      then -o, v1, v2 , --opt2, and v3 are the arguments.
 *
 *    - A SHORT OPTION is any argument of the form -C where C is a character.
 *
 *    - A LONG OPTION is any argument of the form --STR where STR is a string.
 *
 *    - A VALUE of a (short or long) argument is a word following a (short or long) argument
 *      or following itself a value.
 *      For instance in
 *          -o v1 v2 --opt2 v3 v4 v5 --opt3
 *      v1 and v2 are values of -o, v3, v4, and v5 are values of --opt2, and --opt3 has no
 *      values.
 *)

(* Tests if the string arg can be a short option name. *)
let is_short_option_name arg =
    String.length arg >= 2 && String.get arg 0 = '-' && String.get arg 1 <> '-'

(* Tests if the string arg can be a long option name. *)
let is_long_option_name arg =
    String.length arg >= 3 && String.get arg 0 = '-' && String.get arg 1 = '-'
        && String.get arg 2 <> '-'

(* Tests if the string arg can be a value name. *)
let is_value_name arg =
    String.length arg >= 1 && String.get arg 0 <> '-'

(* Tests if the string arg can be an argument name. *)
let is_argument_name arg =
    is_short_option_name arg || is_long_option_name arg || is_value_name arg

(* Returns the list of the arguments. *)
let arguments =
    let len = Array.length Sys.argv in
    let args = List.init (len - 1) (fun i -> Sys.argv.(i + 1)) in
    args |> List.filter is_argument_name

(* Tests if the current execution environment admits the string arg as argument. *)
let exists arg =
    assert (is_argument_name arg);
    List.mem arg arguments

(* Returns the list of the arguments following the argument arg. The returned list is empty
 * when arg does not appear as an argument. *)
let arguments_after arg =
    assert (is_argument_name arg);
    let rec search_suffix args =
        match args with
            |[] -> []
            |x :: args' when x = arg -> args'
            |_ :: args' -> search_suffix args'
    in
    search_suffix arguments

(* Returns the list of the values of the option opt. The empty list is returned when opt is
 * not an option. *)
let option_values opt =
    assert (is_short_option_name opt || is_long_option_name opt);
    let rec longest_prefix_of_values args =
        match args with
            |x :: args' when is_value_name x -> x :: longest_prefix_of_values args'
            |_ -> []
    in
    opt |> arguments_after |> longest_prefix_of_values

(* Tests if the option name opt is an option and admits the value name v as value. *)
let option_has_value opt v =
    assert (is_short_option_name opt || is_long_option_name opt);
    assert (is_value_name v);
    List.mem v (option_values opt)

