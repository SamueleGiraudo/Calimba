(* Author: Samuele Giraudo
 * Creation: may 2021
 * Modifications: may 2021, jun. 2021, aug. 2021, nov. 2021, dec. 2021, jan. 2022,
 * mar. 2022, may 2022, aug. 2022
 *)

(* A preprocessing contains an option on a processed expression and a list of errors. When
 * this list of errors not empty, the option on the expression is None. *)
type preprocessing = {
    expression: Expression.expression option;
    errors: Error.error list;
}

(* An exception to handle cases where an expression has a inappropriate form. *)
exception ValueError

(* Returns an option on the expression of the preprocessing pp. *)
let expression pp =
    pp.expression

(* Returns the list of errors of the preprocessing pp. *)
let errors pp =
    pp.errors

(* Tests if the list of flags flags contains the flag fl when st is On, does not contain fl
 * when st is Off, or returns a coin flip if fl is Random. *)
let flag_test flags st fl =
    match st with
        |Expression.On -> List.mem fl flags
        |Expression.Off -> not (List.mem fl flags)
        |Expression.Random -> Random.int 2 = 1

(* Returns the list of flags obtained from the list of flags flags by adding the flag fl
 * when st is On, by suppressing fl when st is Off, or by adding or suppressing fl decided
 * by a coin flip. *)
let rec flag_modification flags st fl =
    match st with
        |Expression.On -> fl :: flags
        |Expression.Off -> flags |> List.filter (fun fl' -> fl' <> fl)
        |Expression.Random ->
            if Random.int 2 = 1 then
                flag_modification flags Expression.On fl
            else
                flag_modification flags Expression.Off fl

(* Returns the expression obtained by replacing all free occurrences of the alias alias in
 * the expression e1 by the expression e2. *)
