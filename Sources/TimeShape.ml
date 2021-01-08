(* Author: Samuele Giraudo
 * Creation: aug. 2020
 * Modifications: aug. 2020, dec. 2020, jan. 2021
 *)

(* A time shape specifies how the durations of beats and rests are altered. This is a pair
 * (m, d) used in the following way. If the duration of a beat or a rest has to be
 * increased (resp. decreased), its new duration is computed by multiplying (resp. dividing)
 * it by m/d. *)
type time_shape = {
    (* The multiplier of the time shape. *)
    multiplier : int;

    (* The divider of the time shape. *)
    divider : int
}

(* Returns the time shape with the specified attributes. *)
let construct multiplier divider =
    assert (divider >= 1);
    assert (divider < multiplier);
    {multiplier = multiplier; divider = divider}

(* Returns a string representation of the time shape ts. *)
let to_string ts =
    Tools.csprintf Tools.Green (Printf.sprintf "%d/%d" ts.multiplier ts.divider)

(* Returns the multiplier of the time shape ts. *)
let multiplier ts =
    ts.multiplier

(* Returns the divider of the time shape ts. *)
let divider ts =
    ts.divider

