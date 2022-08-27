(* Author: Samuele Giraudo
 * Creation: aug. 2021
 * Modifications: aug. 2021, nov. 2021, dec. 2021, jan. 2022, feb. 2022, mar. 2022,
 * may 2022, aug. 2022
 *)

(* A type to specify a part (a bunch) of a sound. *)
type bunch = {
    (* The starting time of the bunch expressed in seconds. If it is None, then the
     * specified starting time is the origin. *)
    start: float option;

    (* The length of the bunch expressed in second. If it is None, then the specified length
     * is the  maximal possible one. *)
    length: float option
}

(* The delay between printing information. *)
let information_print_delay =
    0.5

(* Returns the bunch with the specified attributes. *)
let construct_bunch start length =
    let start = if Tools.option_value start 0.0 < 0.0 then None else start in
    let length = if Tools.option_value length 0.0 < 0.0 then None else length in
    {start = start; length = length}

(* Returns the factor of the sound s specified by the bunch b. *)
let sound_factor s b =
    let dur = Sound.duration s in
    let start = max 0.0 (min (Tools.option_value b.start 0.0) dur) in
    let len = max 0.0 (min (Tools.option_value b.length (dur -. start)) (dur -. start)) in
    Sound.factor s start len

(* Returns a thread generating the buffer from the sound s and printing information. *)
let generate_buffer s =
    let generation_complete = ref false in

    Thread.create
        (fun _ ->
            let total_duration = Sound.duration s in
            let start_generation = Unix.gettimeofday () in

            (* A thread to write the specified sound in the buffer. *)
            let thread_generation = Thread.create
                (fun _ ->
                    Buffer.delete ();
                    Tools.print_information_1 "Buffer generation...\n";
                    Buffer.write s;
                    generation_complete := true;
                    Tools.print_success "Complete generation.\n")
                ()
            in

            (* A thread to display generation information. *)
            Thread.create
                (fun _ ->
                    let rec loop () =
                        if not !generation_complete then begin
                            let time = Unix.gettimeofday () in
                            Printf.sprintf "Generation: %5.1f%% \
                                [Time: %.2f s / %.2f s] [Speed: %.2f s / s]\n"
                                (100.0 *. Buffer.duration () /. total_duration)
                                (Buffer.duration ())
                                total_duration
                                (Buffer.duration () /. (time -. start_generation))
                                |> Tools.print_information_2
                        end;
                        Thread.delay information_print_delay;
                        loop ()
                    in
                    loop ())
                ()
                |> ignore;

            Thread.join thread_generation)
        ()

(* Returns a thread playing the sound in the buffer and printing information. *)
let play_buffer () =
    Thread.create
        (fun _ ->
            let start_play_time = ref 0.0 in
            let playing = ref false in

            (* A thread to play the sound from the buffer. *)
            let thread_player = Thread.create
                (fun _ ->
                    Sys.command "killall aplay &> /dev/null" |> ignore;
                    Tools.print_information_1 "Playing sound...\n";
                    start_play_time := Unix.gettimeofday ();
                    playing := true;
                    Buffer.play ();
                    Tools.print_information_1 "Playing done.\n";
                    playing := false)
                ()
            in

            (* A thread to display playing information. *)
            Thread.create
                (fun _ ->
                    let rec loop () =
                        if !playing then begin
                            let time = Unix.gettimeofday () in
                            let play_duration = time -. !start_play_time in
                            Printf.sprintf "Playing: %5.1f%% [Time: %.2f s / %.2f s]\n"
                                (100.0 *. play_duration /. Buffer.duration ())
                                play_duration
                                (Buffer.duration ())
                                |> Tools.print_information_3
                        end;
                        Thread.delay information_print_delay;
                        loop ()
                    in
                    loop ())
                ()
                |> ignore;

            Thread.join thread_player)
        ()

(* Returns an option to the most simplified expression obtained by interpreting the
 * expression at path path. None is returned when there are errors in the starting
 * expression. *)
let interpret_path_to_simple_expression path =
    Tools.print_information_1 "Reading the program... ";
    let clock_start = Unix.gettimeofday () in
    let pp = Program.preprocess_path path in
    if Program.errors pp = [] then begin
        Tools.print_success "Done.\n";
        let e = Option.get (Program.expression pp) in
        let clock_end = Unix.gettimeofday () in
        let time = clock_end -. clock_start in
        Printf.sprintf "Final expression generated in %.2f s.\n" time
            |> Tools.print_information_1;
        Tools.print_information_2 "Expression characteristics:\n";
        let st = Statistics.compute e in
        Statistics.to_string st |> Tools.indent 4 |> Tools.print_information_2;
        Some e
    end
    else begin
        "\nThere are errors in the program:\n"
        ^ (Program.errors pp |> List.map Error.to_string |> String.concat "\n"
            |> Tools.indent 4)
        ^ "\n"
        |> Tools.print_error;
        None
    end

