(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A timbre is built as an association list associating with some integers i the weights of
 * the i-th harmonics between 0.0 and 1.0. These weights have to be different from 0.0. If
 * an integer i is not is this association list, the weight of the i-th harmonic is 0.0. The
 * fundamental harmonics is the 1-st one. *)
type timbre = Timbre of (int * float) list

(* The minimal nonzero allowed value for the weights in timbres. *)
let min_weight =
    2.0 ** (-. 16.0)

(* Returns the timbre having lst as underlying association list. *)
let construct lst =
    assert (List.length (lst |> List.map fst |> List.sort_uniq compare) = List.length lst);
    assert (lst |> List.map fst |> List.for_all (fun i -> i >= 1));
    assert (lst |> List.map snd |> List.for_all (fun c -> min_weight <= c && c <= 1.0));
    Timbre lst

(* Returns the underlying association list of the timbre t. *)
let to_list t =
    let Timbre lst = t in
    lst

(* Returns a string representation of the timbre t. *)
let to_string t =
    Printf.sprintf "[%s]"
        (to_list t |> List.map
            (fun (i, c) -> Printf.sprintf "%d: %.4f" i c) |> String.concat "; ")

(* Returns the weight of the i-th harmonics of the timbre t. *)
let weight t i =
    assert (i >= 1);
    let w = List.assoc_opt i (to_list t) in
    match w with
        |Some w' -> w'
        |None -> 0.0

(* Returns the number of weights of the timbre t. *)
let nb_weights t =
    List.length (to_list t)

(* Returns the timbre obtained from the timbre t by scaling each of its weights by the
 * coefficient c. *)
let scale v t =
    assert (0.0 <= v);
    to_list t |> List.map (fun (i, c) -> (i, v *. c))
        |> List.filter (fun (_, c) -> min_weight <= c)
        |> construct

(* Returns the timbre which is the geometric progression of the value v. This value has to
 * be between 0.0 and 1.0 (strictly). *)
let geometric v =
    assert (0.0 < v && v < 1.0);
    let rec aux i =
        let coeff = v ** (float_of_int (i - 1)) in
        if coeff < min_weight then
            []
        else
            (i, coeff) :: aux (i + 1)
    in
    construct (aux 1)

(* Returns the timbre which is the arithmetic reverse progression of the value v. This value
 * has to be between 0.0 and 1.0. *)
let arithmetic v =
    assert (0.0 <= v && v < 1.0);
    let v' = 1.0 -. v in
    let rec aux i =
        let coeff = 1.0 -. (float_of_int (i - 1)) *. v' in
        if coeff < min_weight then
            []
        else
            (i, coeff) :: aux (i + 1)
    in
    construct (aux 1)

(* Returns the timber made of harmonics corresponding with octaves and with 1.0 as weight.
 * The number of such harmonics is nb_octaves. *)
let octaves nb_octaves =
    assert (1 <= nb_octaves);
    construct (List.init nb_octaves (fun i ->  (1 lsl i, 1.0)))

(* Returns the timber wherein the first nb_harmonics have 1.0 as weight and the other ones
 * have 0.0. *)
let full nb_harmonics =
    assert (1 <= nb_harmonics);
    construct (List.init nb_harmonics (fun i -> (i + 1, 1.0)))

(* Returns the timbre obtained from the integer list seq. The i-th harmonics admits as
 * weight the inverse of the i-th term of seq. *)
let sequence seq =
    assert (seq |> List.for_all (fun j -> 1 <= j));
    let len = List.length seq in
    let inv_seq = seq |> List.map (fun j -> 1.0 /. (float_of_int j)) in
    construct (List.combine (List.init len (fun i -> i + 1)) inv_seq)

