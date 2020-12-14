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
    ""

(* Plays the .cal file at path path. *)
let play path =
    Lexer.interpret_file_path
        path
        Parser.program
        Lexer.read
        Expression.interpret_and_play
        (fun t -> Expression.is_error_free t true)

(* Creates a PCM file from the .cal file at path path. Its name is obtained from the one of
 * the .cal file by replacing its extension by .pcm. *)
let write path =
    let path' = (String.sub path 0 ((String.length path) - 3)) ^ "pcm" in
    if Sys.file_exists path' then
        Printf.printf "Error: a file %s exists already.\n" path'
    else
        Lexer.interpret_file_path
            path
            Parser.program
            Lexer.read
            (fun t -> Expression.interpret_and_write t path')
            (fun t -> Expression.is_error_free t true)

(* Creates a live loop reading and playing the .cal file at path path. This inspects if the
 * file is modified. If this is the case, the file is played (and the current play is
 * stopped. *)
let live_loop path =
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
    print_string information
end
else if Tools.has_argument "-f" then begin
    let path = Tools.next_argument "-f" in
    if Option.is_none path then begin
        print_string "Error: a path must follow the -f argument.\n";
        exit 1
    end
    else begin
        let path = Option.get path in
        if not (Sys.file_exists path) then begin
            Printf.printf "Error: there is no file %s.\n" path;
            exit 1
        end
        else begin
            if Tools.has_argument "-w" then begin
                write path;
                exit 0
            end
            else if Tools.has_argument "-l" then begin
                live_loop path;
                exit 0
            end
            else if Tools.has_argument "-a" then begin
                (* TODO *)
            end
            else begin
                play path;
                exit 0
            end
        end
    end
end
else
    print_string "Use option -h to print help.\n";

exit 0

