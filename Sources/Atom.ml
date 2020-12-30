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

(* A performance is a map saying how to associate with any atom a sound. *)
type performance = atom -> Sound.sound

(* Returns an atom which is a silence lasting one unit of time. *)
let silence =
    Silence TimeDegree.zero

(* Returns an atom which is a beat lasting one unit of time and of degree d. *)
let beat d =
    Beat (Degree.Degree d, TimeDegree.zero, None)

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

(* Returns the atom resulting as the product of the atom a1 and a2. This is the product used
 * for the composition of tree patterns. *)
let product a1 a2 =
    match a1, a2 with
        |Silence td1, Silence td2 |Silence td1, Beat (_, td2, _)
                |Beat (_, td1, _), Silence td2 ->
            Silence (TimeDegree.add td1 td2)
        |Beat (d1, td1, _), Beat (d2, td2, lbl2) ->
            Beat (Degree.add d1 d2, TimeDegree.add td1 td2, lbl2)

