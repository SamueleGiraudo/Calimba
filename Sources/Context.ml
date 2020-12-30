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
    synthesizer : Synthesizer.synthesizer
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
    let t = Timbre.scale 0.28 (Timbre.geometric 0.29) in
    let synth = Synthesizer.construct t 4000 40 20 in
    {layout = Layout.natural_minor;
    root = Note.construct 0 12 0;
    time_shape = TimeShape.construct 2 1;
    unit_duration = 500;
    synthesizer = synth}

(* Tests if the context ct is inconsistent. *)
let is_inconsistent ct =
    Layout.nb_steps_by_octave ct.layout <> Note.nb_steps_by_octave ct.root

(* Returns the layout of the context ct. *)
let layout ct =
    ct.layout

(* Returns the root note of the context ct. *)
let root ct =
    ct.root

(* Returns the time shape of the context ct. *)
let time_shape ct =
    ct.time_shape

(* Returns the duration in ms of a unit of time of the context ct. *)
let unit_duration ct =
    ct.unit_duration

(* Returns the synthesizers of the context ct. *)
let synthesizer ct =
    ct.synthesizer

(* Returns the number of minimal degrees in the layout of the context ct. *)
let nb_minimal_degrees ct =
    Layout.nb_minimal_degrees ct.layout

(* Returns the context obtained by changing the layout of the context ct by l. *)
let update_layout ct l =
    {ct with layout = l}

(* Returns the context obtained by changing the root note of the context ct by r. *)
let update_root ct r =
    {ct with root = r}

(* Returns the context obtained by changing the time shape of the context ct by ts. *)
let update_time_shape ct ts =
    {ct with time_shape = ts}

(* Returns the context obtained by changing the duration of a unit of time of the context
 * ct by d in ms. *)
let update_unit_duration ct d =
    assert (1 <= d);
    {ct with unit_duration = d}

(* Returns the context obtained by changing the synthesizer of the context ct by s. *)
let update_synthesizer ct s =
    {ct with synthesizer = s}

(* Returns the performance (the way an atom is transformed into a sound) encoded by the
 * context ct. *)
let to_performance ct =
    fun a ->
        match a with
            |TreePattern.Silence td ->
                let cts = ConcreteTimeShape.construct ct.time_shape ct.unit_duration in
                let dur = ConcreteTimeShape.time_degree_to_duration cts td in
                Sound.silence dur
            |TreePattern.Beat (d, td, _) ->
                let rl = RootedLayout.construct ct.layout ct.root in
                let note = RootedLayout.degree_to_note rl d in
                let cts = ConcreteTimeShape.construct ct.time_shape ct.unit_duration in
                let dur = ConcreteTimeShape.time_degree_to_duration cts td in
                Synthesizer.generate_sound_note ct.synthesizer note dur

