(* Author: Samuele Giraudo
 * Creation: jul. 2023
 * Modifications: jul. 2023
 *)

(* Prints the string str as an error. *)
let print_error str =
    str |> Strings.csprintf Strings.Red |> print_string;
    flush stdout

(* Prints the string str as an information. *)
let print_information_1 str =
    str |> Strings.csprintf Strings.Blue |> print_string;
    flush stdout

(* Prints the string str as an information. *)
let print_information_2 str =
    str |> Strings.csprintf Strings.Magenta |> print_string;
    flush stdout

(* Prints the string str as an information. *)
let print_information_3 str =
    str |> Strings.csprintf Strings.Yellow |> print_string;
    flush stdout

(* Prints the string str as a success. *)
let print_success str =
    str |> Strings.csprintf Strings.Green |> print_string;
    flush stdout

(* Returns a buffer containing the string representation of the expression e. *)
let to_buffered_string e =
    let buffer = Buffer.create 16 in
    let rec aux e =
        match e with
            |Expressions.Beat (_, b) ->
                Beats.to_string b |> Buffer.add_string buffer
            |Expressions.CycleOperation (_, op, e1) ->
                Printf.sprintf "(%s in " (Expressions.cycle_operation_to_string op)
                |> Buffer.add_string buffer;
                aux e1;
                ")" |> Buffer.add_string buffer
            |Expressions.UnaryOperation (_, op, e1) ->
                Printf.sprintf "(%s in " (Expressions.unary_operation_to_string op)
                |> Buffer.add_string buffer;
                aux e1;
                ")" |> Buffer.add_string buffer
            |Expressions.BinaryOperation (_, op, e1, e2) ->
                "(" |> Buffer.add_string buffer;
                aux e1;
                Printf.sprintf " %s " (Expressions.binary_operation_to_string op)
                |> Buffer.add_string buffer;
                aux e2;
                ")" |> Buffer.add_string buffer
            |Expressions.FlagTest (_, st, fl, e1, e2) ->
                Printf.sprintf "(if %s %s then "
                    (Flags.status_to_string st)
                    (Flags.to_string fl)
                |> Buffer.add_string buffer;
                aux e1;
                " else " |> Buffer.add_string buffer;
                aux e2;
                ")" |> Buffer.add_string buffer
            |Expressions.FlagModification (_, st, fl, e1) ->
                Printf.sprintf "(set %s %s in "
                    (Flags.status_to_string st)
                    (Flags.to_string fl)
                |> Buffer.add_string buffer;
                aux e1;
                ")" |> Buffer.add_string buffer
            |Expressions.Alias (_, alias) -> alias |> Buffer.add_string buffer
            |Expressions.AliasDefinition (_, alias, e1, e2) ->
                Printf.sprintf "(let %s = " alias |> Buffer.add_string buffer;
                aux e1;
                " in " |> Buffer.add_string buffer;
                aux e2;
                ")" |> Buffer.add_string buffer
            |Expressions.Composition (_, e1, e_lst) ->
                "(" |> Buffer.add_string buffer;
                aux e1;
                "[" |> Buffer.add_string buffer;
                e_lst |> List.iter (fun e2 ->
                    aux e2;
                    "; " |> Buffer.add_string buffer);
                Buffer.truncate buffer (Buffer.length buffer - 1);
                "]" |> Buffer.add_string buffer
            |Expressions.Put (_, path) -> path |> Buffer.add_string buffer
    in
    aux e;
    buffer

