(* Author: Samuele Giraudo
 * Creation: (aug. 2016), apr. 2020
 * Modifications: apr. 2020, may 2020, jul. 2020, aug. 2020, dec. 2020, jan. 2021, may 2021,
 * aug. 2021, nov. 2021, dec. 2021, jan. 2022, may 2022, aug. 2022
 *)

(* Calimba - A program to program music. *)

let name = "Calimba"
let logo = "<</^\\|_"
(*let version = "0.0001" and version_date = "2020-08-27" *)
(*let version = "0.0010" and version_date = "2020-12-12" *)
(*let version = "0.0011" and version_date = "2021-01-01" *)
(*let version = "0.0100" and version_date = "2021-05-30" *)
(*let version = "0.0101" and version_date = "2021-08-20" *)
(*let version = "0.0110" and version_date = "2021-12-29"*)
(*let version = "0.0111" and version_date = "2022-01-01"*)
(*let version = "0.1000" and version_date = "2022-05-10"*)
(*let version = "0.1001" and version_date = "2022-05-30"*)
let version = "0.1010" and version_date = "2022-08-27"
let author = "Samuele Giraudo"
let email = "samuele.giraudo@univ-eiffel.fr"

let information =
    Printf.sprintf "%s\n%s\nCopyright (C) 2020--2022 %s\nWritten by %s [%s]\n\
        Version: %s (%s)\n"
        logo name author author email version version_date

let help_string =
    "Here, PATH is the path to a Calimba file.\n"
    ^ "Available arguments:\n"
        ^ "-v\n"
        ^ "    -> Print the version of the application.\n"
        ^ "-h\n"
        ^ "    -> Print the help.\n"
        ^ "-f PATH -p\n"
        ^ "    -> Plays the program PATH.\n"
        ^ "-f PATH -w\n"
        ^ "    -> Generates the associated PCM file of the program PATH.\n"
        ^ "-f PATH -d\n"
        ^ "    -> Generates the associated PNG file of the program PATH.\n"
        ^ "-f PATH -e\n"
        ^ "    -> Prints the final expression of the program PATH.\n"
        ^ "The last four commands can be followed by\n"
        ^ "    -b START LENGTH\n"
        ^ "where START is the starting time and LENGTH is the length of the desired bunch "
        ^ "of the sound. These values are in seconds and are optional.\n"

;;

(* Main expression. *)

Random.self_init ();

(* Creation of the buffer directory if it does not exist. *)
let cmd = Printf.sprintf "mkdir -p %s" Buffer.path_directory in
Sys.command cmd |> ignore;

(* Version. *)
if Tools.has_argument "-v" then
    Tools.print_success information

(* Help. *)
else if Tools.has_argument "-h" then
    Tools.print_information_1 help_string

(* Reading file from path. *)
else if Tools.has_argument "-f" then begin
    let arg_lst = Tools.next_arguments "-f" 1 in
    if arg_lst = [] then
        Tools.print_error "Error: a path must follow the -f argument.\n"
    else begin
        let path = List.hd arg_lst in
        if not (Sys.file_exists path) then
            Printf.sprintf "Error: there is no file %s.\n" path |> Tools.print_error
        else if not (Tools.has_extension File.extension path) then
            Printf.sprintf "Error: the file %s has not %s as extension.\n"
                path File.extension
                |> Tools.print_error
        else begin
            (* Detecting a bunch specification. *)
            let bunch =
                try
                    match Tools.next_arguments "-b" 2 with
                        |[] -> Execution.construct_bunch None None
                        |[x1] -> Execution.construct_bunch (Some (float_of_string x1)) None
                        |x1 :: x2 :: _ ->
                            Execution.construct_bunch
                                (Some (float_of_string x1)) (Some (float_of_string x2))
                with
                    |Failure _ -> begin
                        Tools.print_error "Error: after -b, there must be 0, 1, or 2 float \
                            arguments.\n";
                        Tools.print_information_1 "Default bunch has be assigned.\n";
                        Execution.construct_bunch None None
                    end
            in

            (* Writing a PCM file. *)
            if Tools.has_argument "-w" then begin
                let path' = (Tools.remove_extension path) ^ ".pcm" |> Tools.new_file_name in
                Execution.interpret_path_and_write_pcm path path' bunch
            end;

            (* Writing an SVG file. *)
            if Tools.has_argument "-d" then begin
                let path' = (Tools.remove_extension path) ^ ".svg" |> Tools.new_file_name in
                Execution.interpret_path_and_write_svg path path' bunch
            end;

            (* Writing a CAL file containing the final expression. *)
            if Tools.has_argument "-e" then begin
                let path' = (Tools.remove_extension path) ^ File.extension
                    |> Tools.new_file_name in
                Execution.interpret_path_and_write_cal path path'
            end;

            (* Playing. *)
            if Tools.has_argument "-p" then begin
                Execution.interpret_path_and_play path bunch
            end
        end
    end
end

(* Unknown arguments. *)
else
    Tools.print_error "Error: a path to a .cal file must be specified.\n"

