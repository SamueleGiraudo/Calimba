(* Author: Samuele Giraudo
 * Creation: may. 2022
 * Modifications: may. 2022, aug. 2022, jul. 2023
 *)

(* The type to add information for each expression (and its subexpressions). *)
type information = {

    (* The position with respect to the file where the subexpression appears. *)
    file_position: FilePositions.file_positions
}

(* Returns the information specified by the file position file_position. *)
let construct file_position =
    {file_position = file_position}

(* Returns a string representation of the information info. *)
let to_string info =
    FilePositions.to_string info.file_position

