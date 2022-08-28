(* Author: Samuele Giraudo
 * Creation: (mau 2021), may 2022
 * Modifications: may 2022, aug. 2022
 *)

(* The different kinds of errors a Calimba program can contain. *)
type error_kind =
    |InvalidAlias of Expression.alias
    |InvalidBeat of Expression.beat
    |InvalidFlag of Expression.flag
    |InvalidInclusionPath of Expression.path
    |UndefinedAlias of Expression.alias
    |InvalidHorizontalScalingValue of Expression.value
    |InvalidArityComposition of Expression.beat * Expression.beat
    |CircularInclusion of Expression.path
    |SyntaxError of Lexer.error_kind

(* The type to represent information about an error. *)
type error = {

    (* The kind of the error. *)
    kind: error_kind;

    (* Some information about the subexpression where the error appears. *)
    information: Information.information
}

(* An exception to handle cases where an expression has a inappropriate form. *)
exception ValueError

(* Returns the error obtained from the lexer error err. The kind of the returned error is
 * SyntaxError. *)
let syntax_error_from_lexer err =
    let kind = SyntaxError (Lexer.error_to_error_kind err) in
    let info = Information.construct (Lexer.error_to_position err) in
    {kind = kind; information = info}

(* Returns a string representation of the error err. *)
let to_string err =
    Information.to_string err.information ^ ": " ^
    match err.kind with
        |InvalidAlias alias -> Printf.sprintf "invalid alias %s" alias
        |InvalidBeat i -> Printf.sprintf "invalid beat %d" i;
        |InvalidFlag fl -> Printf.sprintf "invalid flag $%s" fl;
        |InvalidInclusionPath path -> Printf.sprintf "path %s is invalid for inclusion" path
        |UndefinedAlias alias -> Printf.sprintf "undefined alias %s" alias
        |InvalidHorizontalScalingValue x ->
            Printf.sprintf "invalid horizontal scaling value %g" x
        |InvalidArityComposition (n, n') ->
            Printf.sprintf "composition expects %d argument(s) instead of %d" n n'
        |CircularInclusion path -> Printf.sprintf "circular inclusion involving %s" path
        |SyntaxError err -> Lexer.error_kind_to_string err

(* Returns the list of the inclusion errors in the expression e and recursively in the
 * expressions of the included Calimba files. *)
let inclusion_errors e =
    let rec aux paths e =
        match e with
            |Expression.Beat _ |Expression.Alias _ -> []
            |Expression.CycleOperation (_, _, e1) |Expression.UnaryOperation (_, _, e1)
            |Expression.FlagModification (_, _, _, e1) ->
                aux paths e1
            |Expression.BinaryOperation (_, _, e1, e2)
            |Expression.AliasDefinition (_, _, e1, e2)
            |Expression.FlagTest (_, _, _, e1, e2) ->
                List.append (aux paths e1) (aux paths e2)
            |Expression.Composition (_, e1, e_lst) ->
                List.append (aux paths e1) (e_lst |> List.map (aux paths) |> List.flatten)
            |Expression.Put (info, path) ->
                let path = File.add_file_extension path in
                if not (Sys.file_exists path) || not (File.is_inclusion_path path) then
                    [{kind = InvalidInclusionPath path; information = info}]
                else
                    let path' = Tools.simplify_path path in
                    if List.mem path' paths then
                        []
                    else
                        try
                            let e0 = File.path_to_expression path' in
                            let paths' = path' :: paths in
                            if List.mem path' (File.included_paths e0) then
                                [{kind = CircularInclusion path'; information = info}]
                            else
                                aux paths' e0
                        with
                            |Lexer.Error err -> [syntax_error_from_lexer err]
    in
    aux [] e |> List.sort_uniq compare

(* Returns the list of the invalid identifiers in the expression e. This expression has to
 * be inclusion free. *)
let invalid_identifier_errors e =
    assert (Statistics.is_inclusion_free e);
    let rec aux e =
        match e with
            |Expression.Beat (info, i) ->
                if File.is_beat i then
                    []
                else
                    [{kind = InvalidBeat i; information = info}]
            |Expression.CycleOperation (_, _, e1)
            |Expression.UnaryOperation (_, _, e1) ->
                aux e1
            |Expression.BinaryOperation (_, _, e1, e2) -> List.append (aux e1) (aux e2)
            |Expression.FlagTest (info, _, fl, e1, e2) ->
                let tmp = List.append (aux e1) (aux e2) in
                if File.is_flag fl then
                    tmp
                else
                    {kind = InvalidFlag fl; information = info} :: tmp
            |Expression.FlagModification (info, _, fl, e1) ->
                let tmp = aux e1 in
                if File.is_flag fl then
                    tmp
                else
                    {kind = InvalidFlag fl; information = info} :: tmp
            |Expression.Composition (_, e1, e_lst) ->
                List.append (aux e1) (e_lst |> List.map aux |> List.flatten)
            |Expression.Alias (info, alias) ->
                if File.is_alias alias then
                    []
                else
                    [{kind = InvalidAlias alias; information = info}]
            |Expression.AliasDefinition (info, alias, e1, e2) ->
                let tmp = List.append (aux e1) (aux e2) in
                if File.is_alias alias then
                    tmp
                else
                    {kind = InvalidAlias alias; information = info} :: tmp
            |Expression.Put _ -> raise ValueError
    in
    aux e |> List.sort_uniq compare

(* Returns the list of the errors about the undefined aliases in the expression e. This
* expression has to be inclusion free. *)
let undefined_alias_errors e =
    assert (Statistics.is_inclusion_free e);
    let rec aux e =
        match e with
            |Expression.Beat _ -> []
            |Expression.CycleOperation (_, _, e1) |Expression.UnaryOperation (_, _, e1)
            |Expression.FlagModification (_, _, _, e1) ->
                aux e1
            |Expression.BinaryOperation (_, _, e1, e2)
            |Expression.FlagTest (_, _, _, e1, e2) ->
                List.append (aux e1) (aux e2)
            |Expression.Composition (_, e1, e_lst) ->
                List.append (aux e1) (e_lst |> List.map aux |> List.flatten)
            |Expression.Alias (info, alias) -> [(alias, info)]
            |Expression.AliasDefinition (_, alias, e1, e2) ->
                List.append
                    (aux e1)
                    (aux e2 |> List.filter (fun (alias', _) -> alias' <> alias))
            |Expression.Put _ -> raise ValueError
    in
    aux e
        |> List.map (fun (alias, info) -> {kind = UndefinedAlias alias; information = info})
        |> List.sort_uniq compare

(* Returns the list of the errors about the invalid compositions w.r.t. the arity of the
 * left-hand members in the expression e. This expression has to be inclusion free and
 * alias free. *)
let invalid_arity_composition_errors e =
    assert (Statistics.is_inclusion_free e);
    assert (Statistics.is_alias_free e);
    let rec aux e =
        match e with
            |Expression.Beat _ -> []
            |Expression.CycleOperation (_, _, e1)
            |Expression.FlagModification (_, _, _, e1)
            |Expression.UnaryOperation (_, _, e1) ->
                aux e1
            |Expression.BinaryOperation (_, _, e1, e2)
            |Expression.FlagTest (_, _, _, e1, e2) ->
                List.append (aux e1) (aux e2)
            |Expression.Composition (info, e1, e_lst) ->
                let n = Statistics.greatest_beat e1 and n' = List.length e_lst in
                let tmp = List.append (aux e1) (e_lst |> List.map aux |> List.flatten) in
                if n <> n' then
                    {kind = InvalidArityComposition (n, n'); information = info} :: tmp
                else
                    tmp
            |Expression.Alias _ |Expression.AliasDefinition _ |Expression.Put _ ->
                raise ValueError
    in
    aux e |> List.sort_uniq compare

(* Returns the list of the errors about the invalid horizontal scaling values in the
 * expression e. This expression has to be simple. *)
let invalid_horizontal_scaling_value_errors e =
    assert (Statistics.is_simple e);
    let rec aux e =
        match e with
            |Expression.Beat _ -> []
            |Expression.CycleOperation (_, _, e1)
            |Expression.FlagModification (_, _, _, e1) ->
                aux e1
            |Expression.UnaryOperation (info, op, e1) -> begin
                let tmp = aux e1 in
                match op with
                    |Expression.HorizontalScaling x when x < 0.0 ->
                        {kind = InvalidHorizontalScalingValue x; information = info} :: tmp
                    |_ -> tmp
            end
            |Expression.BinaryOperation (_, _, e1, e2)
            |Expression.FlagTest (_, _, _, e1, e2) ->
                List.append (aux e1) (aux e2)
            |Expression.Composition _ |Expression.Alias _ |Expression.AliasDefinition _
            |Expression.Put _ ->
                raise ValueError
    in
    aux e |> List.sort_uniq compare

