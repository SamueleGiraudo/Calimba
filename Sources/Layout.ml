(* Author: Samuele Giraudo
 * Creation: (jul. 2015), may. 2020
 * Modifications: may 2020, dec. 2020
 *)

(* A layout is an integer composition. It encodes a sequence of distances in an octave. Each
 * integer specifies the distance between two consecutive minimal degrees. A layout can be
 * used to specify a scale or an arpeggio. *)
type layout = Layout of int list

(* Tests if the integer list lst is a valid list for a layout. *)
let is_valid_list lst =
    lst <> [] && lst |> List.for_all (fun a -> 1 <= a)

(* Returns the layout having lst as underlying list of integers. *)
let construct lst =
    assert (is_valid_list lst);
    Layout lst

(* The natural minor layout. *)
let natural_minor = construct [2; 1; 2; 2; 1; 2; 2]

(* Returns the list associated with the layout l. *)
let to_list l =
    let Layout lst = l in
    lst

(* Returns a string representation of the layout l. For instance, "3 2 2 3 2" is the string
 * representation of the minor pentatonic layout. *)
let to_string l =
    Tools.csprintf Tools.Yellow (to_list l |> List.map string_of_int |> String.concat " ")

(* Returns the number of minimal degrees in the layout l. A degree is minimal if its refers
 * to a note in the octave 0 specified by the layout. *)
let nb_minimal_degrees l =
    List.length (to_list l)

(* Returns the number of steps by octave in the layout l. *)
let nb_steps_by_octave l =
    to_list l |> List.fold_left (+) 0

(* Returns the list of all minimal degrees of the layout l. *)
let minimal_degrees l =
    List.init (nb_minimal_degrees l) Degree.construct

(* Returns the layout obtained by rotating for one step to the left the layout l. This is
 * the layout such that the new degree 0 is the former degree following the degree 0. *)
let rotate_left l =
    let lst = to_list l in
    construct (List.append (List.tl lst) [List.hd lst])

(* Returns the layout obtained by rotating for one step to the right the layout l. This is
 * the layout such that the new degree 0 is the former last degree. *)
let rotate_right l =
    let tmp = List.rev (to_list l) in
    construct ((List.hd tmp) :: (List.rev (List.tl tmp)))

(* Returns the layout obtained by rotating from delta step to the left the layout l if
 * delta is positive and to the right otherwise. *)
let rec rotate l delta =
    if delta = 0 then
        l
    else if delta >= 1 then
        rotate (rotate_left l) (delta - 1)
    else
        rotate (rotate_right l) (delta + 1)

(* Returns the distance in steps from the degree d to the next one in the layout l. *)
let distance_next l d =
    List.nth (to_list l) (Tools.remainder (Degree.to_int d) (nb_minimal_degrees l))

(* Returns the distance in steps from the degree d to the previous one in the layout l. The
 * returned value is negative. *)
let distance_previous l d =
    - (distance_next l (Degree.previous d))

(* Returns the distance in steps from the origin to the degree d in the layout l. This value
 * is negative iff d is negative. *)
let rec distance_from_origin l d =
    if Degree.is_zero d then
        0
    else if Degree.is_nonnegative d then
        distance_next l Degree.zero
            + distance_from_origin (rotate_left l) (Degree.previous d)
    else
        distance_previous l Degree.zero
            + distance_from_origin (rotate_right l) (Degree.next d)

(* Returns the distance between the two degrees d1 and d2 of the layout l. The first one
 * must be not greater than the second one. *)
let distance_between l d1 d2 =
    assert (Degree.is_leq d1 d2);
    distance_from_origin l d2 - distance_from_origin l d1

(* Returns the list of integers of length the number of degrees in the layout l such that
 * the i-th value is the distance from the origin of the i-th degree of l. *)
let distance_vector l =
    minimal_degrees l |> List.map (distance_from_origin l)

(* Returns the mirror of the layout l. *)
let mirror l =
    construct (List.rev (to_list l))

