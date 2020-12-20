(* Author: Samuele Giraudo
 * Creation: (jul. 2015), may. 2020
 * Modifications: may 2020, dec. 2020
 *)

(* A layout is an integer composition. It encodes a sequence of distances in an octave. Each
 * integer specifies the distance between two consecutive degrees. A layout can be used to
 * specify a scale or an arpeggio. *)
type layout = int list

(* Tests if the integer list l is a layout. *)
let is_valid l =
    l <> [] && l |> List.for_all (fun a -> 1 <= a)

(* Returns the layout having l as underlying list of integers. *)
let construct l =
    assert (is_valid l);
    l

(* Returns a string representation of the layout l. For instance, "3 2 2 3 2" is the string
 * representation of the minor pentatonic layout. *)
let to_string l =
    Tools.csprintf Tools.Yellow (l |> List.map string_of_int |> String.concat " ")

(* Returns the number of degrees in the layout l. *)
let nb_degrees l =
    assert (is_valid l);
    List.length l

(* Returns the number of steps by octave in the layout l. *)
let nb_steps_by_octave l =
    assert (is_valid l);
    l |> List.fold_left (+) 0

(* Returns the layout obtained by rotating for one step to the left the layout l. This is
 * the layout such that the new degree 0 is the former degree following the degree 0. *)
let rotate_left l =
    assert (is_valid l);
    List.append (List.tl l) [List.hd l]

(* Returns the layout obtained by rotating for one step to the right the layout l. This is
 * the layout such that the new degree 0 is the former last degree. *)
let rotate_right l =
    assert (is_valid l);
    let tmp = List.rev l in
    (List.hd tmp) :: (List.rev (List.tl tmp))

(* Returns the layout obtained by rotating from delta step to the left the layout l if
 * delta is positive and to the right otherwise. *)
let rec rotate l delta =
    assert (is_valid l);
    if delta = 0 then
        l
    else if delta >= 1 then
        rotate (rotate_left l) (delta - 1)
    else
        rotate (rotate_right l) (delta + 1)

(* Returns the distance in steps from the extended degree d to the next one in the layout
 * l. *)
let distance_next l d =
    assert (is_valid l);
    List.nth l (Tools.remainder d (nb_degrees l))

(* Returns the distance in steps from the extended degree d to the previous one in the
 * layout l. The returned value is negative. *)
let distance_previous l d =
    assert (is_valid l);
    - (distance_next l (d - 1))

(* Returns the distance in steps from the origin to the extended degree d in the layout
 * l. This value is negative iff d is negative. *)
let rec distance_from_origin l d =
    assert (is_valid l);
    if d = 0 then
        0
    else if d >= 1 then
        (distance_next l 0) + (distance_from_origin (rotate_left l) (d - 1))
    else
        (distance_previous l 0) + (distance_from_origin (rotate_right l) (d + 1))

(* Returns the distance between the two extended degrees d1 and d2 of the layout l. The
 * first one must be not greater than the second one. *)
let distance_between l d1 d2 =
    assert (is_valid l);
    assert (d1 <= d2);
    distance_from_origin l d2 - distance_from_origin l d1

(* Returns the mirror of the layout l. *)
let mirror l =
    assert (is_valid l);
    List.rev l

(* Returns the list of all rotations of the layout l. Each element of this list is a mode,
 * also called as an inversion of l. *)
let rotation_class l =
    assert (is_valid l);
    List.init (nb_degrees l) Fun.id |> List.fold_left
        (fun res _ -> (rotate_left (List.hd res)) :: res) [l]
        |> List.sort_uniq compare

(* Tests if the layouts l1 and l2 are in the same rotation class. *)
let are_rotation_equivalent l1 l2 =
    assert (is_valid l1);
    assert (is_valid l2);
    assert (nb_steps_by_octave l1 = nb_steps_by_octave l2);
    List.mem l1 (rotation_class l2)

(* Returns the minimal element of the rotation class of the layout l w.r.t. the
 * lexicographic order. *)
let minimal_of_rotation_class l =
    assert (is_valid l);
    rotation_class l |> List.fold_left min l

(* Tests if the layout l is the minimal layout of its rotation class. *)
let is_minimal_in_rotation_class l =
    assert (is_valid l);
    l = minimal_of_rotation_class l

(* Returns the dual of the layout l. This is the layout having the transpose of l as
 * integer composition. *)
let rec dual l =
    assert (is_valid l);
    match l with
        |[] | [1] -> l
        |1 :: l' ->
            let tmp = dual l' in
            ((List.hd tmp) + 1) :: (List.tl tmp)
        |a :: l' -> 1 :: (dual ((a - 1) :: l'))

