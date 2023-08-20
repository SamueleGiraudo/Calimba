(* Author: Samuele Giraudo
 * Creation: may 2021
 * Modifications: may 2021, jun. 2021, aug. 2021, nov. 2021, dec. 2021, jan. 2022,
 * mar. 2022, may 2022, aug. 2022, nov. 2022, jul. 2023
 *)

(* A type to contain an option on a processed expression, an option on its sound, and a list
 * of errors. *)
type processings = {
    (* The input expression. This is the expression obtained after each step of processing
     * before the computation of its sound. *)
    expression: Expressions.expressions option;

    (* The sound specified by the expression. *)
    sound: Sounds.sounds option;

    (* The list of errors detected during the processing. *)
    errors: Errors.errors list
}

(* A type to represent a transformation, which is a map from processings to processings. *)
type transformations = Transformation of (processings -> processings)

(* Returns the empty processing. *)
let empty =
    {expression = None; sound = None; errors = []}

(* Returns the expression of the processing pr. The expression of pr must be different from
 * None. *)
let expression pr =
    assert (Option.is_some pr.expression);
    Option.get pr.expression

(* Returns the sound of the processing pr. The expression of pr must be different from
 * None. *)
let sound pr =
    assert (Option.is_some pr.sound);
    Option.get pr.sound

(* Returns the list of errors of the processing pr. *)
let errors pr =
    pr.errors

(* Tests if there are errors in the processing pr. *)
let has_errors pr =
    pr.errors <> []

(* Returns the processing obtained by applying the processing transformation tr on the
 * processing pr. *)
let apply_transformation pr tr =
    let Transformation map = tr in
    map pr

(* Returns the processing transformation which detects the errors computed by the function f
 * sending expressions to error lists. *)
let error_transformation f =
    Transformation
        (fun pr ->
            if has_errors pr then
                pr
            else
                let errs =
                    pr.expression
                    |> Options.bind (fun e -> Some (f e))
                    |> Options.value []
                in
                {pr with errors = errs})

(* Returns the processing transformation which applies the resolution computed by the
 * function f sending expressions to expressions. *)
let resolution_transformation f =
    Transformation
        (fun pr ->
            if has_errors pr then
                pr
            else
                let e' = pr.expression |> Options.bind (fun e -> Some (f e)) in
                {pr with expression = e'})

(* Returns the processing of the expression e by resolving inclusions, aliases, and
 * compositions and flags, by constructing the list of errors in e, and by computing the
 * specified sound.
 *
 * This passes by the following steps:
 *
 * |=======================================|===============================================|
 * |               PROCESSING              |             ERROR DETECTION                   |
 * |=======================================|===============================================|
 * |                                       | Syntax errors in all included files and paths |
 * |---------------------------------------|-----------------------------------------------|
 * | Resolution of inclusions              |                                               |
 * |---------------------------------------|-----------------------------------------------|
 * |                                       | Identifier errors                             |
 * |---------------------------------------|-----------------------------------------------|
 * |                                       | Undefined alias errors                        |
 * |---------------------------------------|-----------------------------------------------|
 * | Resolution of aliases                 |                                               |
 * |---------------------------------------|-----------------------------------------------|
 * |                                       | Invalid arity of compositions                 |
 * |---------------------------------------|-----------------------------------------------|
 * | Resolution of compositions and flags  |                                               |
 * |=======================================|===============================================|
 *)
let process e =
    let trs = [
        error_transformation Errors.inclusion_errors;
        resolution_transformation Resolutions.resolve_inclusions;
        error_transformation Errors.invalid_identifier_errors;
        error_transformation Errors.undefined_alias_errors;
        resolution_transformation Resolutions.resolve_alias_definitions;
        error_transformation Errors.invalid_arity_composition_errors;
        resolution_transformation Resolutions.resolve_compositions_and_flags
    ] in
    let pr1 = {empty with expression = Some e} in
    let pr2 = trs |> List.fold_left apply_transformation pr1 in
    let s =
        if not (has_errors pr2) then Some (Evaluations.compute (expression pr2)) else None
    in
    {pr2 with sound = s}

(* Returns the preprocessing of the expression contained in the file at path path. *)
let process_path path =
    try
        process (Files.path_to_expression path)
    with
        |Lexer.Error err ->
            let errs = [Errors.syntax_error_from_lexer err] in
            {empty with errors = errs}

