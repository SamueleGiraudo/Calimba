(* Author: Samuele Giraudo
 * Creation: (jul. 2015), apr. 2020
 * Modifications: apr. 2020, may 2020, jul. 2020, aug. 2020, dec. 2020, jan. 2021, may 2021
 * jun. 2021, aug. 2021, nov. 2021, dec. 2021, jan. 2022, may 2022, aug. 2022, nov. 2022,
 * jul. 2023
 *)

(* Functional representation of a sound. *)
type sounds = {
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
    assert (start >= 0.0);
    assert (start +. duration <= s.duration);
    {wave = (fun x -> s.wave (x +. start)); duration = duration}

(* Returns a sinusoidal sound of frequency freq in Hertz with a duration of duration
 * seconds. *)
let sinusoidal freq duration =
    assert (0.0 <= duration);
    {wave = (fun x -> sin (2.0 *. Float.pi *. freq *. x)); duration = duration}

(* Returns the sound obtained by reversing the sound s. *)
let reverse s =
    {s with wave = (fun x -> s.wave (s.duration -. x))}

(* Returns the sound obtained by multiplying each point of the sound s by the value c. The
 * result is cut. *)
let vertical_scaling c s =
    {s with wave = (fun x -> c *. s.wave x)}

(* Returns the sound obtained by scaling horizontally the sound s by the value c. *)
let rec horizontal_scaling c s =
    if c = 0.0 then
        {wave = Fun.const 0.0; duration = 0.0}
    else if c > 0.0 then
        {wave = (fun x -> s.wave (x /. c)); duration = s.duration *. c}
    else
        horizontal_scaling (Float.abs c) (reverse s)

(* Returns the sound obtained by performing point by point the binary operation op on the
 * waves of the sounds s1 and s2. *)
let pointwise_operation op s1 s2 =
    {wave = (fun x -> op (value s1 x) (value s2 x)); duration = max s1.duration s2.duration}

(* Returns the sound obtained by adding the sounds s1 and s2. They can have different
 * sizes. *)
let add s1 s2 =
    pointwise_operation (+.) s1 s2

(* Returns the sound obtained by the pointwise multiplication of the sounds s1 and s2. They
 * can have different sizes. *)
let multiply s1 s2 =
    pointwise_operation ( *.) s1 s2

(* Returns the sound obtained by concatenating the sounds s1 and s2. *)
let concatenate s1 s2 =
    let wave x =
        if x <= s1.duration then s1.wave x else s2.wave (x -. s1.duration)
    in
    {wave = wave; duration = s1.duration +. s2.duration}

