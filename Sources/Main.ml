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
    - Improve input / output.
*)

let name = "Calimba"
(*let version = "0.0001"*)
let version = "0.0010"
let version_date = "2012-12-12"
let author = "Samuele Giraudo"
let email = "samuele.giraudo@u-pem.fr"

let information =
    Printf.sprintf "%s\nCopyright (C) 2020--2020 %s\nWritten by %s [%s]\nVersion: %s (%s)"
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
        ^ "    -> Launches a live loop on the Calimba file PATH."

(* The extension of Calimba files. *)
let file_extension =
    ".cal"

(* Returns the extension of the file at path path. *)
let extension path =
    let i = String.rindex path '.' in
    String.sub path i ((String.length path) - i)

(* Tests if the file at path path has the good extension. *)
let has_good_extension path =
    if not (String.contains path '.') then
        false
    else
        extension path = file_extension

(* Returns the string obtained from the path path by removing its file extension, including
 * the point. *)
let remove_extension path =
    assert (String.contains path '.');
    let i = String.rindex path '.' in
    String.sub path 0 i

(* Returns an option on the expression specified by the .cal file at path path. None is
 * returned when there is an error in the program. *)
let path_to_expression path =
    assert (has_good_extension path);
    let t =
        try
             Some (Lexer.value_from_file_path path Parser.program Lexer.read)
        with
            |Lexer.Error msg -> begin
                let str = Printf.sprintf "There are errors in the program:\n    %s." msg in
                Tools.print_error str;
                None
            end
    in
    if Option.is_none t then
        None
    else
        let errors = Expression.errors (Option.get t) in
        if errors = [] then begin
            Tools.print_important "The program is correct.";
            t
        end
        else begin
            let error_str = errors |> List.map (fun r -> Expression.error_to_string r)
                |> String.concat "\n" in
            let str = Printf.sprintf
                "There are static errors in the program:\n    %s." error_str in
            Tools.print_error str;
            None
        end

(* Plays the .cal file at path path. *)
let play path =
    assert (has_good_extension path);
    let t = path_to_expression path in
    if Option.is_some t then
        Expression.interpret_and_play (Option.get t) true

(* Creates a PCM file from the .cal file at path path. Its name is obtained from the one of
 * the .cal file by replacing its extension by .pcm. *)
let write path =
    assert (has_good_extension path);
    let path' = (remove_extension path) ^ ".pcm" in
    if Sys.file_exists path' then
        Tools.print_error (Printf.sprintf "Error: a file %s exists already." path')
    else
        let t = path_to_expression path in
        if Option.is_some t then
            Expression.interpret_and_write (Option.get t) path' true

(* Creates a live loop reading and playing the .cal file at path path. This inspects if the
 * file is modified. If this is the case, the file is played (and the current play is
 * stopped. *)
let live_loop path =
    assert (has_good_extension path);
    let rec aux path last_modif num_iter =
        print_string "\r";
        if num_iter mod 2 = 0 then
            print_string (Tools.csprintf Tools.Cyan "-")
        else
            print_string (Tools.csprintf Tools.Magenta "|");
        flush stdout;
        Thread.delay 1.0;
        let last_modif' = (Unix.stat path).Unix.st_mtime in
        if Option.is_none last_modif || Option.get last_modif < last_modif' then begin
            Tools.print_important "Modification detected.";
            Sys.command "killall aplay" |> ignore;
            Thread.create (fun _ -> play path) () |> ignore
        end;
        aux path (Some (last_modif')) (num_iter + 1)
    in
    aux path None 1 |> ignore

(* Draws the signal of the sound specified by the .cal file at path path. The drawn portion
 * starts at start_ms ms and lasts len_ms ms. *)
let draw path start_ms len_ms =
    assert (has_good_extension path);
    let t = path_to_expression path in
    if Option.is_some t then
        Expression.interpret_and_draw (Option.get t) start_ms len_ms true

(* Print an analysis of each layout used in the expression specified by the .cal file at
 * path path. *)
let print_layout_analyses path =
    assert (has_good_extension path);
    let t = path_to_expression path in
    if Option.is_some t then
        Expression.interpret_and_analyse (Option.get t)

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
    Tools.print_important information;
    exit 0
end
else if Tools.has_argument "-h" then begin
    Tools.print_information help_string;
    exit 0
end
else if Tools.has_argument "-f" then begin
    let arg_lst = Tools.next_arguments "-f" 1 in
    if not (List.length arg_lst >= 1) then begin
        Tools.print_error "Error: a path must follow the -f argument.";
        exit 1
    end
    else begin
        let path = List.nth arg_lst 0 in
        if not (Sys.file_exists path) then begin
            Tools.print_error (Printf.sprintf "Error: there is no file %s." path);
            exit 1
        end
        else if not (has_good_extension path) then begin
            Tools.print_error
                (Printf.sprintf
                    "Error: the file %s has not %s as extension." path file_extension);
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
                    Tools.print_error
                        "Error: two positive integers must follow the -d argument.";
                    exit 1
                end
                else begin
                    try
                        let start_ms = int_of_string (List.nth arg_lst 0) in
                        let len_ms = int_of_string (List.nth arg_lst 1) in
                        draw path start_ms len_ms;
                        exit 0
                    with
                        |Failure _ -> begin
                            Tools.print_error
                                "Error: the two argument of -d must be integers.";
                            exit 1
                        end
                end
            end
            (* Analysis of the used layouts. *)
            else if Tools.has_argument "-a" then begin
                print_layout_analyses path
            end
            else begin
                Tools.print_error "Error: unknown argument configuration.";
                exit 1
            end
        end
    end
end
else
    print_string "Use option -h to print help.\n";

exit 0

