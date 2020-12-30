(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A shape is a map from [0.0, 1.0] to [0.0, 1.0] sending each time value, normalized in the
 * interval [0.0, 1.0], to a coefficient between 0.0 and 1.0 representing its loudness. *)
type shape = Shape of (float -> float)

(* Returns the shape having map as underlying map. *)
let construct map =
    Shape map

(* Returns the underlying map of the shape sh. *)
let to_map sh =
    let Shape map = sh in
    map

(* Returns the composition of the two shapes sh1 and sh2. *)
let compose sh1 (sh2 :shape) : shape=
    construct (fun x -> (to_map sh1 x) *. (to_map sh2 x))

(* Returns the shape specified by the durations max_duration, open_duration and
 * close_duration in ms, w.r.t. a sound having duration as duration in ms. This shape looks
 * like a trapezoid, explaining the name. *)
let trapezoid max_duration open_duration close_duration duration =
    assert (duration >= 1);
    let max_proportion = (float_of_int max_duration) /. (float_of_int duration)
    and open_proportion = (float_of_int open_duration) /. (float_of_int duration)
    and close_proportion = (float_of_int close_duration) /. (float_of_int duration) in
    let shape_max =
        construct
            (fun x ->
                if 0.0 <= x && x < max_proportion then
                    (max_proportion -. x) /. max_proportion
                else
                    0.0)
    in
    let shape_open =
        construct
            (fun x ->
                if 0.0 <= x && x < open_proportion then
                    x /. open_proportion
                else
                    1.0)
    in
    let shape_close =
        construct
            (fun x ->
                if 1.0 -. close_proportion < x && x <= 1.0 then
                    (1.0 -. x) /. close_proportion
                else
                    1.0)
    in
    compose shape_max (compose shape_open shape_close)

(* Returns the shape intended to create a tremolo, where the period of the variations is
 * time ms, the amplitude never goes below the coefficient c, w.r.t. a sound having duration
 * as duration in ms. *)
let tremolo time c duration =
    assert (0 <= time);
    assert (0.0 <= c && c <= 1.0);
    let freq = (float_of_int duration) /. (float_of_int time) in
    let map x =
        let v = cos (2.0 *. Float.pi *. freq *. x) in
        ((c -. 1.0) *. v +. c +. 1.0) /. 2.0
    in
    construct map

