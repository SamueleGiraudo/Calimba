(* Author: Samuele Giraudo
 * Creation: may 2022
 * Modifications: may 2022, aug. 2022
 *)

(* A type to collect some statistics about an expression. *)
type statistics = {
    nb_beats: int;
    nb_update_cycle_numbers: int;
    nb_reset_cycle_numbers: int;
    nb_vertical_scalings: int;
    nb_horizontal_scalings: int;
    nb_concatenations: int;
    nb_additions: int;
    nb_multiplications: int;
    nb_flag_tests: int;
    nb_flag_modifications: int;
    nb_compositions: int;
    nb_aliases: int;
    nb_alias_definitions: int;
    nb_puts: int;
    height: int;
    greatest_beat: int
}

(* Returns a string representation of the statistics st. *)
let to_string st =
     let string_if condition str =
        if condition then
            str
        else
            ""
    in
    let nb_internal_nodes =
        st.nb_update_cycle_numbers + st.nb_reset_cycle_numbers + st.nb_vertical_scalings
        + st.nb_horizontal_scalings + st.nb_concatenations + st.nb_additions
        + st.nb_multiplications
    in
    string_if (st.nb_beats >= 1)
        (Printf.sprintf "Nb. beats:                %d\n" st.nb_beats)
    ^
    Printf.sprintf "Nb. int. nodes:           %d\n" nb_internal_nodes
    ^
    string_if (st.nb_update_cycle_numbers >= 1)
        (Printf.sprintf "    Nb. cycles sca.:      %d\n" st.nb_update_cycle_numbers)
    ^
    string_if (st.nb_reset_cycle_numbers >= 1)
        (Printf.sprintf "    Nb. reset cycle num.: %d\n" st.nb_reset_cycle_numbers)
    ^
    string_if (st.nb_vertical_scalings >= 1)
        (Printf.sprintf "    Nb. vert. sca.:       %d\n" st.nb_vertical_scalings)
    ^
    string_if (st.nb_horizontal_scalings >= 1)
        (Printf.sprintf "    Nb. horiz. sca.:      %d\n" st.nb_horizontal_scalings)
    ^
    string_if (st.nb_concatenations >= 1)
        (Printf.sprintf "    Nb. conc.:            %d\n" st.nb_concatenations)
    ^
    string_if (st.nb_additions >= 1)
        (Printf.sprintf "    Nb. add.:             %d\n" st.nb_additions)
    ^
    string_if (st.nb_multiplications >= 1)
        (Printf.sprintf "    Nb. mul.:             %d\n" st.nb_multiplications)
    ^
    string_if (st.nb_flag_tests >= 1)
        (Printf.sprintf "    Nb. flag tests.:      %d\n" st.nb_flag_tests)
    ^
    string_if (st.nb_flag_modifications >= 1)
        (Printf.sprintf "    Nb. flag mod.:        %d\n" st.nb_flag_modifications)
    ^
    string_if (st.nb_compositions >= 1)
        (Printf.sprintf "    Nb. compo.:           %d\n" st.nb_compositions)
    ^
    string_if (st.nb_aliases >= 1)
        (Printf.sprintf "    Nb. aliases.:         %d\n" st.nb_aliases)
    ^
    string_if (st.nb_alias_definitions >= 1)
        (Printf.sprintf "    Nb. alias def.:       %d\n" st.nb_alias_definitions)
    ^
    string_if (st.nb_puts >= 1)
        (Printf.sprintf "    Nb. puts:             %d\n" st.nb_puts)
    ^
    Printf.sprintf "Height:                   %d\n" st.height
    ^
    Printf.sprintf "Greatest beat:            %d\n" st.greatest_beat

(* Returns the empty statistics. *)
let empty =
    {nb_beats = 0;
    nb_update_cycle_numbers = 0;
    nb_reset_cycle_numbers = 0;
    nb_vertical_scalings = 0;
    nb_horizontal_scalings = 0;
    nb_concatenations = 0;
    nb_additions = 0;
    nb_multiplications = 0;
    nb_flag_tests = 0;
    nb_flag_modifications = 0;
    nb_compositions = 0;
    nb_aliases = 0;
    nb_alias_definitions = 0;
    nb_puts = 0;
    height = 0;
    greatest_beat = 0}

(* Returns the statistics obtained by merging the statistics st1 and st2. *)
let merge st1 st2 =
    {nb_beats = st1.nb_beats + st2.nb_beats;
    nb_update_cycle_numbers = st1.nb_update_cycle_numbers + st2.nb_update_cycle_numbers;
    nb_reset_cycle_numbers = st1.nb_reset_cycle_numbers + st2.nb_reset_cycle_numbers;
    nb_vertical_scalings = st1.nb_vertical_scalings + st2.nb_vertical_scalings;
    nb_horizontal_scalings = st1.nb_horizontal_scalings + st2.nb_horizontal_scalings;
    nb_concatenations = st1.nb_concatenations + st2.nb_concatenations;
    nb_additions = st1.nb_additions + st2.nb_additions;
    nb_multiplications = st1.nb_multiplications + st2.nb_multiplications;
    nb_flag_tests = st1.nb_flag_tests + st2.nb_flag_tests;
    nb_flag_modifications = st1.nb_flag_modifications + st2.nb_flag_modifications;
    nb_compositions = st1.nb_compositions + st2.nb_compositions;
    nb_aliases = st1.nb_aliases + st2.nb_aliases;
    nb_alias_definitions = st1.nb_alias_definitions + st2.nb_alias_definitions;
    nb_puts = st1.nb_puts + st2.nb_puts;
    height = max st1.height st2.height;
    greatest_beat = max st1.greatest_beat st2.greatest_beat}

