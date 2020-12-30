(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A label is a name that a beat can optionally hold. *)
type label = string

(* An atom encodes an atomic unit of music. It can be either a silence or a beat. A beat can
 * have a label. *)
type atom =
    |Silence of TimeDegree.time_degree
    |Beat of Degree.degree * TimeDegree.time_degree * (label option)

(* Returns an atom which is a silence with the time degree td. *)
let construct_silence td =
    Silence td

(* Returns an atom which is an unlabeled beat atom with the specified attributes. *)
let construct_beat d td =
    Beat (d, td, None)

(* Returns an atom which is a labeled beat atom with the specified attributes. *)
let construct_labeled_beat d td lbl =
    Beat (d, td, Some lbl)

(* Returns an atom which is a labeled beat lasting one unit of time, of degree d, and of
 * label lbl. *)
let labeled_beat d lbl =
    Beat (Degree.Degree d, TimeDegree.zero, Some lbl)

(* Returns a string representation of the atom a. *)
let to_string a =
    match a with
        |Silence td -> TimeDegree.to_string td
        |Beat (d, td, lbl) ->
            let str = Printf.sprintf "%s%s"
                (Degree.to_string d) (TimeDegree.to_string td) in
            if Option.is_some lbl then
                Printf.sprintf "%s:%s" str (Option.get lbl)
            else
                str

(* Tests if the atom a is a beat. *)
let is_beat a =
    match a with
        |Silence _ -> false
        |Beat _ -> true

(* Returns an option on the label on the atom a. Returns None if a is a silence or if a is a
 * beat without label. *)
let label a =
    match a with
        |Beat (_, _, Some lbl) -> Some lbl
        |_ -> None

(* Returns the complement of the atom a. *)
let complement a =
    match a with
        |Silence _ -> a
        |Beat (d, td, lbl) -> Beat (Degree.complement d, td, lbl)

(* Returns the atom resulting as the product of the atom a1 and a2. This is the product used
 * for the composition of tree patterns. *)
let product a1 a2 =
    match a1, a2 with
        |Silence td1, Silence td2 |Silence td1, Beat (_, td2, _)
                |Beat (_, td1, _), Silence td2 ->
            Silence (TimeDegree.add td1 td2)
        |Beat (d1, td1, _), Beat (d2, td2, lbl2) ->
            Beat (Degree.add d1 d2, TimeDegree.add td1 td2, lbl2)

