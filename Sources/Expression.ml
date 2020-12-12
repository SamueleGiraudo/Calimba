(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020
 *)

(* A modification brings an element to modify the sound specified by an expression. *)
type modification =
    |Layout of Layout.layout
    |Root of Note.note
    |TimeLayout of TimeLayout.time_layout
    |UnitDuration of int
    |Synthesizer of Synthesizer.synthesizer
    |Effect of TreePattern.effect

(* Names in expressions. *)
type name = string

(* Abstract syntax trees for expressions in the calimba language. *)
type expression =
    |Name of name
    |Atom of TreePattern.atom
    |Concatenation of expression * expression
    |Composition of expression * expression
    |IncreaseOctave of expression
    |DecreaseOctave of expression
    |IncreaseTime of expression
    |DecreaseTime of expression
    |Insertion of expression * int * expression
    |LabelInsertion of expression * TreePattern.label * expression
    |BinaryInsertion of expression * expression
    |Repeat of int * expression
    |Reverse of expression
    |Complement of expression
    |Let of name * expression * expression
    |Put of modification * expression

(* The errors an expression can contain. *)
type error =
    |UnboundedName of name
    |InvalidContext of Context.context

exception ValueError

let error_to_string err =
    match err with
        |UnboundedName name -> Printf.sprintf "The name %s is unbounded." name
        |InvalidContext ct ->
            Printf.sprintf "The context %s is invalid." (Context.to_string ct)

(* Returns the context specified by the list lst of modifications. The modifications come
 * from the newest to the oldest one. *)
let modification_list_to_context lst =
    lst |> List.rev |> List.fold_left
        (fun ct m ->
            match m with
                |Layout l -> Context.update_layout ct l
                |Root r -> Context.update_root ct r
                |TimeLayout tl -> Context.update_time_layout ct tl
                |UnitDuration d -> Context.update_unit_duration ct d
                |Synthesizer s -> Context.update_synthesizer ct s
                |Effect _ -> ct)
        Context.default

