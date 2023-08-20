(* Author: Samuele Giraudo
 * Creation: aug. 2021
 * Modifications: aug. 2021, nov. 2021, dec. 2021, jan. 2022, feb. 2022, mar. 2022,
 * may 2022, aug. 2022, jul. 2023
 *)

(* The delay between printing information. *)
let information_print_delay =
    0.25

(* A mutex to be sure that printings are not mixed by other threads. *)
let print_mutex = Mutex.create ()

(* Returns a thread generating the buffer from the sound s and printing information. If the
 * parameter verbose is true, some information is printed. *)
let generate_buffer verbose s =
    let generation_complete = ref false in

    Thread.create
        (fun _ ->
            let total_duration = Sounds.duration s in
            let start_generation = Unix.gettimeofday () in

            (* A thread to write the specified sound in the buffer. *)
            let thread_generation = Thread.create
                (fun _ ->
                    Buffers.delete ();
                    if verbose then begin
                        Mutex.lock print_mutex;
                        "# Buffer generation...\n" |> Outputs.print_information_1;
                        Mutex.unlock print_mutex
                    end;
                    let clock_start = Unix.gettimeofday () in
                    Buffers.write s;
                    let clock_end = Unix.gettimeofday () in
                    let time = clock_end -. clock_start in
                    generation_complete := true;
                    if verbose then begin
                        Mutex.lock print_mutex;
                        "End buffer generation "
                        |> Strings.indent 4
                        |> Outputs.print_success;
                        Printf.sprintf "[duration: %.2f s].\n" time
                        |> Outputs.print_information_3;
                        "## Buffer characteristics:\n"
                        |> Strings.indent 4
                        |> Outputs.print_information_2;
                        Buffers.to_information_string ()
                        |> Strings.indent 8
                        |> Outputs.print_information_3;
                        Mutex.unlock print_mutex;
                    end)
                ()
            in

            (* A thread to display generation information. *)
            Thread.create
                (fun _ ->
                    let rec loop () =
                        Thread.delay information_print_delay;
                        if not !generation_complete then begin
                            let time = Unix.gettimeofday () in
                            if verbose then begin
                                Mutex.lock print_mutex;
                                "Generating: "
                                |> Strings.indent 4 |> Outputs.print_information_2;
                                Printf.sprintf "%.1f%% \
                                    [Time: %.2f s / %.2f s] [Speed: %.2f s / s]\n"
                                    (100.0 *. Buffers.duration () /. total_duration)
                                    (Buffers.duration ())
                                    total_duration
                                    (Buffers.duration () /. (time -. start_generation))
                                |> Outputs.print_information_3;
                                Mutex.unlock print_mutex
                            end
                        end;
                        loop ()
                    in
                    loop ())
                ()
            |> ignore;

            Thread.join thread_generation)
        ()

(* Returns a thread playing the sound in the buffer and printing information. If the
 * parameter verbose is true, some information is printed.*)
let play_buffer verbose =
    Thread.create
        (fun _ ->
            let start_play_time = ref 0.0 in
            let playing = ref false in

            (* A thread to play the sound from the buffer. *)
            let thread_player = Thread.create
                (fun _ ->
                    Sys.command "killall aplay &> /dev/null" |> ignore;
                    if verbose then begin
                        Mutex.lock print_mutex;
                        "# Playing...\n" |> Outputs.print_information_1;
                        Mutex.unlock print_mutex
                    end;
                    start_play_time := Unix.gettimeofday ();
                    playing := true;
                    Buffers.play ();
                    if verbose then begin
                        Mutex.lock print_mutex;
                        "End buffer playing.\n"
                        |> Strings.indent 4
                        |> Outputs.print_success;
                        Mutex.unlock print_mutex
                    end;
                    playing := false)
                ()
            in

            (* A thread to display playing information. *)
            Thread.create
                (fun _ ->
                    let rec loop () =
                        Thread.delay information_print_delay;
                        if !playing then begin
                            let time = Unix.gettimeofday () in
                            let play_duration = time -. !start_play_time in
                            if verbose then begin
                                Mutex.lock print_mutex;
                                "Playing: "
                                |> Strings.indent 4
                                |> Outputs.print_information_2;
                                Printf.sprintf "%.1f%% [Time: %.2f s / %.2f s]\n"
                                    (100.0 *. play_duration /. Buffers.duration ())
                                    play_duration
                                    (Buffers.duration ())
                                |> Outputs.print_information_3;
                                Mutex.unlock print_mutex
                            end
                        end;
                        loop ()
                    in
                    loop ())
                ()
            |> ignore;

            Thread.join thread_player)
        ()

(* Returns an option on a pair consisting in the processed expression of the expression
 * contained in the file at path path and in its sound, cut following the bunch b. If the
 * input expression contains errors, None is returned. If the parameter verbose is true,
 * some information is printed. *)
let interpret_path verbose path b =
    if verbose then begin
        Mutex.lock print_mutex;
        "# Processing the program...\n" |> Outputs.print_information_1;
        Mutex.unlock print_mutex
    end;
    let clock_start = Unix.gettimeofday () in
    let pr = Processings.process_path path in
    let clock_end = Unix.gettimeofday () in
    let time = clock_end -. clock_start in
    if not (Processings.has_errors pr) then begin
        if verbose then begin
            Mutex.lock print_mutex;
            "End program processing " |> Strings.indent 4 |> Outputs.print_success;
            Mutex.unlock print_mutex
        end;
        let e = Processings.expression pr in
        let s = Bunches.cut_sound (Processings.sound pr) b in
        if verbose then begin
            Mutex.lock print_mutex;
            Printf.sprintf "[duration: %.2f s].\n" time |> Outputs.print_information_3;
            "## Expression characteristics:\n"
            |> Strings.indent 4
            |> Outputs.print_information_2;
            let st = Statistics.compute e in
            Statistics.to_string st |> Strings.indent 8 |> print_string;
            Mutex.unlock print_mutex
        end;
        Some (e, s)
    end
    else begin
        Printf.sprintf "\nThere are errors in the program:\n%s"
            (Processings.errors pr
            |> List.map Errors.to_string
            |> String.concat "\n"
            |> Strings.indent 4)
        |> Strings.indent 4
        |> Outputs.print_error;
        print_newline ();
        None
    end

