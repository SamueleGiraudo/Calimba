(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020, jan. 2021
 *)

(* A concrete time shape is a time shape together with the duration of a unit of time. *)
type concrete_time_shape = {
    (* The time shape. *)
    time_shape : TimeShape.time_shape;

    (* The unit duration of a unit of time in ms. *)
    unit_duration : int
}

(* Returns the concrete time shape with the specified attributes. *)
let construct ts unit_duration =
    assert (unit_duration >= 1);
    {time_shape = ts; unit_duration = unit_duration}

(* Returns a string representation of the concrete time shape cts. *)
let to_string cts =
    Tools.csprintf Tools.Blue
        (Printf.sprintf "%d ms - %s" cts.unit_duration (TimeShape.to_string cts.time_shape))

(* Returns the duration in ms specified by the time degree td for the concrete time shape
 * cts. *)
let time_degree_to_duration cts td =
    let coeff = (float_of_int (TimeShape.multiplier cts.time_shape))
        /. (float_of_int (TimeShape.divider cts.time_shape)) in
    let len = coeff ** (float_of_int (TimeDegree.to_int td)) in
    int_of_float (len *. (float_of_int cts.unit_duration))

