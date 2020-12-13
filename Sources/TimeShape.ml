(* Author: Samuele Giraudo
 * Creation: aug. 2020
 * Modifications: aug. 2020, dec. 2020
 *)

(* A time shape specifies how the durations of beats and rests are altered. This is a pair
 * (m, d) used in the following way. If the duration of a beat or a rest has to be
 * increased (resp. decreased), its new duration is computed by multiplying (resp. dividing)
 * it by m/d. *)
type time_shape = {
    multiplier : int;
    divider : int
}

(* Tests if ts is a valid time shape. *)
let is_valid ts =
    ts.multiplier >= 1 && ts.divider >= 1

(* Returns the time shape with the specified attributes. *)
let construct multiplier divider =
    assert (1 <= multiplier);
    assert (1 <= divider);
    {multiplier = multiplier; divider = divider}

(* Returns a string representation of the time shape ts. *)
let to_string ts =
    assert (is_valid ts);
    Printf.sprintf "%d/%d" ts.multiplier ts.divider

(* Returns the multiplier of the time shape ts. *)
let multiplier ts =
    ts.multiplier

(* Returns the divider of the time shape ts. *)
let divider ts =
    ts.divider

(* Returns the duration in ms specified by the shift s, the duration of a unit of time
 * unit_duration in ms, and the time shape ts. *)
let to_duration ts unit_duration tl =
    assert (1 <= unit_duration);
    assert (is_valid tl);
    let coeff = (float_of_int tl.multiplier) /. (float_of_int tl.divider) in
    let len = coeff ** (float_of_int ts) in
    int_of_float (len *. (float_of_int unit_duration))

