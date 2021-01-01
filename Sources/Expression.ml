(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* A modification encode a way to modify the sound specified by an expression. *)
type modification =
    |Layout of Layout.layout
    |Root of Note.note
    |TimeShape of TimeShape.time_shape
    |UnitDuration of int
    |Synthesizer of Synthesizer.synthesizer
    |Effect of Effect.effect

(* Names in expressions. *)
type name = string

(* Abstract syntax trees for expressions in the Calimba language. *)
type expression =
    |Name of name
    |Atom of Atom.atom
    |Concatenation of expression * expression
    |Composition of expression * expression
    |IncreaseDegrees of expression
    |DecreaseDegrees of expression
    |IncreaseTime of expression
    |DecreaseTime of expression
    |LabeledInsertion of expression * Atom.label * expression
    |SaturatedInsertion of expression * expression
    |Repeat of int * expression
    |Reverse of expression
    |Complement of expression
    |IncreaseOctave of expression
    |DecreaseOctave of expression
    |Let of name * expression * expression
    |Put of modification * expression

(* The errors an expression can contain. *)
type error =
    |UnboundedName of name
    |InvalidContext of Context.context

(* An exception to handle errors in the computation of the tree pattern specified by the
 * expression. *)
exception ValueError

(* Returns a string representation of the error err. *)
let error_to_string err =
    match err with
        |UnboundedName name -> Printf.sprintf "the name %s is unbounded" name
        |InvalidContext ct ->
            Printf.sprintf "the context\n%s\nis invalid" (Context.to_string ct)

(* Returns the context obtained by updating the context ct with the modification m. *)
let update_context ct m =
    match m with
        |Layout l -> Context.update_layout ct l
        |Root r -> Context.update_root ct r
        |TimeShape ts -> Context.update_time_shape ct ts
        |UnitDuration d -> Context.update_unit_duration ct d
        |Synthesizer s -> Context.update_synthesizer ct s
        |Effect _ -> ct

