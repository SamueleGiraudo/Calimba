(* Author: Samuele Giraudo
 * Creation: (mau 2021), may 2022
 * Modifications: may 2022, aug. 2022
 *)

(* The extension of Calimba files. *)
let extension = ".cal"

(* The maximal beat (useful to avoid too big integers for beats). *)
let max_beat = 1024

(* The maximal length a flag. *)
let max_flag_length = 255

(* The maximal length for an alias (in definitions or in usage). *)
let max_alias_length = 255

(* The maximal length for a path. *)
let max_path_length = 255

(* Tests if the integer i can be an beat. *)
let is_beat i =
    1 <= i && i <= max_beat

(* Returns the path obtained from the path path by adding the Calimba file extension. *)
let add_file_extension path =
    path ^ extension

(* Tests if the string str can be a flag. *)
let is_flag str =
    let len = String.length str in
    1 <= len && len <= max_flag_length && Tools.is_alpha_character (String.get str 0)
        && String.for_all Tools.is_plain_character str

(* Tests if the string str can be an alias. *)
let is_alias str =
    let len = String.length str in
    1 <= len && len <= max_alias_length && Tools.is_alpha_character (String.get str 0)
        && String.for_all Tools.is_plain_character str

(* Tests if the string str can be a path of an included file. *)
let is_inclusion_path str =
    let len = String.length str in
    if len > max_path_length then
        false
    else
        let levels = String.split_on_char '/' str |> List.fold_left
            (fun res u ->
                let v = if u = ".." then (List.hd res) - 1 else (List.hd res) + 1 in
                v :: res)
            [0]
        in
        if levels |> List.exists (fun v -> v < 0) then
            false
        else
            len >= (1 + String.length extension) && Tools.has_extension extension str
                && String.for_all
                    (fun c -> Tools.is_plain_character c || c = '.' || c = '/')
                    str

(* Returns the expression e obtained by adding to all its inclusion paths the prefix
 * pref. *)
let complete_inclusion_paths pref e =
    let rec aux e =
        match e with
            |Expression.Beat _ |Expression.Alias _  -> e
            |Expression.CycleOperation (info, op, e1') ->
                Expression.CycleOperation (info, op, aux e1')
            |Expression.UnaryOperation (info, op, e1) ->
                Expression.UnaryOperation (info, op, aux e1)
            |Expression.BinaryOperation (info, op, e1, e2) ->
                Expression.BinaryOperation (info, op, aux e1, aux e2)
            |Expression.FlagTest (info, st, fl, e1, e2) ->
                Expression.FlagTest (info, st, fl, aux e1, aux e2)
            |Expression.FlagModification (info, st, fl, e1) ->
                Expression.FlagModification (info, st, fl, aux e1)
            |Expression.AliasDefinition (info, alias, e1, e2) ->
                Expression.AliasDefinition (info, alias, aux e1, aux e2)
            |Expression.Composition (info, e1, e_lst) ->
                Expression.Composition (info, aux e1, e_lst |> List.map aux)
            |Expression.Put (info, path) -> Expression.Put (info, pref ^ path)
    in
    aux e

(* Returns the expression specified by the Calimba file at path path. The exception
 * Lexer.Error is raised when there are syntax errors in the program. *)
let path_to_expression path =
    let e = Lexer.value_from_file_path path Parser.program Lexer.read in
    complete_inclusion_paths (Tools.trim_path path) e

(* Returns the list of the included paths in the expression e and recursively included by
 * the expressions of the included Calimba files. *)
let included_paths e =
    let rec aux paths e =
        match e with
            |Expression.Beat _ |Expression.Alias _ -> []
            |Expression.CycleOperation (_, _, e1) |Expression.UnaryOperation (_, _, e1)
            |Expression.FlagModification (_, _, _, e1) ->
                aux paths e1
            |Expression.BinaryOperation (_, _, e1, e2)
            |Expression.AliasDefinition (_, _, e1, e2)
            |Expression.FlagTest (_, _, _, e1, e2) ->
                List.append (aux paths e1) (aux paths e2)
            |Expression.Composition (_, e1, e_lst) ->
                List.append (aux paths e1) (e_lst |> List.map (aux paths) |> List.flatten)
            |Expression.Put (_, path) ->
                let path = add_file_extension path in
                if not (Sys.file_exists path) || not (is_inclusion_path path) then
                    []
                else
                    let path' = Tools.simplify_path path in
                    if List.mem path' paths then
                        [path']
                    else
                        try
                            let e0 = path_to_expression path' in
                            let paths' = path' :: paths in
                            path' :: aux paths' e0
                        with
                            |Lexer.Error _ -> []
    in
    aux [] e

