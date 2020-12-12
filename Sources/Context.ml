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
    time_layout : TimeLayout.time_layout;

    (* The unit duration in ms. *)
    unit_duration : int;

    (* The synthesizer, specifying the timbre of the sound. *)
    synthesizer : Synthesizer.synthesizer;
}

(* Returns a string representation of the context ct. *)
let to_string ct =
    Printf.sprintf "layout: %s; root: %s; time layout:%s, duration: %s; synthesizer: %s"
        (Layout.to_string ct.layout) (Note.to_string ct.root)
        (TimeLayout.to_string ct.time_layout)
        (string_of_int ct.unit_duration)
        (Synthesizer.to_string ct.synthesizer)

(* Returns the default context. *)
let default =
    let t = Synthesizer.scale_timbre 0.15 (Synthesizer.geometric_timbre 0.24) in
    let synth = Synthesizer.construct t 4000 50 20 in
    {layout = Layout.natural_minor;
    root = Note.construct 0 12 (-2);
    time_layout = TimeLayout.construct 2 1;
    unit_duration = 500;
    synthesizer = synth}

(* Tests if the context ct is valid. *)
let is_valid ct =
    Layout.nb_steps_by_octave ct.layout = Note.nb_steps_by_octave ct.root
        && ct.unit_duration >= 1

(* Returns the layout of the context ct. *)
let layout ct =
    ct.layout

(* Returns the root note of the context ct. *)
let root ct =
    ct.root

(* Returns the time layout of the context ct. *)
let time_layout ct =
    ct.time_layout

(* Returns the duration in ms of a unit of time of the context ct. *)
let unit_duration ct =
    ct.unit_duration

(* Returns the synthesizers of the context ct. *)
let synthesizer ct =
    ct.synthesizer

(* Returns the number of degrees in the layout of the context ct. *)
let nb_degrees ct =
    Layout.nb_degrees ct.layout

(* Returns the context obtained by changing the layout of the context ct by l. *)
let update_layout ct l =
    {ct with layout = l}

(* Returns the context obtained by changing the root note of the context ct by r. *)
let update_root ct r =
    {ct with root = r}

(* Returns the context obtained by changing the time layout of the context ct by tl. *)
let update_time_layout ct tl =
    {ct with time_layout = tl}

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
            |TreePattern.Silence ts ->
                let dur = TimeLayout.to_duration ts ct.unit_duration ct.time_layout in
                Sound.silence dur
            |TreePattern.Beat (s, ts, _) ->
                let rl = RootedLayout.construct ct.layout ct.root in
                let deg = Shift.to_extended_degree (nb_degrees ct) s in
                let note = RootedLayout.extended_degree_to_note rl deg in
                let dur = TimeLayout.to_duration ts ct.unit_duration ct.time_layout in
                Synthesizer.generate_sound_note ct.synthesizer note dur


(* The test function of the module. *)
let test () =
    print_string "Context\n";
    true

