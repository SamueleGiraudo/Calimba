(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* A label is a name that a beat can optionally hold. *)
type label = string

(* An atom encodes an atomic unit of music. It can be either a silence or a beat. A beat can
 * have a label. *)
type atom =
    |Silence of TimeShapeShift.time_shape_shift
    |Beat of LayoutShift.layout_shift * TimeShapeShift.time_shape_shift * (label option)

(* A performance is a map saying how to associate with any atom a sound. *)
type performance = atom -> Sound.sound

(* An effect is a map transforming an input sound into an output one. It is important to
 * have a separate way to encode effects because one cannot put this information into a
 * performance. Indeed, a performance encodes how to send a single atom onto a sound while
 * in an effect, the whole sound resulting in the performance of several atoms may be
 * processed (for instance for delays). *)
type effect = Sound.sound -> Sound.sound

(* A tree pattern is either a leaf (a silence or a beat) or the concatenation of two trees,
 * or the composition of two trees, or the modification of a tree. We see a tree pattern
 * as an element of a clone. Each beat is a valid sector for the substitution. *)
type tree =
    |Atom of atom
    |Concatenation of tree * tree
    |Composition of tree * tree
    |Performance of performance * tree
    |Effect of effect * tree

(* An exception to handle wrong partial compositions. *)
exception ValueError

(* Returns an atom which is a silence lasting one unit of time. *)
let silence =
    Silence 0

(* Returns an atom which is a beat lasting one unit of time and of extended degree d. *)
let beat d =
    Beat ((LayoutShift.construct d 0), 0, None)

(* Returns an atom which is a labeled beat lasting one unit of time, of extended degree d,
 * and of label lbl. *)
let labeled_beat d lbl =
    Beat ((LayoutShift.construct d 0), 0, Some lbl)

(* Returns a string representation of the atom a. *)
let atom_to_string a =
    match a with
        |Silence tss -> TimeShapeShift.to_string tss
        |Beat (ls, tss, lbl) ->
            let str = Printf.sprintf "%s%s"
                (LayoutShift.to_string ls) (TimeShapeShift.to_string tss) in
            if Option.is_some lbl then
                Printf.sprintf "%s:%s" str (Option.get lbl)
            else
                str

(* Returns a string representation of the tree pattern t. *)
let rec to_string t =
    match t with
        |Atom a -> atom_to_string a
        |Concatenation (t1, t2) ->
            Printf.sprintf "*(%s, %s)" (to_string t1) (to_string t2)
        |Composition (t1, t2) ->
            Printf.sprintf "#(%s, %s)" (to_string t1) (to_string t2)
        |Performance (_, t') ->
            Printf.sprintf "P(%s)" (to_string t')
        |Effect (_, t') ->
            Printf.sprintf "E(%s)" (to_string t')

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
        |Atom (Silence _) -> 0
        |Atom (Beat _) -> 1
        |Concatenation (t1, t2) | Composition (t1, t2) -> arity t1 + arity t2
        |Performance (_, t') |Effect (_, t') -> arity t'

(* Returns the tree pattern obtained by applying the layout shift ls and the time shift ts
 * on the tree pattern ts. *)
let rec beat_action ls ts t =
    match t with
        |Atom (Silence ts') -> Atom (Silence (ts + ts'))
        |Atom (Beat (ls', ts', lbl)) -> Atom (Beat (LayoutShift.add ls ls', ts + ts', lbl))
        |Concatenation (t1, t2) ->
            Concatenation (beat_action ls ts t1, beat_action ls ts t2)
        |Composition (t1, t2) -> Composition (beat_action ls ts t1, beat_action ls ts t2)
        |Performance (p, t') -> Performance (p, beat_action ls ts t')
        |Effect (e, t') -> Effect (e, beat_action ls ts t')

(* Returns the operadic partial composition of the tree pattern t2 at i-th position into the
 * tree pattern t1. Beats are indexed from the left to the right. *)
let rec partial_composition t1 i t2 =
    match t1 with
        |Atom (Silence _) -> raise ValueError
        |Atom (Beat (s, ts, _)) ->
            if i = 1 then
                beat_action s ts t2
            else
                raise ValueError
        |Concatenation (t11, t12) ->
            let ar = arity t11 in
            if i <= ar then
                Concatenation (partial_composition t11 i t2, t12)
            else
                Concatenation (t11, partial_composition t12 (i - ar) t2)
        |Composition (t11, t12) ->
            let ar = arity t11 in
            if i <= ar then
                Composition (partial_composition t11 i t2, t12)
            else
                Composition (t11, partial_composition t12 (i - ar) t2)
        |Performance (p, t') -> Performance (p, partial_composition t' i t2)
        |Effect (e, t') -> Effect (e, partial_composition t' i t2)

(* Returns the partial composition of the tree pattern t2 into the tree pattern t1 at i-it
 * position if i is a valid integer. Otherwise, returns t1. *)
let extended_partial_composition t1 i t2 =
    if 1 <= i && i <= arity t1 then
        partial_composition t1 i t2
    else
        t1

(* Returns the tree pattern obtained by replacing each beat having lbl as label of the tree
 * pattern t1 by the tree pattern t2. Each grafted version of t2 is modified by the action
 * of the replaced beat. *)
let rec label_composition t1 lbl t2 =
    match t1 with
        |Atom (Silence _) |Atom (Beat (_, _, None)) -> t1
        |Atom (Beat (s, ts, Some lbl')) ->
            if lbl' = lbl then
                beat_action s ts t2
            else
                t1
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

(* Returns the tree pattern obtained by the full composition of the tree pattern t with the
 * tree patterns of the list t_lst. This list has to have as length the arity of t. *)
let full_composition t t_lst =
    assert (arity t >= List.length t_lst);
    let with_i = List.combine (List.init (List.length t_lst) (fun x -> x + 1)) t_lst in
    with_i |> List.rev |> List.fold_left (fun res (i, t') -> partial_composition res i t') t

(* Returns the tree pattern obtained by the binary composition of the tree patterns t1 and
 * t2. This performs a partial composition of t2 on each beat of t1. *)
let binary_composition t1 t2 =
    let t_lst = List.init (arity t1) (fun _ -> t2) in
    full_composition t1 t_lst

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

(* Returns a tree pattern specifying the complementation of the tree pattern t. This
 * replaces each shift of each beat by its complement. *)
let rec complement t =
    match t with
        |Atom (Silence _) -> t
        |Atom (Beat (ls, ts, lbl)) -> Atom (Beat (LayoutShift.complement ls, ts, lbl))
        |Concatenation (t1, t2) -> Concatenation (complement t1, complement t2)
        |Composition (t1, t2) -> Composition (complement t1, complement t2)
        |Performance (p, t') -> Performance (p, complement t')
        |Effect (e, t') -> Effect (e, complement t')

(* Returns the sound specified by the tree pattern t. *)
let sound t =
    let rec aux p t =
        match t with
            |Atom a -> p a
            |Concatenation (t1, t2) -> Sound.concatenate (aux p t1) (aux p t2)
            |Composition (t1, t2) -> Sound.add (aux p t1) (aux p t2)
            |Performance (p', t') -> aux p' t'
            |Effect (e', t') -> e' (aux p t')
    in
    aux (fun _ -> Sound.silence 0) t

