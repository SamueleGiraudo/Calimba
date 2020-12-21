(* Author: Samuele Giraudo
 * Creation: aug. 2020
 * Modifications: aug. 2020, dec. 2020
 *)

(* A layout shift represents an extended degree by specifying its distance from the origin
 * degree. *)
type layout_shift = {
    (* The distance in degrees from the origin. This value can be negative. *)
    degree : int;

    (* The distance in octaves from the origin. This value can be negative. *)
    octave : int
}

(* Returns the layout shift with the specified attributes. *)
let construct degree octave =
    {degree = degree; octave = octave}

(* Returns the octave of the layout shift ls. *)
let octave ls =
    ls.octave

(* Returns the layout shift encoding the extended degree d in a layout having nb_degrees
 * degrees. The returned layout shift has a degree between 0 and nb_degrees - 1. *)
let from_extended_degree nb_degrees d =
    assert (nb_degrees >= 1);
    let deg = Tools.remainder d nb_degrees in
    if d >= 0 then
        {degree = deg; octave = d / nb_degrees}
    else
        {degree = deg; octave = (d + 1) / nb_degrees - 1}

(* Returns a string representation of the layout shift ls. *)
let to_string ls =
    Tools.csprintf Tools.Magenta (Printf.sprintf "%d:%d" ls.degree ls.octave)

(* Returns the distance from the root encoded by the layout shift ls in the context of a
 * layout having nb_degrees degrees. *)
let distance_from_root nb_degrees ls =
    assert (1 <= nb_degrees);
    ls.degree + nb_degrees * ls.octave

(* Returns the layout shift ls wherein the octave is set to octave. *)
let change_octave ls octave =
    {ls with octave = octave}

(* Returns the layout shift obtained by adding the layout shifts ls1 and ls2. *)
let add ls1 ls2 =
    {degree = ls1.degree + ls2.degree; octave = ls1.octave + ls2.octave}

(* Returns the complement layout shift of the layout shift ls. This is the inverse of ls
 * w.r.t. degree addition. *)
let complement ls =
    {degree = - ls.degree; octave = - ls.octave}

