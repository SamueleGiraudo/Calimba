(* Author: Samuele Giraudo
 * Creation: (mau 2021), may 2022
 * Modifications: may 2022, aug. 2022, nov. 2022, jul. 2023
 *)

(* The different kinds of errors a Calimba program can contain. *)
type kinds =
    |InvalidAlias of Expressions.aliases
    |InvalidBeat of Beats.beats
    |InvalidFlag of Flags.flags
    |InvalidInclusionPath of Expressions.paths
    |UndefinedAlias of Expressions.aliases
    |InvalidHorizontalScalingValue of Scalars.scalars
    |InvalidArityComposition of int * int
    |CircularInclusion of Expressions.paths
    |SyntaxError of Lexer.error_kinds

(* The type to represent information about an error. *)
type errors = {
    (* The kind of the error. *)
    kind: kinds;

    (* Information about the subexpression where the error appears. *)
    information: Information.information
}

(* Returns the error obtained from the lexer error err. The kind of the returned error is
 * SyntaxError. *)
let syntax_error_from_lexer err =
    let info = Information.construct (Lexer.error_to_position err) in
    let kind = SyntaxError (Lexer.error_to_error_kind err) in
    {information = info; kind = kind}

(* Returns a string representation of the error err. *)
let to_string err =
    Information.to_string err.information ^ ": " ^
    match err.kind with
        |InvalidAlias alias -> Printf.sprintf "invalid alias %s" alias
        |InvalidBeat b -> Printf.sprintf "invalid beat %s" (Beats.to_string b);
        |InvalidFlag fl -> Printf.sprintf "invalid flag $%s" (Flags.to_string fl);
        |InvalidInclusionPath path -> Printf.sprintf "path %s is invalid for inclusion" path
        |UndefinedAlias alias -> Printf.sprintf "undefined alias %s" alias
        |InvalidHorizontalScalingValue x ->
            Printf.sprintf "invalid horizontal scaling value %s" (Scalars.to_string x)
        |InvalidArityComposition (n, n') ->
            Printf.sprintf "composition expects %d argument(s) instead of %d" n n'
        |CircularInclusion path -> Printf.sprintf "circular inclusion involving %s" path
        |SyntaxError err -> Lexer.error_kind_to_string err

(* Returns the list of the inclusion errors in the expression e and recursively in the
 * expressions of the included Calimba files. *)
let inclusion_errors e =
    let rec aux paths e =
        match e with
            |Expressions.Beat _ |Expressions.Alias _ -> []
            |Expressions.CycleOperation (_, _, e1) |Expressions.UnaryOperation (_, _, e1)
            |Expressions.FlagModification (_, _, _, e1) ->
                aux paths e1
            |Expressions.BinaryOperation (_, _, e1, e2)
            |Expressions.AliasDefinition (_, _, e1, e2)
            |Expressions.FlagTest (_, _, _, e1, e2) ->
                List.append (aux paths e1) (aux paths e2)
            |Expressions.Composition (_, e1, e_lst) ->
                List.append (aux paths e1) (e_lst |> List.map (aux paths) |> List.flatten)
            |Expressions.Put (info, path) ->
                let path = Files.add_file_extension path |> Paths.simplify in
                if not (Sys.file_exists path) || not (Files.is_inclusion_path path) then
                    [{kind = InvalidInclusionPath path; information = info}]
                else
                    if List.mem path paths then
                        []
                    else
                        try
                            let e0 = Files.path_to_expression path in
                            let paths' = path :: paths in
                            if List.mem path (Files.included_paths e0) then
                                [{kind = CircularInclusion path; information = info}]
                            else
                                aux paths' e0
                        with
                            |Lexer.Error err -> [syntax_error_from_lexer err]
    in
    aux [] e |> List.sort_uniq compare

(* Returns the list of the invalid identifiers in the expression e. This expression has to
 * be inclusion free. *)
let invalid_identifier_errors e =
    assert (Properties.is_inclusion_free e);
    let rec aux e =
        match e with
            |Expressions.Beat (info, b) ->
                if Files.is_beat_index (Beats.index b) then
                    []
                else
                    [{kind = InvalidBeat b; information = info}]
            |Expressions.CycleOperation (_, _, e1)
            |Expressions.UnaryOperation (_, _, e1) ->
                aux e1
            |Expressions.BinaryOperation (_, _, e1, e2) -> List.append (aux e1) (aux e2)
            |Expressions.FlagTest (info, _, fl, e1, e2) ->
                let tmp = List.append (aux e1) (aux e2) in
                if Files.is_flag_name (Flags.name fl) then
                    tmp
                else
                    {kind = InvalidFlag fl; information = info} :: tmp
            |Expressions.FlagModification (info, _, fl, e1) ->
                let tmp = aux e1 in
                if Files.is_flag_name (Flags.name fl) then
                    tmp
                else
                    {kind = InvalidFlag fl; information = info} :: tmp
            |Expressions.Composition (_, e1, e_lst) ->
                List.append (aux e1) (e_lst |> List.map aux |> List.flatten)
            |Expressions.Alias (info, alias) ->
                if Files.is_alias alias then
                    []
                else
                    [{kind = InvalidAlias alias; information = info}]
            |Expressions.AliasDefinition (info, alias, e1, e2) ->
                let tmp = List.append (aux e1) (aux e2) in
                if Files.is_alias alias then
                    tmp
                else
                    {kind = InvalidAlias alias; information = info} :: tmp
            |_ -> Expressions.ValueError (e, "invalid_identifier_errors") |> raise
    in
    aux e |> List.sort_uniq compare

(* Returns the list of the errors about the undefined aliases in the expression e. This
* expression has to be inclusion free. *)
let undefined_alias_errors e =
    assert (Properties.is_inclusion_free e);
    let rec aux e =
        match e with
            |Expressions.Beat _ -> []
            |Expressions.CycleOperation (_, _, e1) |Expressions.UnaryOperation (_, _, e1)
            |Expressions.FlagModification (_, _, _, e1) ->
                aux e1
            |Expressions.BinaryOperation (_, _, e1, e2)
            |Expressions.FlagTest (_, _, _, e1, e2) ->
                List.append (aux e1) (aux e2)
            |Expressions.Composition (_, e1, e_lst) ->
                List.append (aux e1) (e_lst |> List.map aux |> List.flatten)
            |Expressions.Alias (info, alias) -> [(alias, info)]
            |Expressions.AliasDefinition (_, alias, e1, e2) ->
                List.append
                    (aux e1)
                    (aux e2 |> List.filter (fun (alias', _) -> alias' <> alias))
            |_ -> Expressions.ValueError (e, "undefined_alias_errors") |> raise
    in
    aux e
        |> List.map (fun (alias, info) -> {kind = UndefinedAlias alias; information = info})
        |> List.sort_uniq compare

(* Returns the list of the errors about the invalid compositions w.r.t. the arity of the
 * left-hand members in the expression e. This expression has to be inclusion free and
 * alias free. *)
let invalid_arity_composition_errors e =
    assert (Properties.is_inclusion_free e);
    assert (Properties.is_alias_free e);
    let rec aux e =
        match e with
            |Expressions.Beat _ -> []
            |Expressions.CycleOperation (_, _, e1)
            |Expressions.FlagModification (_, _, _, e1)
            |Expressions.UnaryOperation (_, _, e1) ->
                aux e1
            |Expressions.BinaryOperation (_, _, e1, e2)
            |Expressions.FlagTest (_, _, _, e1, e2) ->
                List.append (aux e1) (aux e2)
            |Expressions.Composition (info, e1, e_lst) ->
                let n = Properties.greatest_beat_index e1 and n' = List.length e_lst in
                let tmp = List.append (aux e1) (e_lst |> List.map aux |> List.flatten) in
                if n <> n' then
                    {kind = InvalidArityComposition (n, n'); information = info} :: tmp
                else
                    tmp
            |_ -> Expressions.ValueError (e, "invalid_arity_composition_errors") |> raise
    in
    aux e |> List.sort_uniq compare