(* Returns the statistics collected from the expression e. *)
let rec compute e =
    match e with
        |Expression.Beat (_, i) -> {empty with nb_beats = 1; greatest_beat = i}
        |Expression.CycleOperation (_, Expression.UpdateCycleNumber _, e1) ->
            let st1 = compute e1 in
            {st1 with
                nb_update_cycle_numbers = 1 + st1.nb_update_cycle_numbers;
                height = 1 + st1.height}
        |Expression.CycleOperation (_, Expression.ResetCycleNumber, e1) ->
            let st1 = compute e1 in
            {st1 with
                nb_reset_cycle_numbers = 1 + st1.nb_reset_cycle_numbers;
                height = 1 + st1.height}
        |Expression.UnaryOperation (_, Expression.VerticalScaling _, e1) ->
            let st1 = compute e1 in
            {st1 with
                nb_vertical_scalings = 1 + st1.nb_vertical_scalings;
                height = 1 + st1.height}
        |Expression.UnaryOperation (_, Expression.HorizontalScaling _, e1) ->
            let st1 = compute e1 in
            {st1 with
                nb_horizontal_scalings = 1 + st1.nb_horizontal_scalings;
                height = 1 + st1.height}
        |Expression.BinaryOperation (_, Expression.Concatenation, e1, e2) ->
            let st1 = compute e1 and st2 = compute e2 in
            let st = merge st1 st2 in
            {st with
                nb_concatenations = 1 + st.nb_concatenations;
                height = 1 + st.height}
        |Expression.BinaryOperation (_, Expression.Addition, e1, e2) ->
            let st1 = compute e1 and st2 = compute e2 in
            let st = merge st1 st2 in
            {st with
                nb_additions = 1 + st.nb_additions;
                height = 1 + st.height}
        |Expression.BinaryOperation (_, Expression.Multiplication, e1, e2) ->
            let st1 = compute e1 and st2 = compute e2 in
            let st = merge st1 st2 in
            {st with
                nb_multiplications = 1 + st.nb_multiplications;
                height = 1 + st.height}
        |Expression.FlagTest (_, _, _, e1, e2) ->
            let st1 = compute e1 and st2 = compute e2 in
            let st = merge st1 st2 in
            {st with
                nb_flag_tests = 1 + st.nb_flag_tests;
                height = 1 + st.height}
        |Expression.FlagModification (_, _, _, e1) ->
            let st1 = compute e1 in
            {st1 with
                nb_flag_modifications = 1 + st1.nb_flag_modifications;
                height = 1 + st1.height}
        |Expression.Alias _ -> {empty with nb_aliases = 1}
        |Expression.AliasDefinition (_, _, e1, e2) ->
            let st1 = compute e1 and st2 = compute e2 in
            let st = merge st1 st2 in
            {st with
                nb_alias_definitions = 1 + st.nb_alias_definitions;
                height = 1 + st.height}
        |Expression.Composition (_, e1, e_lst) ->
            let st1 = compute e1 and st_lst = e_lst |> List.map compute in
            let st = st_lst |> List.fold_left merge st1 in
            {st with
                nb_compositions = 1 + st.nb_compositions;
                height = 1 + st.height}
        |Expression.Put _ -> {empty with nb_puts = 1}

(* Tests if there are no inclusions in the expression e. *)
let is_inclusion_free e =
    let st = compute e in
    st.nb_puts = 0

(* Tests if there are no alias uses in the expression e. This expression has to be inclusion
 * free. *)
let is_alias_free e =
    assert (is_inclusion_free e);
    let st = compute e in
    st.nb_aliases = 0 && st.nb_alias_definitions = 0

(* Tests if there are no compositions in the expression e. This expression has to be
 * inclusion and alias free. *)
let is_composition_free e =
    assert (is_inclusion_free e);
    assert (is_alias_free e);
    let st = compute e in
    st.nb_compositions = 0

(* Tests if there are no flags in the expression e. This expression has to be inclusion,
* alias, and composition free. *)
let is_flag_free e =
    assert (is_inclusion_free e);
    assert (is_alias_free e);
    assert (is_composition_free e);
    let st = compute e in
    st.nb_flag_tests = 0 && st.nb_flag_modifications = 0

(* Tests if the expression e is simple. This is the case if there is no flags, no
 * compositions, no aliases, and no inclusions in e. *)
let is_simple e =
    is_inclusion_free e && is_alias_free e && is_composition_free e && is_flag_free e

(* Returns the greatest beat in the expression e. *)
let greatest_beat e =
    let st = compute e in
    st.greatest_beat