(* Returns an option on a list of lists of integers obtained graphically by inserting
 * brackets into the list of integers l2 such that, by taking the sums of the values of the
 * lists, one obtain the list of integers l2. None is returned is this is not possible. *)
let rec gather_as_sub_layout l1 l2 =
    match l1, l2 with
        |[], [] -> Some []
        |a1 :: l1', a2 :: l2' when a1 = a2 ->
            let tmp = gather_as_sub_layout l1' l2' in
            Tools.transform_option_default (fun x -> Some ([a2] :: x)) tmp None
        |a1 :: l1', a2 :: l2' when a1 > a2 ->
            let tmp = gather_as_sub_layout ((a1 - a2) :: l1') l2' in
            Tools.transform_option_default
                (fun x ->  Some ((a2 :: (List.hd x)) :: (List.tl x)))
                tmp
                None
        |_ -> None

(* Tests if the set of the distances from the origin of the layout l1 is included into the
 * set of distances from the origin of the layout l2. *)
let is_sub_layout l1 l2 =
    assert (is_valid l1);
    assert (is_valid l2);
    assert (nb_steps_by_octave l1 = nb_steps_by_octave l2);
    Option.is_some (gather_as_sub_layout l1 l2)

(* Returns the list of the sub_layouts of the layout l. *)
let sub_layouts l =
    assert (is_valid l);
    List.tl l |> List.fold_left
        (fun res v ->
            List.append
                (res |> List.map (fun l' -> v :: l'))
                (res |> List.map (fun l' -> (v + List.hd l') :: List.tl l')))
        [[List.hd l]]
    |> List.map List.rev |> List.sort compare

(* Returns the list of all the layouts circularly included into the layout l. *)
let circular_sub_layouts l =
    rotation_class l |> List.map sub_layouts |> List.flatten |> List.sort_uniq compare

(* Returns the list of the lists of layout shifts such that the layout l1 is a circular
 * sub-layout of the layout l2. Each list of layout shifts specifies a choice of extended
 * degrees of l2 in order to obtain l1. *)
let layout_shifts_for_circular_inclusion l1 l2 =
    assert (is_valid l1);
    assert (is_valid l2);
    let nb_deg = nb_degrees l2 in
    List.init (List.length l2) Fun.id |> List.map
        (fun delta ->
            let l2' = rotate l2 delta in
            let g = gather_as_sub_layout l1 l2' in
            Tools.transform_option_default
                (fun x ->
                     Some (x |> List.map List.length |> List.fold_left
                        (fun res v -> (v + (List.hd res)) :: res)
                        [0]
                        |> List.tl
                        |> List.rev
                        |> List.map (fun v -> v + delta)))
                g
                None)
        |> List.filter Option.is_some
        |> List.map Option.get
        |> List.map
            (fun lst -> lst |> List.map (LayoutShift.from_extended_degree nb_deg))

(* Returns the list of all the layouts defined on nb_steps_by_octave nb steps by octave
 * and on nb_degrees degrees. *)
let rec generate nb_steps_by_octave nb_degrees =
    assert (nb_steps_by_octave >= 0);
    assert (nb_degrees >= 1);
    if nb_degrees > nb_steps_by_octave then
        []
    else if nb_degrees = 1 then
        [[nb_steps_by_octave]]
    else
        List.init nb_steps_by_octave
            (fun x ->
                generate (nb_steps_by_octave - x - 1) (nb_degrees - 1) |> List.map
                    (fun l -> (x + 1) :: l))
            |> List.flatten

(* Some layouts. *)

let chromatic nb_steps_by_octave =
    assert (1 <= nb_steps_by_octave);
    List.init nb_steps_by_octave (fun _ -> 1)

let diminished = [2; 1; 2; 1; 2; 1; 2; 1]

let natural_major = [2; 2; 1; 2; 2; 2; 1]

let natural_minor = [2; 1; 2; 2; 1; 2; 2]

let harmonic_minor = [2; 1; 2; 2; 1; 3; 1]

let phrygian_dominant = [1; 3; 1; 2; 1; 2; 2]

let hungarian_minor = [2; 1; 3; 1; 1; 3; 1]

let double_harmonic_minor = [1; 3; 1; 2; 1; 3; 1]

let blues = [3; 2; 1; 1; 3; 2]

let whole_tone = [2; 2; 2; 2; 2; 2]

let pentatonic_minor = [3; 2; 2; 3; 2]

let pentatonic_major = [2; 2; 3; 2; 3]

let hirajoshi = [2; 1; 4; 1; 4]

let ryukyu = [4; 1; 2; 4; 1]

let major = [4; 3; 5]

let minor = [3; 4; 5]

let major_7 = [4; 3; 4; 1]

let minor_7 = [3; 4; 3; 2]

