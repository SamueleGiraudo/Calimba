(* Author: Samuele Giraudo
 * Creation: aug. 2020
 * Modifications: aug. 2020, dec. 2020
 *)

(* A time layout specifies how the durations of beats and rests are altered. This is a pair
 * (m, d) used in the following way. If the duration of a beat or a rest has to be
 * increased (resp. decreased), its new duration is computed by multiplying (resp. dividing)
 * it by m/d. *)
type time_layout = {
    multiplier : int;
    divider : int
}

(* A time shift is an integer value encoding the number of wanted increments
 * (resp. decrements) of times if it is positive (resp. negative). *)
type time_shift = int

(* Tests if tl is a valid time layout. *)
let is_valid tl =
    tl.multiplier >= 1 && tl.divider >= 1

(* Returns the time layout with the specified attributes. *)
let construct multiplier divider =
    assert (1 <= multiplier);
    assert (1 <= divider);
    {multiplier = multiplier; divider = divider}

(* Returns a string representation of the time layout tl. *)
let to_string tl =
    assert (is_valid tl);
    Printf.sprintf "%d/%d" tl.multiplier tl.divider

(* Returns a string representation of the time shift ts. *)
let time_shift_to_string ts =
    if ts <= 0 then
        String.make (-ts) '<'
    else
        String.make ts '>'

(* Returns the duration in ms specified by the time shift ts, the duration of a unit of
 * time unit_duration in ms, and the time layout tl. *)
let to_duration ts unit_duration tl =
    assert (1 <= unit_duration);
    assert (is_valid tl);
    let coeff = (float_of_int tl.multiplier) /. (float_of_int tl.divider) in
    let len = coeff ** (float_of_int ts) in
    int_of_float (len *. (float_of_int unit_duration))


(* The test function of the module. *)
let test () =
    print_string "TimeLayout\n";
    true