(* Returns the list of all rotations of the layout l. *)
let rotation_class l =
    minimal_degrees l |> List.fold_left
        (fun res _ -> (rotate_left (List.hd res)) :: res) [l]
        |> List.sort_uniq compare

(* Tests if the layouts l1 and l2 are in the same rotation class. *)
let are_rotation_equivalent l1 l2 =
    assert (nb_steps_by_octave l1 = nb_steps_by_octave l2);
    List.mem l1 (rotation_class l2)

(* Returns the minimal element of the rotation class of the layout l w.r.t. the
 * lexicographic order. *)
let minimal_of_rotation_class l =
    rotation_class l |> List.fold_left min l

(* Tests if the layout l is the minimal layout of its rotation class. *)
let is_minimal_in_rotation_class l =
    l = minimal_of_rotation_class l

(* Returns the dual of the layout l. This is the layout having the transpose of l as
 * integer composition. *)
let dual l =
    let rec aux lst =
        match lst with
            |[] | [1] -> lst
            |1 :: lst' ->
                let tmp = aux lst' in
                ((List.hd tmp) + 1) :: (List.tl tmp)
            |a :: lst' -> 1 :: (aux ((a - 1) :: lst'))
    in
    construct (aux (to_list l))

(* Returns an option on a list of lists of integers obtained graphically by inserting
 * brackets into the list of integers l2 such that, by taking the sums of the values of the
 * lists, one obtain the list of integers l2. None is returned is this is not possible. *)
