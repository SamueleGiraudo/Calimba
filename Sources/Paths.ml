(* Author: Samuele Giraudo
 * Creation: (jul. 2020), jul. 2023
 * Modifications: jul. 2023
 *)

(* Returns the extension of the file at path path. *)
let extension path =
    let i = String.rindex path '.' in
    String.sub path i ((String.length path) - i)

(* Tests if the file at path path has the extension ext (with the point). *)
let has_extension ext path =
    if not (String.contains path '.') then
        false
    else
        extension path = ext

(* Returns the string obtained from the path path by removing its file extension, including
 * the '.'. *)
let remove_extension path =
    assert (String.contains path '.');
    let i = String.rindex path '.' in
    String.sub path 0 i

(* Returns the path obtained by suppressing the last part of the path path, by keeping the
 * `/`. For instance, if path is "aa/ab/abc", then "aa/ab/" is returned. If path has no
 * occurrence of '/', the empty path is returned. *)
let trim path =
    try
        let i = String.rindex path '/' in
        String.sub path 0 (i + 1)
    with
        |Not_found -> ""

(* Returns the path obtained from the path path by simplifying the "..". For instance, if
 * path is "a/b/c/../../d/e/..", then "a/d" is returned. *)
let simplify path =
    let tmp = String.split_on_char '/' path in
    tmp |> List.fold_left
        (fun res u -> if u = ".." then List.tl res else u :: res)
        []
     |> List.rev |> String.concat "/"

(* Returns a path that does not correspond to any existing file by adding a string "_N"
 * just before the extension of the path path, where N is an adequate number. *)
let new_distinct path =
    let path' = remove_extension path and ext' = extension path in
    let rec aux i =
        let res_path = Printf.sprintf "%s_%d%s" path' i ext' in
        if Sys.file_exists res_path then
            aux (i + 1)
        else
            res_path
    in
    aux 0

