(* Author: Samuele Giraudo
 * Creation: (jul. 2014), apr. 2020
 * Modifications: apr. 2020, may 2020, dec. 2020
 *)

(* Representation of a musical note. *)
type note = {
    (* The step of the note, from 0 to the number of steps by octave minus one. *)
    step : int;

    (* The number of steps by octave. *)
    nb_steps_by_octave : int;

    (* The octave of the note. This value can be negative. *)
    octave : int
}

(* The frequency in Hz of the note of step 0 and octave 0, for any value of number of steps
 * by octave. *)
let origin_frequency = 440.0

(* Tests if n is a note. *)
let is_valid n =
    n.nb_steps_by_octave >= 1 && 0 <= n.step && n.step < n.nb_steps_by_octave

(* Returns the note with the specified attributes. *)
let construct step nb_steps_by_octave octave =
    let n = {step = step; nb_steps_by_octave = nb_steps_by_octave; octave = octave} in
    assert (is_valid n);
    n

(* Returns the step of the note n. *)
let step n =
    assert (is_valid n);
    n.step

(* Returns the number of steps by octave of the note n. *)
let nb_steps_by_octave n =
    assert (is_valid n);
    n.nb_steps_by_octave

(* Returns the octave of the note n. *)
let octave n =
    assert (is_valid n);
    n.octave

(* Returns the string representation of the note n. For instance, 3/12:4 is the note having
 * 3 as step, 4 as octave, and having 12 steps by octave. *)
let to_string n =
    assert (is_valid n);
    Tools.csprintf Tools.Cyan
        (Printf.sprintf "%d/%d:%d" n.step (n.nb_steps_by_octave - 1) n.octave)

(* Tests if the notes n1 and n2 are equivalent. This is the case if n1 and n2 have the same
 * step. These two notes must have the same numbers of steps by octave. *)
let are_equivalent n1 n2 =
    assert (is_valid n1);
    assert (is_valid n2);
    assert (n1.nb_steps_by_octave = n2.nb_steps_by_octave);
    n1.step = n2.step

(* Returns the number of steps between the origin and the note n. The value is negative if n
 * is lower than the origin. *)
let distance_from_origin n =
    assert (is_valid n);
    n.octave * n.nb_steps_by_octave + n.step

(* Returns the frequency in Hz of the note n. *)
let frequency n =
    assert (is_valid n);
    let i = float_of_int (distance_from_origin n)
    and nb_steps_by_octave = float_of_int n.nb_steps_by_octave in
    origin_frequency *. (2. ** (i /. nb_steps_by_octave))

(* Returns the note immediately higher than the note n. *)
let next n =
    assert (is_valid n);
    if n.step = n.nb_steps_by_octave - 1 then
        {n with step = 0; octave = n.octave + 1}
    else
        {n with step = n.step + 1; octave = n.octave}

(* Returns the note immediately lower than the note n. *)
let previous n =
    assert (is_valid n);
    if n.step = 0 then
        {n with step = n.nb_steps_by_octave - 1; octave = n.octave - 1}
    else
        {n with step = n.step - 1; octave = n.octave}

(* Returns the note located from the note n at a distance offset. If the distance is
 * positive, a higher note is returned, and if the distance is negative, a lower note is
 * returned. *)
let rec shift n offset =
    assert (is_valid n);
    if offset = 0 then
        n
    else if offset >= 1 then
        shift (next n) (offset - 1)
    else
        shift (previous n) (offset + 1)

(* Returns the note obtained by increasing the octave of the note n. *)
let increase_octave n =
    assert (is_valid n);
    {n with octave = n.octave + 1}

(* Returns the note obtained by decreasing the octave of the note n. *)
let decrease_octave n =
    assert (is_valid n);
    {n with octave = n.octave - 1}

(* Tests is the note n1 is lower than the note n2. These two notes must have the same
 * numbers of steps by octave. *)
let is_lower n1 n2 =
    assert (is_valid n1);
    assert (is_valid n2);
    assert (n1.nb_steps_by_octave = n2.nb_steps_by_octave);
    match compare n1.octave n2.octave with
        |(-1) -> true
        |1 -> false
        |_ -> n1.step <= n2.step

(* Returns the list of all the notes having nb_steps_by_octave steps by octave and
 * octave as octave. *)
let generate nb_steps_by_octave octave =
    assert (nb_steps_by_octave >= 1);
    List.init nb_steps_by_octave (fun step -> construct step nb_steps_by_octave octave)

