(* Author: Samuele Giraudo
 * Creation: (jul. 2020), jul. 2023
 * Modifications: jul. 2023
 *)

(* The type of the scalars. *)
type scalars = Scalar of float

(* Returns the value of the scalar s. *)
let value s =
    let Scalar value = s in
    value

(* Returns the addition of the scalars s and s'. *)
let addition s s' =
    Scalar (value s +. value s')

(* Returns the multiplication of the scalars s and s'. *)
let multiplication s s' =
    Scalar (value s *. value s')

(* Returns the exponentiation of the scalars s and s'. *)
let exponentiation s s' =
    Scalar (value s ** value s')

(* Returns a string representation of the scalar s. *)
let to_string s =
    Printf.sprintf "%.8g" (value s)

(* Returns the scalar specified by the string str. This string starts with ' and by dropping
 * this first character, it specifies a signed floating number in decimal. *)
let from_string str =
    let v = String.sub str 1 ((String.length str) - 1) |> float_of_string in
    Scalar v

(* Returns the rounded integer version of the float x. *)
let float_to_rounded_int x =
   int_of_float (Float.round x)

(* Returns the integer being the truncation of the float x. If x is too big or to small to
 * be converted into an integer, then max_int or min_int is returned. *)
let bounded_int_of_float x =
    if x >= float_of_int max_int then
        max_int
    else if x <= float_of_int min_int then
        min_int
    else
        Float.to_int x

