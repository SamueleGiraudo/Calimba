(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020, jan. 2021
 *)

(* An effect is a map transforming an input sound into an output one. It is important to
 * have a separate way to encode effects because one cannot put this information into a
 * performance. Indeed, a performance encodes how to send a single atom onto a sound while
 * in an effect, the whole sound resulting in the performance of several atoms may be
 * processed (for instance for delays). *)
type effect = Effect of (Sound.sound -> Sound.sound)

(* Returns the scaling effect with coefficient c. *)
let scale c =
    assert (0.0 <= c);
    Effect (Sound.scale c)

(* Returns the clip effect. This transforms a sound by replacing each point having absolute
 * value greater than c into c, with the same sign. *)
let clip c =
    assert (0.0 <= c && c <= 1.0);
    Effect (Sound.clip c)

(* Returns the delay effect where time is the shift duration in ms and c is the scaling
 * coefficient. This adds to the sound a shifted version of the same sound by time ms scaled
 * by the coefficient c. *)
let delay time c =
    assert (0 <= time);
    assert (0.0 <= c);
    let map s =
        let s' = Sound.concatenate (Sound.silence time) s in
        Sound.prefix (Sound.add s (Sound.scale c s')) (Sound.size s)
    in
    Effect map

(* Returns the tremolo effect. This transforms a sound by applying a tremolo (periodic
 * variation of the volume). The periodic variation of the tremolo is of time ms, and the
 * amplitude never goes below the coefficient c. *)
let tremolo time c =
    assert (0 <= time);
    assert (0.0 <= c && c <= 1.0);
    let map s =
        Sound.apply_shape s (Shape.tremolo time c (Sound.duration s))
    in
    Effect map

(* Returns the sound obtained from the sound s by applying the effect e. *)
let apply e s =
    let Effect map = e in
    map s

let compose e1 e2 =
    let Effect m1 = e1 and Effect m2 = e2 in
    Effect (fun s -> m1 (m2 s))

let identity =
    Effect Fun.id

