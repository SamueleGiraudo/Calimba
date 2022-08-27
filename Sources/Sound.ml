(* Author: Samuele Giraudo
 * Creation: (jul. 2015), apr. 2020
 * Modifications: apr. 2020, may 2020, jul. 2020, aug. 2020, dec. 2020, jan. 2021, may 2021
 * jun. 2021, aug. 2021, nov. 2021, dec. 2021, jan. 2022, may 2022, aug. 2022
 *)

(* Functional representation of a sound. *)
type sound = {
    (* This map encodes the wave of the sound. This associates with each time in seconds a
     * value. *)
    wave: float -> float;

    (* The duration of the sound in seconds. *)
    duration: float
}

(* Returns the wave of the sound s. *)
let wave s =
    s.wave

(* Returns the duration of the sound s in seconds. *)
let duration s =
    s.duration

(* Returns the value of the wave of the sound s at coordinate x, expressed in seconds. This
 * returns 0.0 if x is outside s. *)
let value s x =
    if 0.0 <= x && x <= s.duration then s.wave x else 0.0

(* Returns the factor of the sound s starting at time start in seconds and having as
 * duration duration in seconds. *)
let factor s start duration =
    assert (start +. duration <= s.duration);
    {wave = (fun x -> s.wave (x +. start)); duration = duration}

(* Returns a sinusoidal sound of frequency freq in Hertz with a duration of duration
 * seconds. *)
let sinusoidal freq duration =
    assert (0.0 <= duration);
    {wave = (fun x -> sin (2.0 *. Float.pi *. freq *. x)); duration = duration}

(* Returns the clipped version of the sound s into the interval -1.0 and 1.0. *)
let cut s =
    let wave x =
        let y = s.wave x in
        copysign (min (abs_float y) 1.0) y
    in
    {s with wave = wave}

(* Returns the sound obtained by multiplying each point of the sound s by the value c. The
 * result is cut. *)
let vertical_scaling c s =
    cut {s with wave = (fun x -> c *. s.wave x)}

(* Returns the sound obtained by scaling horizontally the sound s by the nonnegative value
 * c. *)
let horizontal_scaling c s =
    assert (c >= 0.0);
    {wave = (fun x -> s.wave (x /. c)); duration = s.duration *. c}

(* Returns the sound obtained by adding the sounds s1 and s2. They can have different
 * sizes. The result is cut. *)
let add s1 s2 =
    cut {wave = (fun x -> value s1 x +. value s2 x); duration = max s1.duration s2.duration}

(* Returns the sound obtained by concatenating the sounds s1 and s2. *)
let concatenate s1 s2 =
    let wave x =
        if x <= s1.duration then s1.wave x else s2.wave (x -. s1.duration)
    in
    {wave = wave; duration = s1.duration +. s2.duration}

(* Returns the sound obtained by the pointwise multiplication of the sounds s1 and s2. They
 * can have different sizes. *)
let multiply s1 s2 =
    {wave = (fun x -> value s1 x *. value s2 x); duration = max s1.duration s2.duration}

