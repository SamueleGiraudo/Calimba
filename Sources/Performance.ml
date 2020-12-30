(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A performance is a map specifying how to associate with any atom a sound. *)
type performance = Performance of (Atom.atom -> Sound.sound)

(* Returns the performance encoded by the context ct. *)
let from_context ct =
    let map a =
        match a with
            |Atom.Silence td ->
                let cts = ConcreteTimeShape.construct
                    (Context.time_shape ct)
                    (Context.unit_duration ct) in
                let dur = ConcreteTimeShape.time_degree_to_duration cts td in
                Sound.silence dur
            |Atom.Beat (d, td, _) ->
                let rl = RootedLayout.construct (Context.layout ct) (Context.root ct) in
                let note = RootedLayout.degree_to_note rl d in
                let cts = ConcreteTimeShape.construct
                    (Context.time_shape ct)
                    (Context.unit_duration ct) in
                let dur = ConcreteTimeShape.time_degree_to_duration cts td in
                Synthesizer.generate_sound_note (Context.synthesizer ct) note dur
    in
    Performance map

(* Returns the performance wherein each atom is sent to the empty sound. *)
let empty =
    Performance (fun _ -> Sound.empty)

(* Returns the sound associated with the atom a w.r.t. the performance p. *)
let atom_to_sound p a =
    let Performance map = p in
    map a

