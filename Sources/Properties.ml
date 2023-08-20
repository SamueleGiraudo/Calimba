(* Author: Samuele Giraudo
 * Creation: (may 2022), nov. 2022
 * Modifications: (may 2022, aug. 2022), nov. 2022, jul. 2023
 *)

(* Tests if there are no inclusions in the expression e. *)
let is_inclusion_free e =
    let st = Statistics.compute e in
    Statistics.nb_puts st = 0

(* Tests if there are no alias uses in the expression e. This expression has to be inclusion
 * free. *)
let is_alias_free e =
    assert (is_inclusion_free e);
    let st = Statistics.compute e in
    Statistics.nb_aliases st = 0 && Statistics.nb_alias_definitions st = 0

(* Tests if there are no compositions in the expression e. This expression has to be
 * inclusion and alias free. *)
let is_composition_free e =
    assert (is_inclusion_free e);
    assert (is_alias_free e);
    let st = Statistics.compute e in
    Statistics.nb_compositions st = 0

(* Tests if there are no flags in the expression e. This expression has to be inclusion,
* alias, and composition free. *)
let is_flag_free e =
    assert (is_inclusion_free e);
    assert (is_alias_free e);
    assert (is_composition_free e);
    let st = Statistics.compute e in
    Statistics.nb_flag_tests st = 0 && Statistics.nb_flag_modifications st = 0

(* Tests if the expression e is simple. This is the case if there is no flags, no
 * compositions, no aliases, and no inclusions in e. *)
let is_simple e =
    is_inclusion_free e && is_alias_free e && is_composition_free e && is_flag_free e

(* Returns the greatest beat index in the expression e. *)
let greatest_beat_index e =
    let st = Statistics.compute e in
    Statistics.greatest_beat_index st