let gather_as_sub_layout l1 l2 =
    let rec aux lst1 lst2 =
        match lst1, lst2 with
            |[], [] -> Some []
            |a1 :: lst1', a2 :: lst2' when a1 = a2 ->
                let tmp = aux lst1' lst2' in
                Tools.transform_option_default (fun x -> Some ([a2] :: x)) tmp None
            |a1 :: lst1', a2 :: lst2' when a1 > a2 ->
                let tmp = aux ((a1 - a2) :: lst1') lst2' in
                Tools.transform_option_default
                    (fun x ->  Some ((a2 :: (List.hd x)) :: (List.tl x)))
                    tmp
                    None
            |_ -> None
    in
    aux (to_list l1) (to_list l2)

(* Tests if the set of the distances from the origin of the layout l1 is included into the
 * set of distances from the origin of the layout l2. *)
let is_sub_layout l1 l2 =
    assert (nb_steps_by_octave l1 = nb_steps_by_octave l2);
    Option.is_some (gather_as_sub_layout l1 l2)

(* Returns the list of the sub_layouts of the layout l. *)
let sub_layouts l =
    to_list l |> List.tl |> List.fold_left
        (fun res v ->
            List.append
                (res |> List.map (fun l' -> v :: l'))
                (res |> List.map (fun l' -> (v + List.hd l') :: List.tl l')))
        [[List.hd (to_list l)]]
    |> List.map List.rev |> List.sort compare |> List.map construct

(* Returns the list of all the layouts circularly included into the layout l. *)
let circular_sub_layouts l =
    rotation_class l |> List.map sub_layouts |> List.flatten |> List.sort_uniq compare

(* Returns the list of the lists of degrees such that the layout l1 is a circular sub-layout
 * of the layout l2. Each list of degrees specifies a choice of degrees of l2 in order to
 * obtain l1. *)
let degrees_for_circular_inclusion l1 l2 =
    List.init (nb_minimal_degrees l2) Fun.id |> List.map
        (fun delta ->
            let l2' = rotate l2 delta in
            let g = gather_as_sub_layout l1 l2' in
            Tools.transform_option_default
                (fun x ->
                    let res = x |> List.map List.length |> List.fold_left
                        (fun res v -> (Degree.shift (List.hd res) v) :: res)
                        [Degree.construct delta]
                        |> List.tl
                        |> List.rev in
                    Some res)
                g
                None)
        |> List.filter Option.is_some
        |> List.map Option.get

(* Returns the list of pairs of degrees forming intervals in the layout l. Given such a
 * pair, the two degrees belong to the octave 0 or the first belongs to the octave 0 and the
 * second one to the octave 1. *)
let degrees_for_intervals l =
    let nbd = nb_minimal_degrees l in
    let deg_1 = minimal_degrees l in
    let deg_2 = deg_1 |> List.map (fun d -> Degree.shift d nbd) in
    let tmp =
        List.append
            (Tools.cartesian_product deg_1 deg_1)
            (Tools.cartesian_product deg_1 deg_2) in
    tmp |> List.filter (fun (d1, d2) -> Degree.is_leq d1 d2)

(* Returns the interval vector of the layout l. This is the list of length the number of
 * steps by octave minus 1 such that each value at position i is the number of intervals of
 * i + 1 steps in l. *)
let interval_vector l =
    let intervals = degrees_for_intervals l in
    let interval_values = intervals |> List.map
        (fun (d1, d2) -> distance_between l d1 d2) in
    Tools.occurrence_vector interval_values 1 (nb_steps_by_octave l - 1)

(* Returns the internal interval vector of the layout l. This follows the same idea as the
 * interval vector of l but it takes into account only the intervals in a same octave. *)
let internal_interval_vector l =
    let d_max = Degree.construct ((nb_minimal_degrees l) - 1) in
    let intervals = degrees_for_intervals l |> List.filter
        (fun (d1, d2) -> Degree.is_leq d1 d_max && Degree.is_leq d2 d_max) in
    let interval_values = intervals |> List.map
        (fun (d1, d2) -> distance_between l d1 d2) in
    Tools.occurrence_vector interval_values 1 (nb_steps_by_octave l - 1)

(* Returns the ratio between the frequency of the notes specified by the degrees d1 and d2
 * in the layout l. *)
let frequency_ratio l d1 d2 =
    let nbs = nb_steps_by_octave l in
    let freq d =
        let dist = distance_from_origin l d in
        let nt = Note.shift (Note.construct 0 nbs 0) dist in
        Note.frequency nt
    in
    freq d2 /. freq d1

(* Returns the pair of degrees such that the frequency ratio of the interval of the layout l
 * they specify approximates in the best way the ratio ratio. Given such a pair, the two
 * degrees belong to the octave 0 or the first belongs to the octave 0 and the second one
 * to the octave 1. *)
let best_interval_for_ratio l ratio =
    assert (ratio >= 1.0);
    let oc = int_of_float (Tools.log2 ratio) in
    let nbd = nb_minimal_degrees l in
    let deg_1 = minimal_degrees l in
    let deg_2 = deg_1 |> List.map (fun d -> Degree.shift d (oc * nbd)) in
    let deg_3 = deg_2 |> List.map (fun d -> Degree.shift d nbd) in
    let intervals = Tools.cartesian_product deg_1 (List.append deg_2 deg_3) in
    List.tl intervals |> List.fold_left
        (fun res candidate ->
            let r = frequency_ratio l (fst candidate) (snd candidate)
            and r_res = frequency_ratio l (fst res) (snd res) in
            match Tools.compare_accuracies ratio r_res r with
                |1 -> candidate
                |_ -> res)
        (List.hd intervals)

(* Returns the list of all the layouts defined on nb_steps_by_octave nb steps by octave
 * and on nb_minimal_degrees degrees. *)
let generate nb_steps_by_octave nb_minimal_degrees =
    assert (nb_steps_by_octave >= 0);
    assert (nb_minimal_degrees >= 1);
    let rec aux nb_steps_by_octave nb_minimal_degrees =
        if nb_minimal_degrees > nb_steps_by_octave then
            []
        else if nb_minimal_degrees = 1 then
            [[nb_steps_by_octave]]
        else
            List.init nb_steps_by_octave
                (fun x ->
                    aux (nb_steps_by_octave - x - 1) (nb_minimal_degrees - 1) |> List.map
                        (fun l -> (x + 1) :: l))
                |> List.flatten
    in
    aux nb_steps_by_octave nb_minimal_degrees |> List.map construct

