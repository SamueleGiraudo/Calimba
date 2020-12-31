(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* A tree pattern is either a leaf (a silence or a beat) or the concatenation of two trees,
 * or the composition of two trees, or the modification of a tree. We see a tree pattern as
 * an element of a clone. Each beat is a valid sector for the substitution. *)
type tree =
    |Atom of Atom.atom
    |Concatenation of tree * tree
    |Composition of tree * tree
    |Performance of Performance.performance * tree
    |Effect of Effect.effect * tree

(* An exception to handle wrong partial compositions. *)
exception ValueError

(* Returns a string representation of the tree pattern t. *)
let rec to_string t =
    match t with
        |Atom a -> Atom.to_string a
        |Concatenation (t1, t2) -> Printf.sprintf "*(%s, %s)" (to_string t1) (to_string t2)
        |Composition (t1, t2) -> Printf.sprintf "#(%s, %s)" (to_string t1) (to_string t2)
        |Performance (_, t') -> Printf.sprintf "P(%s)" (to_string t')
        |Effect (_, t') -> Printf.sprintf "E(%s)" (to_string t')

(* Returns the number of leaves of the tree pattern t. *)
let rec nb_leaves t =
    match t with
        |Atom _ -> 1
        |Concatenation (t1, t2) |Composition (t1, t2) -> nb_leaves t1 + nb_leaves t2
        |Performance (_, t') |Effect (_, t') -> nb_leaves t'

(* Returns the number of internal nodes of the tree pattern t. *)
let rec nb_internal_nodes t =
    match t with
        |Atom _ -> 0
        |Concatenation (t1, t2) |Composition (t1, t2) ->
            1 + nb_internal_nodes t1 + nb_internal_nodes t2
        |Performance (_, t') |Effect (_, t') -> 1 + nb_internal_nodes t'

(* Returns the height of the tree pattern t. A tree consisting in a single atom has 0 as
 * height. *)
let rec height t =
    match t with
        |Atom _ -> 0
        |Concatenation (t1, t2) |Composition (t1, t2) -> 1 + max (height t1) (height t2)
        |Performance (_, t') |Effect (_, t') -> 1 + height t'

(* Returns the arity, that is the number of beats, of the tree pattern t. *)
let rec arity t =
    match t with
        |Atom a -> if Atom.is_beat a then 1 else 0
        |Concatenation (t1, t2) | Composition (t1, t2) -> arity t1 + arity t2
        |Performance (_, t') |Effect (_, t') -> arity t'

(* Returns the tree pattern obtained by applying the degree d and the time degree td on the
 * tree pattern ts. *)
let rec beat_action b t =
    match t with
        |Atom a -> Atom (Atom.product b a)
        |Concatenation (t1, t2) -> Concatenation (beat_action b t1, beat_action b t2)
        |Composition (t1, t2) -> Composition (beat_action b t1, beat_action b t2)
        |Performance (p, t') -> Performance (p, beat_action b t')
        |Effect (e, t') -> Effect (e, beat_action b t')

(* Returns the tree pattern obtained by replacing each beat having lbl as label of the tree
 * pattern t1 by the tree pattern t2. Each grafted version of t2 is modified by the action
 * of the replaced beat. *)
let rec label_composition t1 lbl t2 =
    match t1 with
        |Atom a -> begin
            match Atom.label a with
                |None -> t1
                |Some lbl' -> if lbl' = lbl then beat_action a t2 else t1
        end
        |Concatenation (t11, t12) ->
            let t11' = label_composition t11 lbl t2
            and t12' = label_composition t12 lbl t2 in
            Concatenation (t11', t12')
        |Composition (t11, t12) ->
            let t11' = label_composition t11 lbl t2
            and t12' = label_composition t12 lbl t2 in
            Composition (t11', t12')
        |Performance (p, t') -> Performance (p, label_composition t' lbl t2)
        |Effect (e, t') -> Effect (e, label_composition t' lbl t2)

(* Returns the tree pattern obtained by assigning the label lbl to each beat of the tree
 * pattern t. *)
let rec assign_label t lbl =
    match t with
        |Atom a -> Atom (Atom.assign_label a lbl)
        |Concatenation (t1, t2) ->
            let t1' = assign_label t1 lbl and t2' = assign_label t2 lbl in
            Concatenation (t1', t2')
        |Composition (t1, t2) ->
            let t1' = assign_label t1 lbl and t2' = assign_label t2 lbl in
            Composition (t1', t2')
        |Performance (p, t') -> Performance (p, assign_label t' lbl)
        |Effect (p, t') -> Effect (p, assign_label t' lbl)

(* Returns the tree pattern obtained by the binary composition of the tree patterns t1 and
 * t2. This performs a partial composition of t2 on each beat of t1. *)
let binary_composition t1 t2 =
    label_composition (assign_label t1 "") "" t2

(* Returns a tree pattern specifying the repetition of k times of the tree pattern t. *)
let repeat k t =
    assert (k >= 1);
    let t_lst = List.init (k - 1) (fun _ -> t) in
    t_lst |> List.fold_left (fun res t' -> Concatenation (res, t')) t

(* Returns a tree pattern specifying the reversion of the tree pattern t. *)
let rec reverse t =
    match t with
        |Atom _ -> t
        |Concatenation (t1, t2) -> Concatenation (reverse t2, reverse t1)
        |Composition (t1, t2) -> Composition (reverse t1, reverse t2)
        |Performance (p, t') -> Performance (p, reverse t')
        |Effect (e, t') -> Effect (e, reverse t')

(* Returns a tree pattern specifying the complement of the tree pattern t. This replaces
 * each degree of each beat by its complement. *)
let rec complement t =
    match t with
        |Atom a -> Atom (Atom.complement a)
        |Concatenation (t1, t2) -> Concatenation (complement t1, complement t2)
        |Composition (t1, t2) -> Composition (complement t1, complement t2)
        |Performance (p, t') -> Performance (p, complement t')
        |Effect (e, t') -> Effect (e, complement t')

(* Returns the sound specified by the tree pattern t. *)
let sound t =
    let rec aux p t =
        match t with
            |Atom a -> Performance.atom_to_sound p a
            |Concatenation (t1, t2) -> Sound.concatenate (aux p t1) (aux p t2)
            |Composition (t1, t2) -> Sound.add (aux p t1) (aux p t2)
            |Performance (p', t') -> aux p' t'
            |Effect (e', t') -> Effect.apply e' (aux p t')
    in
    aux Performance.empty t

