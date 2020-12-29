(* Author: Samuele Giraudo
 * Creation: (jul. 2015), may 2020
 * Modifications: may 2020, dec. 2020
 *)

(* A rooted layout is a layout together with a root note. This root is put in correspondence
 * with the note of degree 0. In this way, a rooted layout specifies an infinite  set of
 * notes, each indexed by its degree. *)
type rooted_layout = {
    (* The layout. *)
    layout : Layout.layout;

    (* The root note. This note is put in correspondence with the note of degree zero. *)
    root : Note.note
}

(* Tests if rl is a rooted layout. *)
let is_valid rl =
    Layout.is_valid rl.layout && Note.is_valid rl.root
        && Layout.nb_steps_by_octave rl.layout = Note.nb_steps_by_octave rl.root

(* Returns the rooted layout with the specified attributes. *)
let construct layout root =
    let rl = {layout = layout; root = root} in
    assert (is_valid rl);
    rl

(* Returns a string representation of the rooted layout rl. For instance,
 * "9/12:1 - 3 2 2 3 2" is the string representation of a rooted layout. *)
let to_string rl =
    assert (is_valid rl);
    Printf.sprintf "%s - %s" (Note.to_string rl.root) (Layout.to_string rl.layout)

(* Returns the underlying layout of the rooted layout rl. *)
let layout rl =
    assert (is_valid rl);
    rl.layout

(* Returns the note which is the root of the rooted layout rl. *)
let root rl =
    assert (is_valid rl);
    rl.root

(* Returns the number of minimal degrees in the rooted layout rl. *)
let nb_minimal_degrees rl =
    assert (is_valid rl);
    Layout.nb_minimal_degrees rl.layout

(* Returns the number of steps by octave in the layout l. *)
let nb_steps_by_octave rl =
    assert (is_valid rl);
    Layout.nb_steps_by_octave rl.layout

(* Returns the rooted layout obtained by setting as new root note the note at the position
 * delta, expressed as a degree from the current root. This value delta can be
 * negative. For instance, if rl is the rooted layout 9/11:0 - 2 1 2 2 1 2 2 and delta is 2,
  * the returned rooted layout is 0/11:1 - 2 2 1 2 2 2 1. *)
let transpose rl delta =
    assert (is_valid rl);
    let nt = Note.shift rl.root
        (Layout.distance_from_origin rl.layout (Degree.construct delta)) in
    let l = Layout.rotate rl.layout delta in
    {layout = l; root = nt}

(* Returns the note specified by the degree d in the rooted layout rl. *)
let degree_to_note rl d =
    assert (is_valid rl);
    root (transpose rl (Degree.to_int d))

(* Returns the list of the notes corresponding to all the degrees of the rooted layout
 * rl. *)
let first_notes rl =
    assert (is_valid rl);
    List.init (nb_minimal_degrees rl) Degree.construct |> List.map (degree_to_note rl)

(* Tests if the note n belongs to the notes denoted by the rooted layout rl. *)
let is_note rl n =
    assert (is_valid rl);
    assert (Note.is_valid n);
    assert (nb_steps_by_octave rl = Note.nb_steps_by_octave n) ;
    first_notes rl |> List.exists (fun n' -> Note.are_equivalent n n')

(* Tests if the two rooted layouts rl1 and rl2 are equivalent. This is the case if the
 * infinite sets of notes denoted by these two rooted layouts are the same. *)
let are_equivalent rl1 rl2 =
    assert (is_valid rl1);
    assert (is_valid rl2);
    assert (nb_steps_by_octave rl1 = nb_steps_by_octave rl2);
    let notes_1 = first_notes rl1 and notes_2 = first_notes rl2 in
    notes_1 |> List.for_all (fun n -> is_note rl2 n)
        && notes_2 |> List.for_all (fun n -> is_note rl1 n)

(* Returns the list of all rooted layouts consisting in the layout l and any root of the
 * octave octave. *)
let generate l octave =
    assert (Layout.is_valid l);
    let nb_steps_by_octave = Layout.nb_steps_by_octave l in
    Note.generate nb_steps_by_octave octave |> List.map (fun n -> {layout = l; root = n})

(* Returns the list of all non pairwise equivalent rooted layouts consisting in the layout l
 * and any root of the octave octave. *)
let generate_nonequivalent l octave =
    assert (Layout.is_valid l);
    generate l octave |> List.fold_left
        (fun res rl ->
            if res |> List.for_all (fun rl' -> not (are_equivalent rl rl')) then
                rl :: res
            else
                res)
        []
        |> List.rev

