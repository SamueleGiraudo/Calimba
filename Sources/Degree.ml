(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

(* A degree is an integer i specifying the i-th element of a layout, possibly on different
 * octaves. *)
type degree = Degree of int

(* Returns the degree having the specified attribute. *)
let construct i =
    Degree i

(* Returns the degree zero. *)
let zero =
    Degree 0

(* Returns the integer associated with the degree d *)
let to_int d =
    let Degree i = d in
    i

(* Returns a string representation of the degree d. *)
let to_string d =
    Tools.csprintf Tools.Magenta (string_of_int (to_int d))

(* Returns the next degree of the degree d. *)
let next d =
    Degree (to_int d + 1)

(* Returns the previous degree of the degree d. *)
let previous d =
    Degree (to_int d - 1)

(* Tests is the degree d is the degree zero. *)
let is_zero d =
    d = zero

(* Tests if the degree d is nonnegative. *)
let is_nonnegative d =
    (to_int d) >= 0

(* Tests if the degree d1 is smaller than or equal as d2. *)
let is_leq d1 d2 =
    to_int d1 <= to_int d2

(* Returns the degree obtained by shifting the degree d for delta positions. *)
let shift d delta =
    Degree (delta + to_int d)

(* Returns the degree obtained by adding the extended degrees ed1 and ed2. *)
let add d1 d2 =
    Degree (to_int d1 + to_int d2)

(* Returns the complement degree of the extended degree ed. This is the inverse of
 * ls w.r.t. degree addition. *)
let complement d =
    Degree (-(to_int d))

