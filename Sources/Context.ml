(* Author: Samuele Giraudo
 * Creation: aug. 2020
 * Modifications: aug. 2020, dec. 2020
 *)

(* A context specifies how to translate the atoms of a tree pattern into a sound. *)
type context = {
    (* The layout. *)
    layout : Layout.layout;

    (* The root note. *)
    root : Note.note;

    (* The time layout. *)
    time_shape : TimeShape.time_shape;

    (* The unit duration in ms. *)
    unit_duration : int;

    (* The synthesizer, specifying the timbre of the sound. *)
    synthesizer : Synthesizer.synthesizer;
}

(* Returns a string representation of the context ct. *)
let to_string ct =
    Printf.sprintf "[layout: %s; root: %s; time layout: %s; duration: %s; synthesizer: %s]"
        (Layout.to_string ct.layout) (Note.to_string ct.root)
        (TimeShape.to_string ct.time_shape)
        (string_of_int ct.unit_duration)
        (Synthesizer.to_string ct.synthesizer)

(* Returns the default context. *)
let default =
    let t = Synthesizer.scale_timbre 0.28 (Synthesizer.geometric_timbre 0.29) in
    let synth = Synthesizer.construct t 4000 40 20 in
    {layout = Layout.natural_minor;
    root = Note.construct 0 12 0;
    time_shape = TimeShape.construct 2 1;
    unit_duration = 500;
    synthesizer = synth}

(* Tests if the context ct is valid. *)
let is_valid ct =
    Layout.nb_steps_by_octave ct.layout = Note.nb_steps_by_octave ct.root
        && ct.unit_duration >= 1

(* Returns the layout of the context ct. *)
let layout ct =
    assert (is_valid ct);
    ct.layout

(* Returns the root note of the context ct. *)
let root ct =
    assert (is_valid ct);
    ct.root

(* Returns the time shape of the context ct. *)
let time_shape ct =
    assert (is_valid ct);
    ct.time_shape

(* Returns the duration in ms of a unit of time of the context ct. *)
let unit_duration ct =
    assert (is_valid ct);
    ct.unit_duration

(* Returns the synthesizers of the context ct. *)
let synthesizer ct =
    assert (is_valid ct);
    ct.synthesizer

(* Returns the number of degrees in the layout of the context ct. *)
let nb_degrees ct =
    assert (is_valid ct);
    Layout.nb_degrees ct.layout

(* Returns the context obtained by changing the layout of the context ct by l. *)
let update_layout ct l =
    assert (is_valid ct);
    assert (Layout.is_valid l);
    {ct with layout = l}

(* Returns the context obtained by changing the root note of the context ct by r. *)
let update_root ct r =
    assert (is_valid ct);
    {ct with root = r}

(* Returns the context obtained by changing the time shape of the context ct by ts. *)
let update_time_shape ct ts =
    assert (is_valid ct);
    assert (TimeShape.is_valid ts);
    {ct with time_shape = ts}

(* Returns the context obtained by changing the duration of a unit of time of the context
 * ct by d in ms. *)
let update_unit_duration ct d =
    assert (is_valid ct);
    assert (1 <= d);
    {ct with unit_duration = d}

(* Returns the context obtained by changing the synthesizer of the context ct by s. *)
let update_synthesizer ct s =
    assert (is_valid ct);
    assert (Synthesizer.is_valid s);
    {ct with synthesizer = s}

(* Returns the performance (the way an atom is transformed into a sound) encoded by the
 * context ct. *)
let to_performance ct =
    assert (is_valid ct);
    fun a ->
        match a with
            |TreePattern.Silence tss ->
                let cts = ConcreteTimeShape.construct ct.time_shape ct.unit_duration in
                let dur = ConcreteTimeShape.time_shift_to_duration cts tss in
                Sound.silence dur
            |TreePattern.Beat (ls, tss, _) ->
                let rl = RootedLayout.construct ct.layout ct.root in
                let note = RootedLayout.layout_shift_to_note rl ls in
                let cts = ConcreteTimeShape.construct ct.time_shape ct.unit_duration in
                let dur = ConcreteTimeShape.time_shift_to_duration cts tss in
                Synthesizer.generate_sound_note ct.synthesizer note dur

