(* Author: Samuele Giraudo
 * Creation: (jul. 2020), may 2021
 * Modifications: (jul. 2020, aug. 2020, dec. 2020, jan. 2021), may 2021, jun. 2021,
 * aug. 2021, nov. 2021, dec. 2021, jan. 2022, mar. 2022, may 2022, aug. 2022, nov. 2022,
 * jul. 2023
 *)

(* The type of aliases. *)
type aliases = string

(* The type of file paths for inclusion. *)
type paths = string

(* The two operations to control the number of cycles for a beat. *)
type cycle_operations =
    |UpdateCycleNumber of Scalars.scalars
    |ResetCycleNumber

(* The two kinds of unary operations. *)
type unary_operations =
    |VerticalScaling of Scalars.scalars
    |HorizontalScaling of Scalars.scalars

(* The three kinds of binary operations. *)
type binary_operations =
    |Concatenation
    |Addition
    |Multiplication

(* A type to represent expressions. *)
type expressions =
    (* The leaf. *)
    |Beat of (Information.information * Beats.beats)

    (* The control of the number of cycles for a beat. *)
    |CycleOperation of (Information.information * cycle_operations * expressions)

    (* The unary operations. *)
    |UnaryOperation of (Information.information * unary_operations * expressions)

    (* The binary operations. *)
    |BinaryOperation of
        (Information.information * binary_operations * expressions * expressions)

    (* The management of flags. *)
    |FlagTest of
        (Information.information * Flags.statuses * Flags.flags * expressions * expressions)
    |FlagModification of
        (Information.information * Flags.statuses * Flags.flags * expressions)

    (* The meta-operation of composition. *)
    |Composition of (Information.information * expressions * (expressions list))

    (* The management of aliases. *)
    |Alias of (Information.information * aliases)
    |AliasDefinition of
        (Information.information * aliases * expressions * expressions)

    (* The management of inclusions. *)
    |Put of (Information.information * paths)

(* An exception to handle cases where an expression has a inappropriate form. *)
exception ValueError of expressions * string

(* Returns a string representation of the cycle operation op. *)
let cycle_operation_to_string op =
    match op with
        |UpdateCycleNumber x -> Printf.sprintf "scale cycles %s" (Scalars.to_string x)
        |ResetCycleNumber -> "reset cycles"

(* Returns a string representation of the unary operation op. *)
let unary_operation_to_string op =
    match op with
        |VerticalScaling x -> Printf.sprintf "scale vertical %s" (Scalars.to_string x)
        |HorizontalScaling x -> Printf.sprintf "scale horizontal %s" (Scalars.to_string x)

(* Returns a string representation of the binary operation op. *)
let binary_operation_to_string op =
    match op with
        |Concatenation -> "*"
        |Addition -> "+"
        |Multiplication -> "^"

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