(* Returns an option on the portion of the sound of the buffer specified by the bunch b.
 * None is returned when there are errors in the starting expression. *)
let interpret_path_to_sound path b =
    let e = interpret_path_to_simple_expression path in
    if Option.is_none e then
        None
    else begin
        Tools.print_information_1 "Generating sound... ";
        let clock_start = Unix.gettimeofday () in
        let s = sound_factor (Program.sound (Option.get e)) b in
        let clock_end = Unix.gettimeofday () in
        Tools.print_success "Done.\n";
        let time = clock_end -. clock_start in
        Printf.sprintf "Sound generated in %.2f s.\n" time |> Tools.print_information_1;
        Tools.print_information_2 "Sound and buffer characteristics:\n";
        Buffer.to_information_string s |> Tools.indent 4 |> Tools.print_information_2;
        Some s
    end

(* Interprets the Calimba file at path path and, if it has no errors, plays the portion of
 * signal of the buffer specified by the bunch b each time ENTER is pressed. *)
let interpret_path_and_play path b =
    let s = interpret_path_to_sound path b in
    if Option.is_some s then begin
        Buffer.delete ();
        let s' = Option.get s in
        generate_buffer s' |> ignore;

        (* A thread to listen if the user press the Enter key in order to start playing. *)
        let thread_play_control = Thread.create
            (fun _ ->
                let rec loop () =
                    read_line () |> ignore;
                    play_buffer () |> ignore;
                    loop ()
                in
                Tools.print_information_1 "Press ENTER to play.\n";
                loop ())
            ()
        in

        Thread.join thread_play_control
    end

(* Interprets the Calimba file at path path and, if it has no errors, draws the portion of
 * signal of the buffer specified by the bunch b into a PCM file at path res_path. *)
let interpret_path_and_write_pcm path res_path b =
    assert (not (Sys.file_exists res_path));
    assert (Tools.extension res_path = ".pcm");
    let s = interpret_path_to_sound path b in
    if Option.is_some s then begin
        Printf.sprintf "Writing sound in file %s...\n" res_path
            |> Tools.print_information_1;
        let clock_start = Unix.gettimeofday () in
        let thread = generate_buffer (Option.get s) in
        Thread.join thread;
        Buffer.write_pcm_file res_path;
        let clock_end = Unix.gettimeofday () in
        let time = clock_end -. clock_start in
        Tools.print_success "Done.\n";
        Printf.sprintf "File generated in %.2f s.\n" time |> Tools.print_information_1
    end

(* Interprets the Calimba file at path path and, if it has no errors, draws the portion of
 * signal of the buffer specified by the bunch b into an SVG file at path res_path. *)
let interpret_path_and_write_svg path res_path b =
    assert (not (Sys.file_exists res_path));
    assert (Tools.extension res_path = ".svg");
    let s = interpret_path_to_sound path b in
    if Option.is_some s then begin
        Printf.sprintf "Drawing sound in file %s...\n" res_path
            |> Tools.print_information_1;
        let clock_start = Unix.gettimeofday () in
        let thread = generate_buffer (Option.get s) in
        Thread.join thread;
        Buffer.write_svg_file res_path;
        let clock_end = Unix.gettimeofday () in
        let time = clock_end -. clock_start in
        Tools.print_success "Done.\n";
        Printf.sprintf "File generated in %.2f s.\n" time |> Tools.print_information_1
    end

(* Interprets the Calimba file at path path and, if it has no errors, write its final
 * expression in the Calimba file at path res_path. *)
let interpret_path_and_write_cal path res_path =
    assert (not (Sys.file_exists res_path));
    assert (Tools.extension res_path = File.extension);
    let e = interpret_path_to_simple_expression path in
    if Option.is_some e then begin
        Printf.sprintf "Printing final expression in file %s...\n" res_path
            |> Tools.print_information_1;
        let f = open_out res_path in
        output_string f (Expression.to_string (Option.get e));
        close_out f;
        Tools.print_success "Done.\n"
    end

