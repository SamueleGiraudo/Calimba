(* Author: Samuele Giraudo
 * Creation: (mau 2021), may 2022
 * Modifications: may 2022, aug. 2022, jul. 2023
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

(* Tests if the integer i can be a beat index. *)
let is_beat_index i =
    1 <= i && i <= max_beat

(* Returns the path obtained from the path path by adding the Calimba file extension. *)
let add_file_extension path =
    path ^ extension

(* Tests if the character c is an alphabetic character. *)
let is_alpha_character c =
    ('a' <= c && c <= 'z') || ('A' <= c && c <= 'Z')

(* Tests if the character c is a numerical character. *)
let is_numerical_character c =
    ('0' <= c && c <= '9')

(* Tests if the character c is a special character. *)
let is_special_character c =
     c = '_' || c = '.' || c = '/'

(* Tests if the character c is a character allowed in identifiers. *)
let is_plain_character c =
     is_alpha_character c || is_numerical_character c || is_special_character c

(* Tests if the string str can be a flag. *)
let is_flag_name str =
    let len = String.length str in
    1 <= len && len <= max_flag_length && is_alpha_character (String.get str 0)
        && String.for_all is_plain_character str

(* Tests if the string str can be an alias. *)
let is_alias str =
    let len = String.length str in
    1 <= len && len <= max_alias_length && is_alpha_character (String.get str 0)
        && String.for_all is_plain_character str

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
            len >= (1 + String.length extension) && Paths.has_extension extension str
                && str |> String.for_all is_plain_character

(* Returns the expression e obtained by adding to all its inclusion paths the prefix
 * pref. *)
let complete_inclusion_paths pref e =
    let rec aux e =
        match e with
            |Expressions.Beat _ |Expressions.Alias _  -> e
            |Expressions.CycleOperation (info, op, e1') ->
                Expressions.CycleOperation (info, op, aux e1')
            |Expressions.UnaryOperation (info, op, e1) ->
                Expressions.UnaryOperation (info, op, aux e1)
            |Expressions.BinaryOperation (info, op, e1, e2) ->
                Expressions.BinaryOperation (info, op, aux e1, aux e2)
            |Expressions.FlagTest (info, st, fl, e1, e2) ->
                Expressions.FlagTest (info, st, fl, aux e1, aux e2)
            |Expressions.FlagModification (info, st, fl, e1) ->
                Expressions.FlagModification (info, st, fl, aux e1)
            |Expressions.AliasDefinition (info, alias, e1, e2) ->
                Expressions.AliasDefinition (info, alias, aux e1, aux e2)
            |Expressions.Composition (info, e1, e_lst) ->
                Expressions.Composition (info, aux e1, e_lst |> List.map aux)
            |Expressions.Put (info, path) -> Expressions.Put (info, pref ^ path)
    in
    aux e

(* Returns the expression specified by the Calimba file at path path. The exception
 * Lexer.Error is raised when there are syntax errors in the program. *)
let path_to_expression path =
    let e = Lexer.value_from_file_path path Parser.program Lexer.read in
    let path' = Paths.simplify path in
    e |> complete_inclusion_paths (Paths.trim path')
    (* TODO completion of identifiers *)

(* Returns the list of the included paths in the expression e and recursively included by
 * the expressions of the included Calimba files. *)
let included_paths e =
    let rec aux paths e =
        match e with
            |Expressions.Beat _ |Expressions.Alias _ -> []
            |Expressions.CycleOperation (_, _, e1) |Expressions.UnaryOperation (_, _, e1)
            |Expressions.FlagModification (_, _, _, e1) ->
                aux paths e1
            |Expressions.BinaryOperation (_, _, e1, e2)
            |Expressions.AliasDefinition (_, _, e1, e2)
            |Expressions.FlagTest (_, _, _, e1, e2) ->
                List.append (aux paths e1) (aux paths e2)
            |Expressions.Composition (_, e1, e_lst) ->
                List.append (aux paths e1) (e_lst |> List.map (aux paths) |> List.flatten)
            |Expressions.Put (_, path) ->
                let path = add_file_extension path in
                if not (Sys.file_exists path) || not (is_inclusion_path path) then
                    []
                else
                    let path' = Paths.simplify path in
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

