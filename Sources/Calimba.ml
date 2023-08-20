(* Author: Samuele Giraudo
 * Creation: (aug. 2016), apr. 2020
 * Modifications: apr. 2020, may 2020, jul. 2020, aug. 2020, dec. 2020, jan. 2021, may 2021,
 * aug. 2021, nov. 2021, dec. 2021, jan. 2022, may 2022, aug. 2022, nov. 2022, jul. 2023
 *)

(* Calimba - A program to program music. *)

(* TODO
 *
 * - Improve flags by adding to them the prefix of their file of appearance.
 *
 * - Rewrite the parser by introducing expression_1, expression_2, etc. to manage
 *   priorities.
 *
 * - Improve the syntax and the abstract syntax tree of expressions.
 *
 * - Add a loop operation.
 *
 * - Implement environment model.
 *
 * - Replace List.append by @.
 *
 * - Add prefixes to the messages of the raised exceptions by the name of their modules.
 *
 *)

let name = "Calimba"

let logo = "<</\\|_"

let description = "A musical programming language based on clone theory."

(*let version = "0.0001" and version_date = "2020-08-27" *)
(*let version = "0.0010" and version_date = "2020-12-12" *)
(*let version = "0.0011" and version_date = "2021-01-01" *)
(*let version = "0.0100" and version_date = "2021-05-30" *)
(*let version = "0.0101" and version_date = "2021-08-20" *)
(*let version = "0.0110" and version_date = "2021-12-29"*)
(*let version = "0.0111" and version_date = "2022-01-01"*)
(*let version = "0.1000" and version_date = "2022-05-10"*)
(*let version = "0.1001" and version_date = "2022-05-30"*)
(*let version = "0.1010" and version_date = "2022-08-27"*)
let version = "0.1011" and version_date = "2023-07-20"

let author = "Samuele Giraudo"

(*let email = "samuele.giraudo@univ-eiffel.fr"*)
let email = "giraudo.samuele@uqam.fr"

(* Returns a string of information about the Aclove program. *)
let information =
    Printf.sprintf "%s\n%s\n%s\nCopyright (C) 2020--2023 %s\nWritten by %s [%s]\n\
        Version: %s (%s)\n"
        logo name description author author email version version_date

(* Returns the help string about the arguments of the program. *)
let help_string =
      "Usage:\n    ./calimba [--help] [--version] --file PATH [--verbose] \
      [--bunch START LEN] [--text] [--write] [--draw] [--play] \nwhere:\n"
    ^ "    + `--help` prints the short help (the present text).\n"
    ^ "    + `--version` prints the version and other information.\n"
    ^ "    + `--file PATH` sets PATH as the path to the Calimba program to consider, \
             contained in a " ^ Files.extension ^ " file.\n"
    ^ "    + `--verbose` enables the verbose mode.\n"
    ^ "    + `--bunch START LEN` specifies the part of the generated signal to consider, \
             with its starting time START and length LEN in seconds.\n"
    ^ "    + `--text` creates the CAL file containing the processed expression specified \
             the program.\n"
    ^ "    + `--write` creates the PCM file specified by the program.\n"
    ^ "    + `--draw` creates the SVG and PNG files specified by the program.\n"
    ^ "    + `--play` plays the signal specified by the program.\n"

(* Returns the bunch specified by the standard input. *)
let read_bunch () =
    try
        match Arguments.option_values "--bunch" with
            |[] -> Bunches.construct None None
            |[x1] -> Bunches.construct (Some (float_of_string x1)) None
            |x1 :: x2 :: _ ->
                Bunches.construct (Some (float_of_string x1)) (Some (float_of_string x2))
    with
        |Failure _ -> begin
            "Error: after -b, there must be 0, 1, or 2 float arguments.\n"
            |> Outputs.print_error;
            "Default bunch has be assigned.\n" |> Outputs.print_information_1;
            exit 0
        end

;;

(* Main expression. *)

Random.self_init ();

(* Creation of the buffer directory if it does not exist. *)
let cmd = Printf.sprintf "mkdir -p %s" Buffers.path_directory in
Sys.command cmd |> ignore;

(* Version. *)
if Arguments.exists "--version" then begin
    Outputs.print_success information;
    exit 0
end;

(* Help. *)
if Arguments.exists "--help" then begin
    Outputs.print_information_1 help_string;
    exit 0
end;

(* Test if there is a single file path. *)
let arg_lst = Arguments.option_values "--file" in
if List.length arg_lst <> 1 then begin
    "Error: one path must follow the --file argument.\n" |> Outputs.print_error;
    exit 1
end;

(* The path of the file containing the program. *)
let path = List.hd arg_lst in

(* Checks the existence of the file at path path. *)
if Sys.file_exists path |> not then begin
    Printf.sprintf "Error: there is no file %s.\n" path |> Outputs.print_error;
    exit 1
end;

(* Checks if the file has the right extension. *)
if not (Paths.has_extension Files.extension path) then begin
    Printf.sprintf "Error: the file %s has not %s as extension.\n" path Files.extension
    |> Outputs.print_error;
    exit 1
end;

(* Detection of the verbose mode. *)
let verbose = Arguments.exists "--verbose" in

(* Detecting a bunch specification. *)
let bunch = read_bunch () in

(* Writing a CAL file. *)
if Arguments.exists "--text" then
    Executions.interpret_path_and_write_expression verbose path bunch;

(* Writing a PCM file. *)
if Arguments.exists "--write" then
    Executions.interpret_path_and_write_sound verbose path bunch;

(* Writing an SVG and PNG file. *)
if Arguments.exists "--draw" then
    Executions.interpret_path_and_draw_sound verbose path bunch;

(* Playing. *)
if Arguments.exists "--play" then
    Executions.interpret_path_and_play verbose path bunch;

exit 0

