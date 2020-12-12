(* Author: Samuele Giraudo
 * Creation: (jul. 2015), may 2020
 * Modifications: may 2020, dec. 2020
 *)

(* A rooted layout is a layout together with a root note. This root is put in correspondence
 * with the note of extended degree 0. In this way, a rooted layout specifies an infinite 
 * set of notes, each indexed by its extended degree. *)
type rooted_layout = {
    (* The layout. *)
    layout : Layout.layout;

    (* The root note. This note is put in correspondence with the note of extended degree
     * 0. *)
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

(* Returns the number of degrees in the rooted layout rl. *)
let nb_degrees rl =
    assert (is_valid rl);
    Layout.nb_degrees rl.layout

(* Returns the number of steps by octave in the layout l. *)
let nb_steps_by_octave rl =
    assert (is_valid rl);
    Layout.nb_steps_by_octave rl.layout

(* Returns the rooted layout obtained from the rooted layout rl by choosing the next note
 * of the root as new root. *)
let shift_left rl =
    assert (is_valid rl);
    let note = Note.shift rl.root (Layout.distance_next rl.layout 0) in
    {layout = Layout.rotate_left rl.layout; root = note}

(* Returns the rooted layout obtained from the rooted layout rl by choosing the previous
 * note of the root as new root. *)
let shift_right rl =
    assert (is_valid rl);
    let note = Note.shift rl.root (Layout.distance_previous rl.layout 0) in
    {layout = Layout.rotate_right rl.layout; root = note}

(* Returns the note of extended degree d in the rooted layout rl *)
let rec extended_degree_to_note rl d =
    assert (is_valid rl);
    if d = 0 then
        rl.root
    else if d >= 1 then
        extended_degree_to_note (shift_left rl) (d - 1)
    else
        extended_degree_to_note (shift_right rl) (d + 1)

(* Returns the list of the notes corresponding to all the degrees of the rooted layout
 * rs. *)
let first_notes rl =
    assert (is_valid rl);
    List.init (nb_degrees rl) (extended_degree_to_note rl)

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
    let notes_1 = first_notes rl1 and notes_2 = first_notes rl2 in
    notes_1 |> List.for_all (fun n -> is_note rl2 n)
        && notes_2 |> List.for_all (fun n -> is_note rl1 n)

(* Returns the list of all rooted layouts consisting in the layout l and any root having
 * octave_index as octave index. *)
let generate l octave_index =
    assert (Layout.is_valid l);
    let nb_steps_by_octave = Layout.nb_steps_by_octave l in
    Note.generate nb_steps_by_octave octave_index |> List.map
        (fun n -> {layout = l; root = n})

(* Returns the list of all non pairwise equivalent rooted layouts consisting in the layout l
 * and any root having octave_index as octave index. *)
let generate_nonequivalent l octave_index =
    generate l octave_index |> List.fold_left
        (fun res rl ->
            if res |> List.for_all (fun rl' -> not (are_equivalent rl rl')) then
                rl :: res
            else
                res)
        []
        |> List.rev


(* The test function of the module. *)
let test () =
    print_string "RootedLayout\n";

(*
    let n1 = Note.construct 4 12 2 in
    let n2 = Note.construct 6 12 2 in
    let n3 = Note.construct 11 12 2 in
    let rl1 = construct Layout.harmonic_minor n1 in
    let rl2 = construct Layout.harmonic_minor n2 in
    if to_string rl1 <> "4/11:2 - 2 1 2 2 1 3 1" then
        false
    else if shift_left rl1 <> rl2 then
        false
    else if shift_left (from_string "11/11:2 - 2 1 2 2 1 3 1") <>
            from_string "1/11:3 - 1 2 2 1 3 1 2" then
        false
    else if shift_right (from_string "4/11:2 - 2 1 2 2 1 3 1") <>
            from_string "3/11:2 - 1 2 1 2 2 1 3" then
        false
    else if shift_right (from_string "0/11:2 - 2 1 2 2 1 3 1") <>
            from_string "11/11:1 - 1 2 1 2 2 1 3" then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") 0 <>
            Note.construct 4 12 2 then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") 1 <>
            Note.construct 6 12 2 then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") 2 <>
            Note.construct 7 12 2 then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") (-1) <>
            Note.construct 3 12 2 then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") (-2) <>
            Note.construct 0 12 2 then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") 8 <>
            Note.construct 6 12 3 then
        false
    else if extended_degree_to_note (from_string "4/11:2 - 2 1 2 2 1 3 1") (-8) <>
            Note.construct 3 12 1 then
        false
    else if first_notes (from_string "4/11:2 - 2 1 4 1 4") <>
            [Note.construct 4 12 2; Note.construct 6 12 2; Note.construct 7 12 2;
             Note.construct 11 12 2; Note.construct 0 12 3] then
         false
    else if is_note (from_string "4/11:2 - 2 1 4 1 4") (Note.construct 11 12 (-3)) <> true
            then
        false
    else if is_note (from_string "4/11:2 - 2 1 4 1 4") (Note.construct 10 12 (-3)) <> false
            then
        false
    else if are_equivalent (from_string "0/11:1 - 2 2 1 2 2 2 1")
            (from_string "9/11:3 - 2 1 2 2 1 2 2") <> true then
        false
    else if are_equivalent (from_string "0/11:1 - 2 2 1 2 2 2 1")
            (from_string "7/11:3 - 2 1 2 2 1 2 2") <> false then
        false
    else if generate [2; 1; 2; 1] 3 |> List.map to_string |> String.concat "; "
            <> "0/5:3 - 2 1 2 1; 1/5:3 - 2 1 2 1; 2/5:3 - 2 1 2 1; 3/5:3 - 2 1 2 1; \
                4/5:3 - 2 1 2 1; 5/5:3 - 2 1 2 1" then
        false
    else if generate_nonequivalent [2; 1; 2; 1] 3 |> List.map to_string
            |> String.concat "; " <> "0/5:3 - 2 1 2 1; 1/5:3 - 2 1 2 1; 2/5:3 - 2 1 2 1"
            then
        false
    else
    *)
        true

