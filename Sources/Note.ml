(* Author: Samuele Giraudo
 * Creation: (jul. 2014), apr. 2020
 * Modifications: apr. 2020, may 2020, dec. 2020
 *)

(* Representation of a musical note. *)
type note = {
    (* The index of the step of the note, from 0 to the number of steps by octave. *)
    step_index : int;

    (* The number of steps by octave. *)
    nb_steps_by_octave : int;

    (* The index of the octave of the note. This value can be negative. *)
    octave_index : int
}

(* The frequency in Hz of the note of step index 0 and octave index 0, for any value of
 * number of steps by octave. *)
let origin_frequency = 440.0

(* Tests if n is a note. *)
let is_valid n =
    n.nb_steps_by_octave >= 1 && 0 <= n.step_index && n.step_index < n.nb_steps_by_octave

(* Returns the note with the specified attributes. *)
let construct step_index nb_steps_by_octave octave_index =
    let n = {step_index = step_index;
        nb_steps_by_octave = nb_steps_by_octave;
        octave_index = octave_index} in
    assert (is_valid n);
    n

(* Returns the step index of the note n. *)
let step_index n =
    assert (is_valid n);
    n.step_index

(* Returns the number of steps by octave of the note n. *)
let nb_steps_by_octave n =
    assert (is_valid n);
    n.nb_steps_by_octave

(* Returns the octave index of the note n. *)
let octave_index n =
    assert (is_valid n);
    n.octave_index

(* Returns the string representation of the note n. For instance, 3/12:4 is the note having
 * 3 as step index, 4 as octave index, and having 12 steps by octave. *)
let to_string n =
    assert (is_valid n);
    Tools.csprintf Tools.Cyan
        (Printf.sprintf "%d/%d:%d" n.step_index (n.nb_steps_by_octave - 1) n.octave_index)

(* Tests if the notes n1 and n2 are equivalent. This is the case if n1 and n2 have the same
 * step_index. *)
let are_equivalent n1 n2 =
    assert (is_valid n1);
    assert (is_valid n2);
    assert (n1.nb_steps_by_octave = n2.nb_steps_by_octave);
    n1.step_index = n2.step_index

(* Returns the number of steps from the origin and the note n. The value is negative if n is
 * lower than the origin. *)
let distance_from_origin n =
    assert (is_valid n);
    n.octave_index * n.nb_steps_by_octave + n.step_index

(* Returns the frequency in Hz of the note n. *)
let frequency n =
    assert (is_valid n);
    let i = float_of_int (distance_from_origin n)
    and nb_steps_by_octave = float_of_int n.nb_steps_by_octave in
    origin_frequency *. (2. ** (i /. nb_steps_by_octave))

(* Returns the note immediately higher than the note n. *)
let next n =
    assert (is_valid n);
    if n.step_index = n.nb_steps_by_octave - 1 then
        {n with step_index = 0; octave_index = n.octave_index + 1}
    else
        {n with step_index = n.step_index + 1; octave_index = n.octave_index}

(* Returns the note immediately lower than the note n. *)
let previous n =
    assert (is_valid n);
    if n.step_index = 0 then
        {n with step_index = n.nb_steps_by_octave - 1; octave_index = n.octave_index - 1}
    else
        {n with step_index = n.step_index - 1; octave_index = n.octave_index}

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

(* Tests is the note n1 is lower than the note n2. These two notes must have the same
 * numbers of steps by octave. *)
let is_lower n1 n2 =
    assert (is_valid n1);
    assert (is_valid n2);
    assert (n1.nb_steps_by_octave = n2.nb_steps_by_octave);
    if n1.octave_index < n2.octave_index then
        true
    else if n1.octave_index > n2.octave_index then
        false
    else
        n1.step_index <= n2.step_index

(* Returns the note obtained from the note n by changing its octave index by
 * octave_index. *)
let change_octave_index n octave_index =
    assert (is_valid n);
    {n with octave_index = octave_index}

(* Returns the note obtained by incrementing the octave index of the note n. *)
let increment_octave_index n =
    assert (is_valid n);
    change_octave_index n (n.octave_index + 1)

(* Returns the note obtained by decrementing the octave index of the note n. *)
let decrement_octave_index n =
    assert (is_valid n);
    change_octave_index n (n.octave_index - 1)

(* Returns the list of all the notes having nb_steps_by_octave steps by octave and
 * octave_index as octave index. *)
let generate nb_steps_by_octave octave_index =
    assert (nb_steps_by_octave >= 1);
    List.init nb_steps_by_octave
        (fun step ->
            {step_index = step;
            nb_steps_by_octave = nb_steps_by_octave;
            octave_index = octave_index})