(* Returns the free names in the expression e. *)
let rec free_names e =
    match e with
        |Name name -> [name]
        |Atom _ -> []
        |Concatenation (t1, t2) |Composition (t1, t2) |Insertion (t1, _, t2)
                |LabelInsertion (t1, _, t2) |BinaryInsertion (t1, t2) ->
            List.append (free_names t1) (free_names t2)
        |IncreaseOctave e' |DecreaseOctave e' |IncreaseTime e' |DecreaseTime e'
                |Repeat (_, e') |Reverse e' |Complement e' ->
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
        |IncreaseOctave e' ->
            let e'' = substitute_free_names e' name e2 in
            IncreaseOctave e''
        |DecreaseOctave e' ->
            let e'' = substitute_free_names e' name e2 in
            DecreaseOctave e''
        |IncreaseTime e' ->
            let e'' = substitute_free_names e' name e2 in
            IncreaseTime e''
        |DecreaseTime e' ->
            let e'' = substitute_free_names e' name e2 in
            DecreaseTime e''
        |Insertion (e1', i, e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            Insertion (e1'', i, e2'')
        |LabelInsertion (e1', lbl, e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            LabelInsertion (e1'', lbl, e2'')
        |BinaryInsertion (e1', e2') ->
            let e1'' = substitute_free_names e1' name e2
            and e2'' = substitute_free_names e2' name e2 in
            BinaryInsertion (e1'', e2'')
        |Repeat (k, e') ->
            let e'' = substitute_free_names e' name e2 in
            Repeat (k, e'')
        |Reverse e' ->
            let e'' = substitute_free_names e' name e2 in
            Reverse e''
        |Complement e' ->
            let e'' = substitute_free_names e' name e2 in
            Complement e''
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
    let rec aux m_lst e =
        match e with
            |Name _ -> raise ValueError
            |Atom (TreePattern.Silence ts) -> TreePattern.Atom (TreePattern.Silence ts)
            |Atom (TreePattern.Beat (s, ts, lbl)) ->
                TreePattern.Atom (TreePattern.Beat (s, ts, lbl))
            |Concatenation (e1, e2) ->
                let tp1 = aux m_lst e1 and tp2 = aux m_lst e2 in
                TreePattern.Concatenation (tp1, tp2)
            |Composition (e1, e2) ->
                let tp1 = aux m_lst e1 and tp2 = aux m_lst e2 in
                TreePattern.Composition (tp1, tp2)
            |IncreaseOctave e' ->
                let tp = aux m_lst e' in
                TreePattern.beat_action (Shift.construct 0 1) 0 tp
            |DecreaseOctave e' ->
                let tp = aux m_lst e' in
                TreePattern.beat_action (Shift.construct 0 (-1)) 0 tp
            |IncreaseTime e' ->
                let tp = aux m_lst e' in
                TreePattern.beat_action (Shift.construct 0 0) 1 tp
            |DecreaseTime e' ->
                let tp = aux m_lst e' in
                TreePattern.beat_action (Shift.construct 0 0) (-1) tp
            |Insertion (e1, i, e2) ->
                let tp1 = aux m_lst e1 and tp2 = aux m_lst e2 in
                TreePattern.extended_partial_composition tp1 i tp2
            |LabelInsertion (e1, lbl, e2) ->
                let tp1 = aux m_lst e1 and tp2 = aux m_lst e2 in
                TreePattern.label_composition tp1 lbl tp2
            |BinaryInsertion (e1, e2) ->
                let tp1 = aux m_lst e1 and tp2 = aux m_lst e2 in
                TreePattern.binary_composition tp1 tp2 
            |Repeat (k, e') ->
                let tp = aux m_lst e' in
                TreePattern.repeat k tp
            |Reverse e' ->
                let tp = aux m_lst e' in
                TreePattern.reverse tp
            |Complement e' ->
                let tp = aux m_lst e' in
                TreePattern.complement tp
            |Let (name, e1', e2') ->
                let e' = substitute_free_names e2' name e1' in
                aux m_lst e'
            |Put (m, e') ->
                let m_lst' = m :: m_lst in
                let tp = aux m_lst' e' in
                match m with
                    |Effect e -> TreePattern.Effect (e, tp)
                    |_ ->
                        let ct = modification_list_to_context m_lst' in
                        let p = Context.to_performance ct in
                        TreePattern.Performance (p, tp)
    in
    let tp = aux [] e in
    let p = Context.to_performance Context.default in
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
    let rec aux m_lst e =
        match e with
            |Name _ -> []
            |Atom _ ->
                let ct = modification_list_to_context m_lst in
                if Context.is_valid ct then [] else [ct]
            |Concatenation (e1, e2) |Composition (e1, e2) |Insertion (e1, _, e2)
                    |LabelInsertion (e1, _, e2) |BinaryInsertion (e1, e2) ->
                List.append (aux m_lst e1) (aux m_lst e2)
            |IncreaseOctave e' |DecreaseOctave e' |IncreaseTime e' |DecreaseTime e'
                    |Repeat (_, e') |Reverse e' |Complement e' ->
                aux m_lst e'
            |Let (name, e1', e2') ->
                let e' = substitute_free_names e2' name e1' in
                aux m_lst e'
            |Put (m, e') -> aux (m :: m_lst) e'
    in
    aux [] e

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

(* Tests if the expression e has no errors. When e has errors, error messages are printed
 * on the standard output. *)
let is_error_free e verbose =
    let errors = errors e in
    if errors = [] then
        true
    else begin
        if verbose then begin
            errors |> List.iter (fun r -> Printf.printf "Error: %s\n" (error_to_string r));
            flush stdout
        end;
        false
    end

let interpret e =
    Printf.printf "# Generating sound... ";
    let clock_start = Sys.time () in
    let sound = sound e in
    let clock_end = Sys.time () in
    let time_ms = int_of_float ((clock_end -. clock_start) *. 1000.0) in
    let tp = to_tree_pattern e in
    Printf.printf "done in %d ms.\n" time_ms;
    let dur_ms = Sound.duration sound in
    let dur_hour = (dur_ms / 1000) / 3600
    and dur_min = ((dur_ms / 1000) / 60) mod 60
    and dur_sec = (dur_ms / 1000) mod 60 in
    Printf.printf "## Duration: %d ms (%dh %dm %ds)\n" dur_ms dur_hour dur_min dur_sec;
    Printf.printf "## Arity: %d\n" (TreePattern.arity tp);
    Printf.printf "## Size: %d leaves\n" (TreePattern.nb_leaves tp);
    Printf.printf "## Height: %d\n" (TreePattern.height tp);
    print_newline ();
    sound

let interpret_and_play e =
    let s = interpret e in
    Printf.printf "# Playing sound... ";
    flush stdout;
    Sound.play s;
    Printf.printf "done.\n"

let interpret_and_write e path =
    assert (not (Sys.file_exists path));
    let s = interpret e in
    Printf.printf "# Writing sound... ";
    flush stdout;
    Sound.write_buffer s;
    ignore (Sys.command (Printf.sprintf "cp %s %s" Sound.buffer_path path));
    Printf.printf "done.\n"


(* The test function of the module. *)
let test () =
    print_string "Expression\n";
    true
