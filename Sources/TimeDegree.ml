(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A time degree is an integer value encoding a number increments (resp. decrements) of
 * times when it is positive (resp. negative). For instance, for a time shape with a
 * multiplier equal to 3 and a divider equal to 2, a time shape shift of 5 specifies
 * (3 / 2) ** 5 units of time, and a time shape shift of -3 specifies (2 / 3) ** 3 units of
 * time. *)
type time_degree = TimeDegree of int

(* Returns the time degree having the specified attribute. *)
let construct i =
    TimeDegree i

(* Returns the time degree zero. *)
let zero =
    TimeDegree 0

(* Returns the integer associated with the time degree td *)
let to_int td =
    let TimeDegree i = td in
    i

(* Returns a string representation of the time degree td. *)
let to_string td =
    let i = to_int td in
    let str =
        if i <= 0 then
            String.make (-i) '<'
        else
            String.make i '>' in
    Tools.csprintf Tools.Magenta str

(* Returns the time degree obtained by adding the time degrees td1 and td2. *)
let add td1 td2 =
    TimeDegree (to_int td1 + to_int td2)
