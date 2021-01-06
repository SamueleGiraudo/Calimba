(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, dec. 2020, jan. 2021
 *)

{

(* An exception raised when an error is encountered. *)
exception Error of string

(* Raise Tools.SyntaxError with information about the unexpected character c. *)
let unexpected_character_error c =
    raise (Tools.SyntaxError (Printf.sprintf "unexpected character %c" c))

(* Raise Tools.SyntaxError with information about an unclosed comment. *)
let unclosed_comment_error () =
    raise (Tools.SyntaxError "unclosed comment")

(* Modifies the buffer lexbuf so that it contains the next line. *)
let next_line lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    lexbuf.Lexing.lex_curr_p <-
        {pos with
            Lexing.pos_bol = lexbuf.Lexing.lex_curr_pos;
            Lexing.pos_lnum = pos.Lexing.pos_lnum + 1}

(* Returns a string giving information about the position contained in the buffer lexbuf. *)
let position lexbuf =
    let pos = lexbuf.Lexing.lex_curr_p in
    Printf.sprintf "file %s, line %d, column %d"
        pos.Lexing.pos_fname
        pos.Lexing.pos_lnum
        (pos.Lexing.pos_cnum - pos.Lexing.pos_bol + 1)

(* Returns the value computed by the parser parser_axiom, with the lexer lexer_axiom, and
 * with the buffer lexbuf. If there is an error, the exception Error is raised. *)
let parse_lexer_buffer parser_axiom lexer_axiom lexbuf =
    try
        parser_axiom lexer_axiom lexbuf
    with
        |Parser.Error ->
            let str = Printf.sprintf "syntax error in %s" (position lexbuf) in
            raise (Error str)
        |Tools.SyntaxError msg ->
            let str = Printf.sprintf "syntax error in %s: %s" (position lexbuf) msg in
            raise (Error str)
        |Tools.ValueError msg ->
            let str = Printf.sprintf "value error in %s: %s" (position lexbuf) msg in
            raise (Error str)

(* Returns the value contained in the file at path path, interpreted with the parser
 * parser_axiom, with the lexer lexer_axiom. If an error is found, the exception Error is
 * raised. *)
let value_from_file_path path parser_axiom lexer_axiom =
    assert (Sys.file_exists path);
    let lexbuf = Lexing.from_channel (open_in path) in
    lexbuf.Lexing.lex_curr_p <- {lexbuf.Lexing.lex_curr_p with Lexing.pos_fname = path};
    parse_lexer_buffer parser_axiom lexer_axiom lexbuf

}

let letter = ['a'-'z' 'A'-'Z' '_']
let digits = ['0'-'9']
let plain_character = letter | digits

let name = letter plain_character*
let integer = '-'? digits+
let pos_float = integer '.' digits+

rule read = parse
    |' ' |'\t'
        {read lexbuf}
    |'\n'
        {next_line lexbuf; read lexbuf}
    |'('
        {Parser.PAR_L}
    |')'
        {Parser.PAR_R}
    |'.'
        {Parser.POINT}
    |':'
        {Parser.COLON}
    |'+'
        {Parser.PLUS}
    |'-'
        {Parser.MINUS}
    |'<'
        {Parser.LT}
    |'>'
        {Parser.GT}
    |'*'
        {Parser.STAR}
    |'#'
        {Parser.SHARP}
    |'@' name
        {Parser.AT_LABEL (ExtLib.String.lchop (Lexing.lexeme lexbuf))}
    |"@@"
        {Parser.AT_AT}
    |'='
        {Parser.EQUALS}
    |'\''
        {Parser.PRIME}
    |','
        {Parser.COMMA}
    |"begin"
        {Parser.BEGIN}
    |"end"
        {Parser.END}
    |"repeat"
        {Parser.REPEAT}
    |"reverse"
        {Parser.REVERSE}
    |"complement"
        {Parser.COMPLEMENT}
    |"let"
        {Parser.LET}
    |"put"
        {Parser.PUT}
    |"in"
        {Parser.IN}
    |"layout"
        {Parser.LAYOUT}
    |"root"
        {Parser.ROOT}
    |"time"
        {Parser.TIME}
    |"duration"
        {Parser.DURATION}
    |"synthesizer"
        {Parser.SYNTHESIZER}
    |"scale"
        {Parser.SCALE}
    |"delay"
        {Parser.DELAY}
    |"clip"
        {Parser.CLIP}
    |"tremolo"
        {Parser.TREMOLO}
    |integer
        {Parser.INTEGER (int_of_string (Lexing.lexeme lexbuf))}
    |pos_float
        {Parser.POS_FLOAT (float_of_string (Lexing.lexeme lexbuf))}
    |name
        {Parser.NAME (Lexing.lexeme lexbuf)}
    |'{'
        {comment 0 lexbuf}
    |eof
        {Parser.EOF}
    |_ as c
        {unexpected_character_error c}

and comment level = parse
    |'\n'
        {next_line lexbuf; comment level lexbuf}
    |'}'
        {if level = 0 then read lexbuf else comment (level - 1) lexbuf}
    |'{'
        {comment (level + 1) lexbuf}
    |eof
        {unclosed_comment_error ()}
    |_
        {comment level lexbuf}

