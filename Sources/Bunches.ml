(* Author: Samuele Giraudo
 * Creation: (aug. 2021), jul. 2023
 * Modifications: jul. 2023
 *)

(* A type to specify a part (a bunch) of a sound. *)
type bunches = {
    (* The starting time of the bunch expressed in seconds. If it is None, then the
     * specified starting time is the origin. *)
    start: float option;

    (* The length of the bunch expressed in second. If it is None, then the specified length
     * is the  maximal possible one. *)
    length: float option
}

(* Returns the bunch with the specified attributes. *)
let construct start length =
    let start = if start |> Options.value 0.0 < 0.0 then None else start in
    let length = if length |> Options.value 0.0 < 0.0 then None else length in
    {start = start; length = length}

(* Returns an option on the starting time of the bunch b. *)
let start b =
    b.start

(* Returns an option on the length of the bunch b. *)
let length b =
    b.length

(* Returns the factor of the sound s specified by the bunch b. *)
let cut_sound s b =
    let dur = Sounds.duration s in
    let start = max 0.0 (min (start b|> Options.value 0.0) dur) in
    let end_time = dur -. start in
    let len = max 0.0 (min (length b |> Options.value end_time) end_time) in
    Sounds.factor s start len

