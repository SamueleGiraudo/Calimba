(* Author: Samuele Giraudo
 * Creation: jul. 2023
 * Modifications: jul. 2023
 *)

(* The type of flags. *)
type flags = Flag of string

(* The three possible statuses for a flag. *)
type statuses =
    |On
    |Off
    |Random

(* Returns the name of the flag fl. *)
let name fl =
    let Flag name = fl in
    name

(* Returns a string representation of the flag fl. *)
let to_string fl =
    Printf.sprintf "$%s" (name fl)

(* Returns a string representation of the flag status st. *)
let status_to_string st =
    match st with
        |On -> "on"
        |Off -> "off"
        |Random -> "random"

(* Tests if the list of flags flags contains the flag fl when st is On, does not contain fl
 * when st is Off, or returns a coin flip if fl is Random. *)
let test flags st fl =
    match st with
        |On -> List.mem fl flags
        |Off -> not (List.mem fl flags)
        |Random -> Random.int 2 = 1

(* Returns the list of flags obtained from the list of flags flags by adding the flag fl
 * when st is On, by suppressing fl when st is Off, or by adding or suppressing fl decided
 * by a coin flip. *)
let rec modify flags st fl =
    match st with
        |On -> fl :: flags
        |Off -> flags |> List.filter (fun fl' -> fl' <> fl)
        |Random ->
            if Random.int 2 = 1 then modify flags On fl else modify flags Off fl

