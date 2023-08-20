(* Author: Samuele Giraudo
 * Creation: (jul 2020), jul. 2023
 * Modifications: jul. 2023
 *)

(* A type to represent positions in a file. *)
type file_positions = {
    path: string;
    line: int;
    column: int
}

(* Returns the file position having path as path, line a line number and column as column
 * number. *)
let construct path line column =
    assert (path <> "");
    assert (0 <= line);
    assert (0 <= column);
    {path = path; line = line; column = column}

(* Returns the file position specified by the lexing position pos. *)
let from_position pos =
    {path = pos.Lexing.pos_fname;
    line = pos.Lexing.pos_lnum;
    column = pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1}

(* Returns a string representation of the file position fp. *)
let to_string fp =
    Printf.sprintf "@%s L%d C%d" fp.path fp.line fp.column