(* Interprets the file at path path and, if it has no errors, plays the portion of signal of
 * the buffer specified by the bunch b each time ENTER is pressed. If the parameter verbose
 * is true, some information is printed. *)
let interpret_path_and_play verbose path b =
    let es = interpret_path verbose path b in
    if Option.is_some es then begin
        let (_, s) = Option.get es in
        Buffers.delete ();
        generate_buffer verbose s |> ignore;

        (* A thread to listen if the user press the Enter key in order to start playing. *)
        let thread_play_control = Thread.create
            (fun _ ->
                let rec loop () =
                    read_line () |> ignore;
                    play_buffer verbose |> ignore;
                    loop ()
                in
                if verbose then begin
                    Mutex.lock print_mutex;
                    "Press ENTER to play.\n"
                    |> Strings.indent 4
                    |> Outputs.print_information_2;
                    Mutex.unlock print_mutex
                end;
                loop ())
            ()
        in

        Thread.join thread_play_control
    end

(* Interprets the file at path path and, if it has no errors, draws the portion of signal of
 * the buffer specified by the bunch b into a PCM file having as path a new one. If the
 * parameter verbose is true, some information is printed. *)
let interpret_path_and_write_sound verbose path b =
    let es = interpret_path verbose path b in
    if Option.is_some es then begin
        let (_, s) = Option.get es in
        let path' = (Paths.remove_extension path) ^ ".pcm" |> Paths.new_distinct in
        if verbose then begin
            Mutex.lock print_mutex;
            Printf.sprintf "# Writing sound in file %s...\n" path'
            |> Outputs.print_information_1;
            Mutex.unlock print_mutex
        end;
        let clock_start = Unix.gettimeofday () in
        let thread = generate_buffer verbose s in
        Thread.join thread;
        Buffers.write_pcm_file path';
        let clock_end = Unix.gettimeofday () in
        let time = clock_end -. clock_start in
        if verbose then begin
            Mutex.lock print_mutex;
            "End writing sound in file " |> Strings.indent 4 |> Outputs.print_success;
            Printf.sprintf "[duration: %.2f s].\n" time |> Outputs.print_information_3;
            Mutex.unlock print_mutex
        end
    end

(* Interprets the file at path path and, if it has no errors, draws the portion of signal of
 * the buffer specified by the bunch b into an SVG file and a PNG file having as paths new
 * ones. If the parameter verbose is true, some information is printed. *)
let interpret_path_and_draw_sound verbose path b =
    let es = interpret_path verbose path b in
    if Option.is_some es then begin
        let (_, s) = Option.get es in
        let path' = (Paths.remove_extension path) ^ ".svg" |> Paths.new_distinct in
        if verbose then begin
            Mutex.lock print_mutex;
            Printf.sprintf "# Drawing sound in file %s...\n" path'
            |> Outputs.print_information_1;
            Mutex.unlock print_mutex
        end;
        let clock_start = Unix.gettimeofday () in
        let thread = generate_buffer verbose s in
        Thread.join thread;
        Buffers.write_svg_file path';
        let path'' = (Paths.remove_extension path) ^ ".png" |> Paths.new_distinct in
        if verbose then begin
            Mutex.lock print_mutex;
            Printf.sprintf "Drawing sound in file %s...\n" path''
                |> Strings.indent 4 |> Outputs.print_information_2;
            Mutex.unlock print_mutex
        end;
        let cmd = Printf.sprintf "convert -density 144 %s %s" path' path'' in
        Sys.command cmd |> ignore;
        let clock_end = Unix.gettimeofday () in
        let time = clock_end -. clock_start in
        if verbose then begin
            Mutex.lock print_mutex;
            "End drawing sound in files " |> Strings.indent 4 |> Outputs.print_success;
            Printf.sprintf "[duration: %.2f s].\n" time |> Outputs.print_information_3;
            Mutex.unlock print_mutex
        end
    end

(* Interprets the Qlusster file at path path and, if it has no errors, write its final
 * expression into a Qlusster file having as path a new one. If the parameter verbose is
 * true, some information is printed. *)
let interpret_path_and_write_expression verbose path b =
    let es = interpret_path verbose path b in
    if Option.is_some es then begin
        let (e, _) = Option.get es in
        let path' = (Paths.remove_extension path) ^ Files.extension |> Paths.new_distinct in
        if verbose then begin
            Mutex.lock print_mutex;
            Printf.sprintf "# Writing final expression in file %s...\n" path'
            |> Outputs.print_information_1;
            Mutex.unlock print_mutex
        end;
        let clock_start = Unix.gettimeofday () in
        let f = open_out path' in
        Buffer.output_buffer f (Outputs.to_buffered_string e);
        close_out f;
        let clock_end = Unix.gettimeofday () in
        let time = clock_end -. clock_start in
        if verbose then begin
            Mutex.lock print_mutex;
            "End writing final expression in file " |> Outputs.print_success;
            Printf.sprintf "[duration: %.2f s].\n" time |> Outputs.print_information_3;
            Mutex.unlock print_mutex
        end
    end

