(* Author: Samuele Giraudo
 * Creation: (jul. 2020), may 2021
 * Modifications: (jul. 2020, aug. 2020, dec. 2020, jan. 2021), may 2021, jun. 2021,
 * aug. 2021, nov. 2021, dec. 2021, jan. 2022, mar. 2022, may 2022, aug. 2022
 *)

(* The type of beats. *)
type beat = int

(* The type of the values (parameters of some operations). *)
type value = float

(* The type of flags. *)
type flag = string

(* The type of aliases. *)
type alias = string

(* The type of file paths for inclusion. *)
type path = string

(* The two operations to control the number of cycles for a beat. *)
type cycle_operation =
    |UpdateCycleNumber of value
    |ResetCycleNumber

(* The two kinds of unary operations. *)
type unary_operation =
    |VerticalScaling of value
    |HorizontalScaling of value

(* The three kinds of binary operations. *)
type binary_operation =
    |Concatenation
    |Addition
    |Multiplication

(* The three possible statuses for a flag. *)
type flag_status =
    |On
    |Off
    |Random

(* A type to represent expressions. *)
type expression =
    (* The leaf. *)
    |Beat of Information.information * beat

    (* The control of the number of cycles for a beat. *)
    |CycleOperation of Information.information * cycle_operation * expression

    (* The unary operations. *)
    |UnaryOperation of Information.information * unary_operation * expression

    (* The binary operations. *)
    |BinaryOperation of Information.information * binary_operation * expression * expression

    (* The management of flags. *)
    |FlagTest of Information.information * flag_status * flag * expression * expression
    |FlagModification of Information.information * flag_status * flag * expression

    (* The meta-operation of composition. *)
    |Composition of Information.information * expression * (expression list)

    (* The management of aliases. *)
    |Alias of Information.information * alias
    |AliasDefinition of Information.information * alias * expression * expression

    (* The management of inclusions. *)
    |Put of Information.information * path

(* Returns a string representation of the cycle operation op. *)
let cycle_operation_to_string op =
    match op with
        |UpdateCycleNumber x -> Printf.sprintf "scale cycles %.8g" x
        |ResetCycleNumber -> "reset cycles"

(* Returns a string representation of the unary operation op. *)
let unary_operation_to_string op =
    match op with
        |VerticalScaling x -> Printf.sprintf "scale vertical %.8g" x
        |HorizontalScaling x -> Printf.sprintf "scale horizontal %.8g" x

(* Returns a string representation of the binary operation op. *)
let binary_operation_to_string op =
    match op with
        |Concatenation -> "*"
        |Addition -> "+"
        |Multiplication -> "^"

(* Returns a string representation of the flag status st. *)
let flag_status_to_string st =
    match st with
        |On -> "on"
        |Off -> "off"
        |Random -> "random"

(* Returns a string representation of the expression e. *)
let rec to_string e =
    match e with
        |Beat (info, i) -> Printf.sprintf "{%s}\n%%%d" (Information.to_string info) i
        |CycleOperation (info, op, e1) ->
            Printf.sprintf "{%s}\n(%s\nin\n%s)"
                (Information.to_string info)
                (cycle_operation_to_string op) (to_string e1)
        |UnaryOperation (info, op, e1) ->
            Printf.sprintf "{%s}\n(%s\nin\n%s)"
                (Information.to_string info)
                (unary_operation_to_string op)
                (to_string e1)
        |BinaryOperation (info, op, e1, e2) ->
            Printf.sprintf "{%s}\n(%s\n%s\n%s)"
                (Information.to_string info)
                (to_string e1)
                (binary_operation_to_string op)
                (to_string e2)
        |FlagTest (info, st, fl, e1, e2) ->
            Printf.sprintf "{%s}\n(if %s $%s then\n%s\nelse\n%s)"
                (Information.to_string info)
                (flag_status_to_string st)
                fl
                (to_string e1)
                (to_string e2)
        |FlagModification (info, st, fl, e1) ->
            Printf.sprintf "{%s}\n(set %s $%s\nin\n%s)"
                (Information.to_string info)
                (flag_status_to_string st)
                fl
                (to_string e1)
        |Alias (info, alias) ->
            Printf.sprintf "{%s}\n%s" (Information.to_string info) alias
        |AliasDefinition (info, alias, e1, e2) ->
            Printf.sprintf "{%s}\n(let %s =\n%s\nin\n%s)"
                (Information.to_string info)
                alias
                (to_string e1)
                (to_string e2)
        |Composition (info, e1, e_lst) ->
            Printf.sprintf "{%s}\n(%s\n[%s])"
                (Information.to_string info)
                (to_string e1)
                (e_lst |> List.map to_string |> String.concat "; ")
        |Put (info, path) ->
            Printf.sprintf "{%s}\n(put %s)" (Information.to_string info) path

(* Returns the information data of the root of the expression e. *)
let root_information e =
    match e with
        |Beat (info, _)
        |CycleOperation (info, _, _)
        |UnaryOperation (info, _, _)
        |BinaryOperation (info, _, _, _)
        |FlagTest (info, _, _, _, _)
        |FlagModification (info, _, _, _)
        |Composition (info, _, _)
        |Alias (info, _)
        |AliasDefinition (info, _, _, _)
        |Put (info, _) ->
            info