let substitute_free_aliases e1 alias e2 =
    assert (Statistics.is_inclusion_free e1);
    assert (Statistics.is_inclusion_free e2);
    let rec aux e1 =
        match e1 with
            |Expression.Beat _ -> e1
            |Expression.CycleOperation (info, op, e1') ->
                Expression.CycleOperation (info, op, aux e1')
            |Expression.UnaryOperation (info, op, e1') ->
                Expression.UnaryOperation (info, op, aux e1')
            |Expression.BinaryOperation (info, op, e1', e2') ->
                Expression.BinaryOperation (info, op, aux e1', aux e2')
            |Expression.FlagTest (info, st, fl, e1', e2') ->
                Expression.FlagTest (info, st, fl, aux e1', aux e2')
            |Expression.FlagModification (info, st, fl, e1') ->
                Expression.FlagModification (info, st, fl, aux e1')
            |Expression.Composition (info, e1', e_lst) ->
                Expression.Composition (info, aux e1', e_lst |> List.map aux)
            |Expression.Alias (_, alias') -> if alias' = alias then e2 else e1
            |Expression.AliasDefinition (info, alias', e1', e2') ->
                let e2'' = if alias' = alias then e2' else aux e2' in
                Expression.AliasDefinition (info, alias', aux e1', e2'')
            |Expression.Put _ -> raise ValueError
    in
    aux e1

(* Returns the expression obtained by composing the expression e with the list e_lst of
 * expressions. This replaces each beat i of e by the i-th element of e_lst (starting from
 * 0). The expression e has to be inclusion and alias free. *)
let compose e e_lst =
    assert (Statistics.is_inclusion_free e);
    assert (Statistics.is_alias_free e);
    assert (Statistics.greatest_beat e = List.length e_lst);
    let rec aux e =
        match e with
            |Expression.Beat (_, i) -> List.nth e_lst (i - 1)
            |Expression.CycleOperation (info, op, e1) ->
                Expression.CycleOperation (info, op, aux e1)
            |Expression.UnaryOperation (info, op, e1) ->
                Expression.UnaryOperation (info, op, aux e1)
            |Expression.BinaryOperation (info, op, e1, e2) ->
                Expression.BinaryOperation (info, op, aux e1, aux e2)
            |Expression.FlagTest (info, st, fl, e1, e2) ->
                Expression.FlagTest (info, st, fl, aux e1, aux e2)
            |Expression.FlagModification (info, st, fl, e1) ->
                Expression.FlagModification (info, st, fl, aux e1)
            |Expression.Composition (info, e1, e_lst') ->
                Expression.Composition (info, e1, e_lst' |> List.map aux)
            |Expression.Alias _ |Expression.AliasDefinition _ |Expression.Put _ ->
                raise ValueError
    in
    aux e

(* Returns the expression obtained from the expression e by resolving its inclusions. The
 * expression e has to have no inclusion errors. *)
let resolve_inclusions e =
    assert (Error.inclusion_errors e = []);
    let rec aux e =
        match e with
            |Expression.Beat _ |Expression.Alias _ -> e
            |Expression.CycleOperation (info, op, e1) ->
                Expression.CycleOperation (info, op, aux e1)
            |Expression.UnaryOperation (info, op, e1) ->
                Expression.UnaryOperation (info, op, aux e1)
            |Expression.BinaryOperation (info, op, e1, e2) ->
                Expression.BinaryOperation (info, op, aux e1, aux e2)
            |Expression.FlagTest (info, st, fl, e1, e2) ->
                Expression.FlagTest (info, st, fl, aux e1, aux e2)
            |Expression.FlagModification (info, st, fl, e1) ->
                Expression.FlagModification (info, st, fl, aux e1)
            |Expression.AliasDefinition (info, alias, e1, e2) ->
                Expression.AliasDefinition (info, alias, aux e1, aux e2)
            |Expression.Composition (info, e1, e_lst) ->
                Expression.Composition (info, aux e1, e_lst |> List.map aux)
            |Expression.Put (_, path) ->
                let path' = Tools.simplify_path (File.add_file_extension path) in
                aux (File.path_to_expression path')
    in
    aux e

(* Returns the expression obtained by replacing all the aliases in the expression e by their
 * definitions. *)
let resolve_alias_definitions e =
    assert (Statistics.is_inclusion_free e);
    let rec aux e =
        match e with
            |Expression.Beat _ |Expression.Alias _  -> e
            |Expression.CycleOperation (info, op, e1') ->
                Expression.CycleOperation (info, op, aux e1')
            |Expression.UnaryOperation (info, op, e1) ->
                Expression.UnaryOperation (info, op, aux e1)
            |Expression.BinaryOperation (info, op, e1, e2) ->
                Expression.BinaryOperation (info, op, aux e1, aux e2)
            |Expression.FlagTest (info, st, fl, e1, e2) ->
                Expression.FlagTest (info, st, fl, aux e1, aux e2)
            |Expression.FlagModification (info, st, fl, e1) ->
                Expression.FlagModification (info, st, fl, aux e1)
            |Expression.AliasDefinition (_, alias, e1, e2) ->
                substitute_free_aliases (aux e2) alias (aux e1)
            |Expression.Composition (info, e1, e_lst) ->
                Expression.Composition (info, aux e1, e_lst |> List.map aux)
            |Expression.Put _ -> raise ValueError
    in
    aux e

(* Returns the expression obtained by resolving all the compositions and flags in the
 * expression e. This expression has to be inclusion free and alias free. *)
let resolve_compositions_and_flags e =
    assert (Statistics.is_inclusion_free e);
    assert (Statistics.is_alias_free e);
    let rec aux flags e =
        match e with
            |Expression.Beat _ -> e
            |Expression.CycleOperation (info, op, e1) ->
                Expression.CycleOperation (info, op, aux flags e1)
            |Expression.UnaryOperation (info, op, e1) ->
                Expression.UnaryOperation (info, op, aux flags e1)
            |Expression.BinaryOperation (info, op, e1, e2) ->
                Expression.BinaryOperation (info, op, aux flags e1, aux flags e2)
            |Expression.FlagTest (_, st, fl, e1, e2) ->
                if flag_test flags st fl then aux flags e1 else aux flags e2
            |Expression.FlagModification (_, st, fl, e1) ->
                aux (flag_modification flags st fl) e1
            |Expression.Composition (_, e1, e_lst) -> aux flags (compose e1 e_lst)
            |Expression.AliasDefinition _ |Expression.Alias _ |Expression.Put _ ->
                raise ValueError
    in
    aux [] e

(* Returns the preprocessing of the expression e (obtained by resolving inclusions, aliases,
 * and compositions and flags), and by constructing the list of errors in e.
 *
 * This follows the following steps:
 *
 * |=======================================|===============================================|
 * | Processing                            | Error detection                               |
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
 * |---------------------------------------|-----------------------------------------------|
 * |                                       | Invalid horizontal scaling values             |
 * |=======================================|===============================================|
 *)
let preprocess e =
    let res = {expression = None; errors = []} in
    let errs = Error.inclusion_errors e in
    if errs <> [] then
        {res with errors = errs}
    else
    let e1 = resolve_inclusions e in
    let errs = Error.invalid_identifier_errors e1 in
    if errs <> [] then
        {res with errors = errs}
    else
    let errs = Error.undefined_alias_errors e1 in
    if errs <> [] then
        {res with errors = errs}
    else
    let e2 = resolve_alias_definitions e1 in
    let errs = Error.invalid_arity_composition_errors e2 in
    if errs <> [] then
        {res with errors = errs}
    else
    let e3 = resolve_compositions_and_flags e2 in
    let errs = Error.invalid_horizontal_scaling_value_errors e3 in
    if errs <> [] then
        {res with errors = errs}
    else
    {res with expression = Some e3}

(* Returns the preprocessing of the expression contained in the file at path path. *)
let preprocess_path path =
    try
        preprocess (File.path_to_expression path)
    with
        |Lexer.Error err ->
            {expression = None; errors = [Error.syntax_error_from_lexer err]}

(* Returns the sound specified by the expression e. This expression has to be simple. *)
let sound e =
    assert (Statistics.is_simple e);
    let mem = ref PMap.empty in
    let rec aux freq e =
        let preimage = (freq, e) in
        if PMap.exists preimage !mem then
            PMap.find preimage !mem
        else
            let res =
                match e with
                    |Expression.Beat _ -> Sound.sinusoidal freq 1.0
                    |Expression.CycleOperation (_, op, e1) -> begin
                        match op with
                            |Expression.UpdateCycleNumber x -> aux (freq *. x) e1
                            |Expression.ResetCycleNumber -> aux 1.0 e1
                    end
                    |Expression.UnaryOperation (_, op, e1) -> begin
                        match op with
                            |Expression.VerticalScaling x ->
                                Sound.vertical_scaling x (aux freq e1)
                            |Expression.HorizontalScaling x ->
                                Sound.horizontal_scaling x (aux freq e1)
                    end
                    |Expression.BinaryOperation (_, op, e1, e2) -> begin
                        let s1 = aux freq e1 and s2 = aux freq e2 in
                        match op with
                            |Expression.Concatenation -> Sound.concatenate s1 s2
                            |Expression.Addition -> Sound.add s1 s2
                            |Expression.Multiplication -> Sound.multiply s1 s2
                    end
                    |Expression.FlagTest _ |Expression.FlagModification _
                    |Expression.Alias _ |Expression.AliasDefinition _
                    |Expression.Composition _ |Expression.Put _ ->
                        raise ValueError
            in
            mem := PMap.add preimage res !mem;
            res
    in
    aux 1.0 e

