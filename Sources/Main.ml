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
*)

let name = "Calimba"
(*let version = "0.0001"*)
let version = "0.0010"
let author = "Samuele Giraudo"
let email = "samuele.giraudo@u-pem.fr"

let information =
    Printf.sprintf "%s\nCopyright (C) 2020--2020 %s\nWritten by %s [%s]\nVersion: %s\n"
        name author author email version

let help_string =
    ""

;;

(* Main expression. *)

(* Creation of the buffer directory if it does not exist. *)
ignore (Sys.command("mkdir -p /dev/shm/Synth/"));

if Tools.has_argument "-r" then
    Random.init 0
else
    Random.self_init ();

if Tools.has_argument "-v" then begin
    print_string information
end
else if Tools.has_argument "-t" then begin
    if Note.test () then Printf.printf "-> OK\n" else Printf.printf "->ERROR\n";
    if Layout.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if RootedLayout.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if Sound.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if Synthesizer.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if Shift.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if TimeLayout.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if Context.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if TreePattern.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    if Expression.test () then Printf.printf "-> OK\n" else Printf.printf "-> ERROR\n";
    print_newline ();
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
                let path' = (String.sub path 0 ((String.length path) - 3)) ^ "pcm" in
                if Sys.file_exists path' then begin
                    Printf.printf "Error: a file %s exists already.\n" path';
                     exit 1
                end
                else begin
                    Lexer.interpret_file_path
                        path
                        Parser.program
                        Lexer.read
                        (fun t -> Expression.interpret_and_write t path')
                        (fun t -> Expression.is_error_free t true);
                    exit 0
                end
            end
            else begin
                Lexer.interpret_file_path
                    path
                    Parser.program
                    Lexer.read
                    Expression.interpret_and_play
                    (fun t -> Expression.is_error_free t true);
                exit 0
            end
        end
    end
end
else
    print_string "Use option -h to print help.\n";

exit 0