(* Returns the list of all layouts used in the expression e. *)
let rec layouts e =
    match e with
        |Name _ -> []
        |Atom _ -> []
        |Concatenation (e1, e2) -> List.append (layouts e1) (layouts e2)
        |Composition (e1, e2) -> List.append (layouts e1) (layouts e2)
        |IncreaseOctave e' -> layouts e'
        |DecreaseDegrees e' -> layouts e'
        |IncreaseTime e' -> layouts e'
        |DecreaseTime e' -> layouts e'
        |LabeledInsertion (e1, _, e2) -> List.append (layouts e1) (layouts e2)
        |SaturatedInsertion (e1, e2) -> List.append (layouts e1) (layouts e2)
        |Repeat (_, e') -> layouts e'
        |Reverse e' -> layouts e'
        |Complement e' -> layouts e'
        |DecreaseOctave e' -> layouts e'
        |IncreaseDegrees e' -> layouts e'
        |Let (_, e1, e2) -> List.append (layouts e1) (layouts e2)
        |Put (Layout l, e') -> l :: (layouts e')
        |Put (_, e') -> layouts e'

(* Returns the free names in the expression e. *)
let rec free_names e =
    match e with
        |Name name -> [name]
        |Atom _ -> []
        |Concatenation (t1, t2) |Composition (t1, t2)
                |LabeledInsertion (t1, _, t2) |SaturatedInsertion (t1, t2) ->
            List.append (free_names t1) (free_names t2)
        |IncreaseDegrees e' |DecreaseDegrees e' |IncreaseTime e' |DecreaseTime e'
                |Repeat (_, e') |Reverse e' |Complement e'
                |IncreaseOctave e' |DecreaseOctave e' ->
            free_names e'
        |Let (name, e1, e2) ->
            List.append
                (free_names e1)
                (free_names e2 |> List.filter (fun name' -> name' <> name))
        |Put (_, e') -> free_names e'

(* Returns the expression obtained by substituting the free occurrences of the name name in
 * the expression e1 by the expression e2. *)
let rec substitute_free_names e1 name e2 =
    match e1 with
        |Name name' -> if name' = name then e2 else e1
        |Atom _ -> e1
        |Concatenation (e1', e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            Concatenation (e1'', e2'')
        |Composition (e1', e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            Composition (e1'', e2'')
        |IncreaseDegrees e' ->
            let e'' = substitute_free_names e' name e2 in
            IncreaseDegrees e''
        |DecreaseDegrees e' ->
            let e'' = substitute_free_names e' name e2 in
            DecreaseDegrees e''
        |IncreaseTime e' ->
            let e'' = substitute_free_names e' name e2 in
            IncreaseTime e''
        |DecreaseTime e' ->
            let e'' = substitute_free_names e' name e2 in
            DecreaseTime e''
        |LabeledInsertion (e1', lbl, e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            LabeledInsertion (e1'', lbl, e2'')
        |SaturatedInsertion (e1', e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            SaturatedInsertion (e1'', e2'')
        |Repeat (k, e') ->
            let e'' = substitute_free_names e' name e2 in
            Repeat (k, e'')
        |Reverse e' ->
            let e'' = substitute_free_names e' name e2 in
            Reverse e''
        |Complement e' ->
            let e'' = substitute_free_names e' name e2 in
            Complement e''
        |IncreaseOctave e' ->
            let e'' = substitute_free_names e' name e2 in
            IncreaseOctave e''
        |DecreaseOctave e' ->
            let e'' = substitute_free_names e' name e2 in
            DecreaseOctave e''
        |Let (name', e1', e2') ->
            let e1'' = substitute_free_names e1' name e2 in
            let e2'' = if name' = name then e2' else substitute_free_names e2' name e2 in
            Let (name', e1'', e2'')
        |Put (ct, e') ->
            let e'' = substitute_free_names e' name e2 in
            Put (ct, e'')

(* Returns the tree pattern encoded by the expression e. Raises ValueError if there are
 * unbounded names in e. *)
let to_tree_pattern e =
    let rec aux ct e =
        match e with
            |Name _ -> raise ValueError
            |Atom ((Atom.Silence _) as s) -> TreePattern.Atom s
            |Atom ((Atom.Beat _ as b)) -> TreePattern.Atom b
            |Concatenation (e1, e2) ->
                let tp1 = aux ct e1 and tp2 = aux ct e2 in
                TreePattern.Concatenation (tp1, tp2)
            |Composition (e1, e2) ->
                let tp1 = aux ct e1 and tp2 = aux ct e2 in
                TreePattern.Composition (tp1, tp2)
            |IncreaseDegrees e' ->
                let tp = aux ct e' in
                let b = Atom.construct_beat (Degree.construct 1) TimeDegree.zero in
                TreePattern.beat_action b tp
            |DecreaseDegrees e' ->
                let tp = aux ct e' in
                let b = Atom.construct_beat (Degree.construct (-1)) TimeDegree.zero in
                TreePattern.beat_action b tp
            |IncreaseTime e' ->
                let tp = aux ct e' in
                let b = Atom.construct_beat Degree.zero (TimeDegree.construct 1) in
                TreePattern.beat_action b tp
            |DecreaseTime e' ->
                let tp = aux ct e' in
                let b = Atom.construct_beat Degree.zero (TimeDegree.construct (-1)) in
                TreePattern.beat_action b tp
            |LabeledInsertion (e1, lbl, e2) ->
                let tp1 = aux ct e1 and tp2 = aux ct e2 in
                TreePattern.labeled_insertion tp1 lbl tp2
            |SaturatedInsertion (e1, e2) ->
                let tp1 = aux ct e1 and tp2 = aux ct e2 in
                TreePattern.saturated_insertion tp1 tp2 
            |Repeat (k, e') ->
                let tp = aux ct e' in
                TreePattern.repeat k tp
            |Reverse e' ->
                let tp = aux ct e' in
                TreePattern.reverse tp
            |Complement e' ->
                let tp = aux ct e' in
                TreePattern.complement tp
            |IncreaseOctave e' ->
                let ct' = Context.update_root ct (Note.increase_octave (Context.root ct)) in
                let tp = aux ct' e' in
                let p = Performance.from_context ct' in
                TreePattern.Performance (p, tp)
            |DecreaseOctave e' ->
                let ct' = Context.update_root ct (Note.decrease_octave (Context.root ct)) in
                let tp = aux ct' e' in
                let p = Performance.from_context ct' in
                TreePattern.Performance (p, tp)
            |Let (name, e1', e2') ->
                let e' = substitute_free_names e2' name e1' in
                aux ct e'
            |Put (m, e') -> begin
                let ct' = update_context ct m in
                let tp = aux ct' e' in
                match m with
                    |Effect e -> TreePattern.Effect (e, tp)
                    |_ ->
                        let p = Performance.from_context ct' in
                        TreePattern.Performance (p, tp)
            end
    in
    let tp = aux Context.default e in
    let p = Performance.from_context Context.default in
    TreePattern.Performance (p, tp)

(* Returns the sound represented by the expression t. This computation works only if e has
 * no errors. *)
let sound e =
    let tp = to_tree_pattern e in
    TreePattern.sound tp

(* Returns the list of the invalid contexts associated with each atom  appearing in the
 * expression e. For instance, this happens if a root note has not the required number of
 * steps by octave as required by the layout. *)
let invalid_contexts e =
    let rec aux ct e =
        match e with
            |Name _ -> []
            |Atom _ -> if Context.is_inconsistent ct then [ct] else []
            |Concatenation (e1, e2) |Composition (e1, e2)
                    |LabeledInsertion (e1, _, e2) |SaturatedInsertion (e1, e2) ->
                List.append (aux ct e1) (aux ct e2)
            |IncreaseDegrees e' |DecreaseDegrees e' |IncreaseTime e' |DecreaseTime e'
                    |Repeat (_, e') |Reverse e' |Complement e'
                    |IncreaseOctave e' |DecreaseOctave e' ->
                aux ct e'
            |Let (name, e1', e2') ->
                let e' = substitute_free_names e2' name e1' in
                aux ct e'
            |Put (m, e') -> aux (update_context ct m) e'
    in
    aux Context.default e

(* Returns the list of the errors in the expression e. *)
let errors e =
    let tmp_1 = free_names e
        |> List.sort_uniq compare
        |> List.map (fun name -> UnboundedName name) in
    if tmp_1 <> [] then
        tmp_1
    else
        let tmp_2 = invalid_contexts e
            |> List.sort_uniq compare
            |> List.map (fun ct -> InvalidContext ct) in
        List.concat [tmp_1; tmp_2]

(* Returns the sound obtained by interpreting the expression e. *)
let interpret e verbose =
    if verbose then
        Tools.print_information "Generating sound.";
    let clock_start = Sys.time () in
    let sound = sound e in
    let clock_end = Sys.time () in
    let time_ms = int_of_float ((clock_end -. clock_start) *. 1000.0) in
    let tp = to_tree_pattern e in
    if verbose then
        Tools.print_information (Printf.sprintf "Sound generated in %d ms." time_ms);
    let dur_ms = Sound.duration sound in
    let dur_hour = (dur_ms / 1000) / 3600
    and dur_min = ((dur_ms / 1000) / 60) mod 60
    and dur_sec = (dur_ms / 1000) mod 60
    and dur_ms' = dur_ms mod 1000 in
    if verbose then begin
        Printf.printf "Characteristics:\n";
        Printf.printf "    Duration: %d ms (%dh %dm %ds %dms)\n"
            dur_ms dur_hour dur_min dur_sec dur_ms';
        Printf.printf "    Nb. beats: %d\n" (TreePattern.arity tp);
        Printf.printf "    Nb. leaves: %d\n" (TreePattern.nb_leaves tp);
        Printf.printf "    Nb. int. nodes: %d\n" (TreePattern.nb_internal_nodes tp);
        Printf.printf "    Height: %d\n" (TreePattern.height tp)
    end;
    sound

(* Interprets the expression e and plays the specified sound. *)
let interpret_and_play e verbose =
    let s = interpret e verbose in
    if verbose then
        Tools.print_information "Playing sound.";
    Sound.play s;
    if verbose then
        Tools.print_information "End of play."

(* Interprets the expression e and write the specified sound as a PCM file at path path. *)
let interpret_and_write e path verbose =
    assert (not (Sys.file_exists path));
    let s = interpret e verbose in
    if verbose then
        Tools.print_information (Printf.sprintf "Writing sound in file %s." path);
    Sound.write_buffer s;
    ignore (Sys.command (Printf.sprintf "cp %s %s" Sound.buffer_path_file path));
    if verbose then
        Tools.print_information "Writing done."

(* Draws the signal of the sound specified by the expression e. The drawn portion starts at
 * start_ms ms and lasts len_ms ms. *)
let interpret_and_draw e start_ms len_ms verbose =
    if verbose then
        Tools.print_information "Drawing sound.";
    let s = interpret e true in
    let dur = Sound.duration s in
    let start_ms = max 0 (min start_ms dur) in
    let len_ms = max 0 (min len_ms (dur - start_ms)) in
    let start_x = Sound.duration_to_size start_ms in
    let len_x = Sound.duration_to_size len_ms in
    let s' = Sound.factor s start_x len_x in
    Sound.draw s';
    if verbose then
        Tools.print_information "Drawing done."

(* Prints some analysis information about the expression e. *)
let interpret_and_analyse e verbose =
    if verbose then
        Tools.print_information "Printing analysis information.";
    let l_lst = layouts e |> List.sort_uniq compare in
    l_lst |> List.iter
        (fun l ->
            Printf.printf "Layout: %s\n" (Layout.to_string l);

            (* Computation of some data. *)
            let nbs = Layout.nb_steps_by_octave l in
            let nbmd = Layout.nb_minimal_degrees l in

            (* Prints the number of steps by octave. *)
            Printf.printf "    Nb steps by octave: %d\n" nbs;

            (* Prints the number of minimal degrees. *)
            Printf.printf "    Nb of minimal degrees: %d\n" nbmd;

            (* Prints the position of the layout in the list of all layouts having the same
             * number of steps by octave and the same number of minimal degrees, sorted
             * lexicographically. *)
            let all_layouts = Layout.generate nbs nbmd in
            let pos = Tools.occurrences all_layouts l in
            Printf.printf "    Index: %d over a total of %d layouts having %d steps by \
                octave and %d minimal degrees.\n"
                (List.hd pos) (List.length all_layouts) nbs nbmd;

            (* Prints the distance vector. *)
            Printf.printf "    Distance vector: %s\n"
                (Layout.distance_vector l |> List.map string_of_int |> String.concat " ");

            (* Prints the interval vectors. *)
            Printf.printf "    Interval vector:          %s\n"
                (Layout.interval_vector l |> List.map string_of_int |> String.concat " ");
            Printf.printf "    Internal interval vector: %s\n"
                (Layout.internal_interval_vector l |> List.map string_of_int
                    |> String.concat " ");

            (* Prints the mirror layout. *)
            Printf.printf "    Mirror: %s\n" (Layout.to_string (Layout.mirror l));

            (* Prints the dual layout. *)
            Printf.printf "    Dual: %s\n" (Layout.to_string (Layout.dual l));

            (* Prints the rotation class. *)
            Printf.printf "    Rotation class: %s\n"
                (Layout.rotation_class l |> List.map Layout.to_string
                    |> String.concat ", ");
            Printf.printf "    Minimal in rotation class: %s\n"
                (if Layout.is_minimal_in_rotation_class l then "yes" else "no");

            (* Prints the complement rotation class. *)
            Printf.printf "    Complement rotation class: %s\n"
                (Layout.complement_rotation_class l |> List.map Layout.to_string
                    |> String.concat ", ");

            (* Prints the best approximations of just intonation intervals. *)
            Printf.printf "    Approximations of just intonation intervals:\n";
            let ratios_and_names =
                [(1.0, "unison"); (6.0 /. 5.0, "minor third"); (5.0 /. 4.0, "major third");
                 (4.0 /. 3.0, "fourth"); (3.0 /. 2.0, "fifth"); (8.0 /. 5.0, "minor sixth");
                 (5.0 /. 3.0, "major sixth"); (2.0, "octave")] in
            ratios_and_names |> List.iter
                (fun (ratio, name) ->
                    let (ls1, ls2) = Layout.best_interval_for_ratio l ratio in
                    let acc = Tools.accuracy ratio (Layout.frequency_ratio l ls1 ls2) in
                    Printf.printf "        For %.2f %-11s: %s - %s with error of %+.2f%%\n"
                        ratio name
                        (Degree.to_string ls1)
                        (Degree.to_string ls2)
                        (100.0 *. acc));

            (* Prints all the nonequivalent induced rooted layouts. *)
            let rl_lst = RootedLayout.generate_nonequivalent l 0 in
            Printf.printf "    Nonequivalent rooted layouts:\n";
            Printf.printf "        Cardinal: %d\n" (List.length rl_lst);
            Printf.printf "        Rooted layouts:\n";
            rl_lst |> List.iter
                (fun rl ->
                    Printf.printf "            %s with notes" (RootedLayout.to_string rl);
                    let notes = RootedLayout.first_notes rl in
                    Printf.printf " %s\n"
                        (notes |> List.map Note.to_string |> String.concat " "));

            (* Prints all the circular sub-layouts and all the degrees to obtain these. *)
            Printf.printf "    Circular sub-layouts:\n";
            let csl = Layout.circular_sub_layouts l in
            List.init nbmd (fun n -> n + 1) |> List.rev
                |> List.iter
                (fun n ->
                    let csl' = csl |> List.filter
                        (fun l' -> Layout.nb_minimal_degrees l' = n) in
                    Printf.printf "        With %d degrees:\n" n;
                    Printf.printf "            Cardinal: %d\n" (List.length csl');
                    csl' |> List.iter
                        (fun l' ->
                            Printf.printf "            %s: " (Layout.to_string l');
                            let deg_lst = Layout.degrees_for_circular_inclusion l' l in
                            Printf.printf "%d occ." (List.length deg_lst);
                            let deg_str = deg_lst |> List.map
                                (fun lst ->
                                    let str = lst |> List.map Degree.to_string
                                        |> String.concat " " in
                                    "[" ^ str ^ "]")
                                |> String.concat " "
                            in
                            Printf.printf " at %s\n" deg_str)));

    if verbose then
        Tools.print_information "Printing done."

(* Interprets the expression e and prints its tree pattern. *)
let interpret_and_print_tree_pattern e verbose =
    if verbose then
        Tools.print_information "Printing the tree pattern specified by the program.";
    let tp = to_tree_pattern e in
    Printf.printf "%s\n" (TreePattern.to_string tp);
    if verbose then
        Tools.print_information "Printing done."

