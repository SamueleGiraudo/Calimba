(* Author: Samuele Giraudo
 * Creation: (aug. 2016), apr. 2020
 * Modifications: apr. 2020, may 2020, jul. 2020, aug. 2020, dec. 2020
 *)

(* Calimba: a program to explore music theory, explore combinatorial representation of
 * music, and synthesize sounds.
 *)

(* TODO
    - Improve comments.
    - Robustness.
    - External documentation.
    - Information about layouts.
    - Error gestion for program is broken.
*)

let name = "Calimba"
(*let version = "0.0001"*)
let version = "0.0010"
let version_date = "2012-12-12"
let author = "Samuele Giraudo"
let email = "samuele.giraudo@u-pem.fr"

let information =
    Printf.sprintf "%s\nCopyright (C) 2020--2020 %s\nWritten by %s [%s]\nVersion: %s (%s)\n"
        name author author email version version_date

let help_string =
    "Available arguments:\n"
        ^ "-v\n"
        ^ "    -> Print the version of the application.\n"
        ^ "-h\n"
        ^ "    -> Print the help.\n"
        ^ "-f PATH -p\n"
        ^ "    -> Plays the Calimba file PATH.\n"
        ^ "-f PATH -w\n"
        ^ "    -> Writes the associated PCM file from the Calimba file PATH.\n"
        ^ "-f PATH -l\n"
        ^ "    -> Launches a live loop on the Calimba file PATH.\n"

(* Returns the extension of the file at path path. *)
let extension path =
    let i = String.rindex path '.' in
    String.sub path i ((String.length path) - i)

(* Tests if the file at path path has the good extension. *)
let has_good_extension path =
    if not (String.contains path '.') then
        false
    else
        extension path = Lexer.file_extension

(* Returns the string obtained from the path path by removing its file extension, including
 * the point. *)
let remove_extension path =
    assert (String.contains path '.');
    let i = String.rindex path '.' in
    String.sub path 0 i

(* Returns the expression specified by the .cal file at path path. *)
let path_to_expression path =
    assert (has_good_extension path);
    try
        let t = Lexer.value_from_file_path
            path
            Parser.program
            Lexer.read
            (fun t -> Expression.is_error_free t true) in
        print_string "There are errors in the program.";
        print_newline ();
        t
    with
        |Lexer.Error msg ->
            print_string "There are errors in the program.";
            print_newline ();
            print_string msg;
            print_newline ();
            Expression.Atom (TreePattern.Silence 0)

(* Plays the .cal file at path path. *)
let play path =
    assert (has_good_extension path);
    let t = path_to_expression path in
    Expression.interpret_and_play t

(* Creates a PCM file from the .cal file at path path. Its name is obtained from the one of
 * the .cal file by replacing its extension by .pcm. *)
let write path =
    assert (has_good_extension path);
    let path' = (remove_extension path) ^ ".pcm" in
    if Sys.file_exists path' then
        Printf.printf "Error: a file %s exists already.\n" path'
    else
        let t = path_to_expression path in
        Expression.interpret_and_write t path'

(* Creates a live loop reading and playing the .cal file at path path. This inspects if the
 * file is modified. If this is the case, the file is played (and the current play is
 * stopped. *)
let live_loop path =
    assert (has_good_extension path);
    let rec aux path last_modif num_iter =
        print_string "\r";
        if num_iter mod 2 = 0 then
            Printf.printf "-"
        else
            Printf.printf "|";
        flush stdout;
        Thread.delay 1.0;
        let last_modif' = (Unix.stat path).Unix.st_mtime in
        if Option.is_none last_modif
                || Option.get last_modif < last_modif' then begin
            Printf.printf "Modification detected: interpreting and playing...";
            print_newline ();
            Sys.command "killall aplay" |> ignore;
            Thread.create (fun _ -> play path) () |> ignore;
            Printf.printf " done.";
            print_newline ()
        end;
        aux path (Some (last_modif')) (num_iter + 1)
    in
    aux path None 1 |> ignore;

;;

(* Main expression. *)

(* Creation of the buffer directory if it does not exist. *)
let cmd = Printf.sprintf "mkdir -p %s" Sound.buffer_path_directory in
Sys.command cmd |> ignore;

if Tools.has_argument "-r" then
    Random.init 0
else
    Random.self_init ();

if Tools.has_argument "-v" then begin
    print_string information;
    exit 0
end
else if Tools.has_argument "-h" then begin
    print_string help_string;
    exit 0
end
else if Tools.has_argument "-f" then begin
    let arg_lst = Tools.next_arguments "-f" 1 in
    if not (List.length arg_lst >= 1) then begin
        print_string "Error: a path must follow the -f argument.\n";
        exit 1
    end
    else begin
        let path = List.nth arg_lst 0 in
        if not (Sys.file_exists path) then begin
            Printf.printf "Error: there is no file %s.\n" path;
            exit 1
        end
        else if not (has_good_extension path) then begin
            Printf.printf "Error: the file %s has not .cal as extension.\n" path;
            exit 1
        end
        else begin
            (* Playing. *)
            if Tools.has_argument "-p" then begin
                play path;
                exit 0
            end
            (* Writing a PCM file. *)
            else if Tools.has_argument "-w" then begin
                write path;
                exit 0
            end
            (* Launching a live loop. *)
            else if Tools.has_argument "-l" then begin
                live_loop path;
                exit 0
            end
            (* Drawing a fragment of the sound. *)
            else if Tools.has_argument "-d" then begin
                let arg_lst = Tools.next_arguments "-d" 2 in
                if not (List.length arg_lst >= 2) then begin
                    print_string
                        "Error: two positive integers must follow the -d argument.\n";
                    exit 1
                end
                else begin
                    try
                        let t = path_to_expression path in
                        let s = Expression.interpret t in
                        let start_ms = int_of_string (List.nth arg_lst 0) in
                        if not (0 <= start_ms && start_ms < (Sound.duration s)) then begin
                            print_string "Error: incorrect start time.\n";
                            exit 1
                        end;
                        let len_ms = int_of_string (List.nth arg_lst 1) in
                        if not (1 <= len_ms && start_ms + len_ms - 1 < (Sound.duration s))
                                then begin
                            print_string "Error: incorrect duration.\n";
                            exit 1
                        end;
                        let start_x = Sound.duration_to_size start_ms in
                        let len_x = Sound.duration_to_size len_ms in
                        let s' = Sound.factor s start_x len_x in
                        Sound.draw s';
                        exit 0
                    with
                        |Failure _ -> begin
                            print_string
                                "Error: the two argument of -d must be integers.\n";
                            exit 1
                        end
                end
            end
            (* Analysis of the used layouts. *)
            else if Tools.has_argument "-a" then begin
                (* TODO *)
            end
            else begin
                Printf.printf "Error: unknown argument configuration.\n";
                exit 1
            end
        end
    end
end
else
    print_string "Use option -h to print help.\n";

exit 0

