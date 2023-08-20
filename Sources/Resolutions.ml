(* Author: Samuele Giraudo
 * Creation: (may 2021), jul. 2023
 * Modifications: jul. 2023
 *)

(* Returns the expression obtained by replacing all free occurrences of the alias alias in
 * the expression e1 by the expression e2. *)
let substitute_free_aliases e1 alias e2 =
    assert (Properties.is_inclusion_free e1);
    assert (Properties.is_inclusion_free e2);
    let rec aux e1 =
        match e1 with
            |Expressions.Beat _ -> e1
            |Expressions.CycleOperation (info, op, e1') ->
                Expressions.CycleOperation (info, op, aux e1')
            |Expressions.UnaryOperation (info, op, e1') ->
                Expressions.UnaryOperation (info, op, aux e1')
            |Expressions.BinaryOperation (info, op, e1', e2') ->
                Expressions.BinaryOperation (info, op, aux e1', aux e2')
            |Expressions.FlagTest (info, st, fl, e1', e2') ->
                Expressions.FlagTest (info, st, fl, aux e1', aux e2')
            |Expressions.FlagModification (info, st, fl, e1') ->
                Expressions.FlagModification (info, st, fl, aux e1')
            |Expressions.Composition (info, e1', e_lst) ->
                Expressions.Composition (info, aux e1', e_lst |> List.map aux)
            |Expressions.Alias (_, alias') -> if alias' = alias then e2 else e1
            |Expressions.AliasDefinition (info, alias', e1', e2') ->
                let e2'' = if alias' = alias then e2' else aux e2' in
                Expressions.AliasDefinition (info, alias', aux e1', e2'')
            |_ -> Expressions.ValueError (e1, "substitute_free_aliases") |> raise
    in
    aux e1

(* Returns the expression obtained by composing the expression e with the list e_lst of
 * expressions. This replaces each beat i of e by the i-th element of e_lst (starting from
 * 1). The expression e has to be inclusion and alias free. *)
let compose e e_lst =
    assert (Properties.is_inclusion_free e);
    assert (Properties.is_alias_free e);
    assert (Properties.greatest_beat_index e = List.length e_lst);
    let rec aux e =
        match e with
            |Expressions.Beat (_, b) -> List.nth e_lst (Beats.index b - 1)
            |Expressions.CycleOperation (info, op, e1) ->
                Expressions.CycleOperation (info, op, aux e1)
            |Expressions.UnaryOperation (info, op, e1) ->
                Expressions.UnaryOperation (info, op, aux e1)
            |Expressions.BinaryOperation (info, op, e1, e2) ->
                Expressions.BinaryOperation (info, op, aux e1, aux e2)
            |Expressions.FlagTest (info, st, fl, e1, e2) ->
                Expressions.FlagTest (info, st, fl, aux e1, aux e2)
            |Expressions.FlagModification (info, st, fl, e1) ->
                Expressions.FlagModification (info, st, fl, aux e1)
            |Expressions.Composition (info, e1, e_lst') ->
                Expressions.Composition (info, e1, e_lst' |> List.map aux)
            |_ -> Expressions.ValueError (e, "compose") |> raise
    in
    aux e

(* Returns the expression obtained from the expression e by resolving its inclusions. The
 * expression e has to have no inclusion errors. *)
let resolve_inclusions e =
    assert (Errors.inclusion_errors e = []);
    let rec aux e =
        match e with
            |Expressions.Beat _ |Expressions.Alias _ -> e
            |Expressions.CycleOperation (info, op, e1) ->
                Expressions.CycleOperation (info, op, aux e1)
            |Expressions.UnaryOperation (info, op, e1) ->
                Expressions.UnaryOperation (info, op, aux e1)
            |Expressions.BinaryOperation (info, op, e1, e2) ->
                Expressions.BinaryOperation (info, op, aux e1, aux e2)
            |Expressions.FlagTest (info, st, fl, e1, e2) ->
                Expressions.FlagTest (info, st, fl, aux e1, aux e2)
            |Expressions.FlagModification (info, st, fl, e1) ->
                Expressions.FlagModification (info, st, fl, aux e1)
            |Expressions.AliasDefinition (info, alias, e1, e2) ->
                Expressions.AliasDefinition (info, alias, aux e1, aux e2)
            |Expressions.Composition (info, e1, e_lst) ->
                Expressions.Composition (info, aux e1, e_lst |> List.map aux)
            |Expressions.Put (_, path) ->
                let path' = Paths.simplify (Files.add_file_extension path) in
                aux (Files.path_to_expression path')
    in
    aux e

(* Returns the expression obtained by replacing all the aliases in the expression e by their
 * definitions. *)
let resolve_alias_definitions e =
    assert (Properties.is_inclusion_free e);
    let rec aux e =
        match e with
            |Expressions.Beat _ |Expressions.Alias _  -> e
            |Expressions.CycleOperation (info, op, e1') ->
                Expressions.CycleOperation (info, op, aux e1')
            |Expressions.UnaryOperation (info, op, e1) ->
                Expressions.UnaryOperation (info, op, aux e1)
            |Expressions.BinaryOperation (info, op, e1, e2) ->
                Expressions.BinaryOperation (info, op, aux e1, aux e2)
            |Expressions.FlagTest (info, st, fl, e1, e2) ->
                Expressions.FlagTest (info, st, fl, aux e1, aux e2)
            |Expressions.FlagModification (info, st, fl, e1) ->
                Expressions.FlagModification (info, st, fl, aux e1)
            |Expressions.AliasDefinition (_, alias, e1, e2) ->
                substitute_free_aliases (aux e2) alias (aux e1)
            |Expressions.Composition (info, e1, e_lst) ->
                Expressions.Composition (info, aux e1, e_lst |> List.map aux)
            |_ -> Expressions.ValueError (e, "resolve_alias_definitions") |> raise
    in
    aux e

(* Returns the expression obtained by resolving all the compositions and flags in the
 * expression e. This expression has to be inclusion free and alias free. *)
let resolve_compositions_and_flags e =
    assert (Properties.is_inclusion_free e);
    assert (Properties.is_alias_free e);
    let rec aux flags e =
        match e with
            |Expressions.Beat _ -> e
            |Expressions.CycleOperation (info, op, e1) ->
                Expressions.CycleOperation (info, op, aux flags e1)
            |Expressions.UnaryOperation (info, op, e1) ->
                Expressions.UnaryOperation (info, op, aux flags e1)
            |Expressions.BinaryOperation (info, op, e1, e2) ->
                Expressions.BinaryOperation (info, op, aux flags e1, aux flags e2)
            |Expressions.FlagTest (_, st, fl, e1, e2) ->
                if Flags.test flags st fl then aux flags e1 else aux flags e2
            |Expressions.FlagModification (_, st, fl, e1) ->
                aux (Flags.modify flags st fl) e1
            |Expressions.Composition (_, e1, e_lst) -> aux flags (compose e1 e_lst)
            |_ -> Expressions.ValueError (e, "resolve_compositions_and_flags") |> raise
    in
    aux [] e

