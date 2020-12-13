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
    l |> List.map string_of_int |> String.concat " "

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


(* Some functions for exploration of layouts. *)

(* Returns the distance in steps from the degree d to the next in the layout l. *)
let distance_next l d =
    assert (is_valid l);
    assert (0 <= d && d < nb_degrees l);
    List.nth l d

(* Returns the distance in steps from the degree d to the previous in the layout l. The
 * returned value is negative. *)
let distance_previous l d =
    assert (is_valid l);
    assert (0 <= d && d < nb_degrees l);
    if d = 0 then
        - List.nth l ((nb_degrees l) - 1)
    else
        - List.nth l (d - 1)

(* Returns the distance in steps from the origin to the degree d in the layout l. *)
let distance_from_origin l d =
    assert (is_valid l);
    assert (0 <= d && d < nb_degrees l);
    List.init d Fun.id |> List.fold_left (fun res d' -> res + (distance_next l d')) 0

(* Returns the distance in steps from the degree d to the end in the layout l. *)
let distance_to_end l d =
    assert (is_valid l);
    assert (0 <= d && d < nb_degrees l);
    (nb_steps_by_octave l) - (distance_from_origin l d)

(* Returns the distance between the two degrees d1 and d2 of the layout l. This value is
 * always positive. *)
let distance_between l d1 d2 =
    assert (is_valid l);
    assert (0 <= d1 && d1 < nb_degrees l);
    assert (0 <= d2 && d1 < nb_degrees l);
    if d1 <= d2 then
        (distance_from_origin l d2) - (distance_from_origin l d1)
    else
        (distance_to_end l d1) + (distance_from_origin l d2)

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

(* Tests if the layout l1 is included into the layout l2 in the sense that the set of
 * distances from the origin of l1 is included into the set of distances from the origin
 * of l2. *)
let is_included l1 l2 =
    assert (is_valid l1);
    assert (is_valid l2);
    assert (nb_steps_by_octave l1 = nb_steps_by_octave l2);
    let dist1 = List.init (nb_degrees l1) (distance_from_origin l1)
    and dist2 = List.init (nb_degrees l2) (distance_from_origin l2) in
    dist1 |> List.for_all (fun d -> List.mem d dist2)

(* Returns the list of the degrees d of which the layout l1 is included into the layout l2
 * by putting in correspondence the degree 0 of l1 and the degree d of l2. *)
let degrees_for_inclusion l1 l2 =
    assert (is_valid l1);
    assert (is_valid l2);
    assert (nb_steps_by_octave l1 = nb_steps_by_octave l2);
    let rec rotation l n = if n = 0 then l else rotation (rotate_left l) (n - 1) in
    List.init (nb_degrees l2)
        (fun d -> if is_included l1 (rotation l2 d) then Some d else None)
        |> ExtLib.List.filter_map Fun.id

(* Tests if the layout l1 is contained in one of the rotations of the layout l2. *)
let is_included_with_rotation l1 l2 =
    assert (is_valid l1);
    assert (is_valid l2);
    degrees_for_inclusion l1 l2 <> []

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

