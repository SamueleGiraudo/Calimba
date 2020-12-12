(* Author: Samuele Giraudo
 * Creation: aug. 2020
 * Modifications: aug. 2020
 *)

(* A shift represents an extended degree by specifying its distance from the origin
 * degree. *)
type shift = {
    (* The distance in degrees from the origin. This value can be negative. *)
    degree : int;

    (* The distance in octaves from the origin. This value can be negative. *)
    octave : int
}

(* Returns the shift with the specified attributes. *)
let construct degree octave =
    {degree = degree; octave = octave}

(* Returns a string representation of the shift s. *)
let to_string s =
    Printf.sprintf "%d:%d" s.degree s.octave

(* Returns the extended degree encoded by the shift s in the context of a layout having
 * nb_degrees degrees. *)
let to_extended_degree nb_degrees s =
    assert (1 <= nb_degrees);
    s.degree + nb_degrees * s.octave

(* Returns the shift obtained by adding the shifts s1 and s2. *)
let add s1 s2 =
    {degree = s1.degree + s2.degree; octave = s1.octave + s2.octave}

(* Returns the complement shift of the shift s. This is the inverse of s w.r.t. degree 
 * addition. *)
let complement s =
    {degree = - s.degree; octave = - s.octave}


(* The test function of the module. *)
let test () =
    print_string "Shift\n";
    true

