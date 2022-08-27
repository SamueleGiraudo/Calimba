(* Author: Samuele Giraudo
 * Creation: may 2021
 * Modifications: may 2021, jun. 2021, aug. 2021, nov. 2021, dec. 2021, jan. 2022,
 * mar. 2022, may 2022, aug. 2022
 *)

%token L_PAR R_PAR
%token BEGIN END
%token PERCENT
%token PLUS STAR CIRCUMFLEX
%token RESET
%token SCALE
%token CYCLES
%token VERTICAL HORIZONTAL
%token TIME
%token PRIME COMMA
%token LT GT
%token DOLLAR
%token IF
%token THEN ELSE
%token SET
%token ON OFF RANDOM
%token SEMICOLON
%token L_BRACKET R_BRACKET
%token LET
%token EQUAL
%token IN
%token PUT
%token <string> STRING
%token <float> NUMBER
%token EOF

%left IN
%left ELSE
%left PLUS
%left STAR
%left CIRCUMFLEX
%left L_BRACKET

%nonassoc PRIME
%nonassoc COMMA
%nonassoc LT
%nonassoc GT

%start <Expression.expression> program

%%

program:
    |e=expression EOF {e}

expression:
    |L_PAR e=expression R_PAR {e}
    |PERCENT i=NUMBER {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.Beat (info, Tools.bounded_int_of_float i)
    }
    |e=scale {e}
    |e=reset {e}
    |e=binary_operation {e}
    |IF st=flag_status fl=flag THEN e1=expression ELSE e2=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.FlagTest (info, st, fl, e1, e2)
    }
    |SET st=flag_status fl=flag IN e=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.FlagModification (info, st, fl, e)
    }
    |e=expression L_BRACKET e_lst=separated_list(SEMICOLON, expression) R_BRACKET {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.Composition (info, e, e_lst)
    }
    |alias=STRING {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.Alias (info, alias)
    }
    |LET alias=STRING EQUAL e1=expression IN e2=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.AliasDefinition (info, alias, e1, e2)
    }
    |PUT path=STRING {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.Put (info, path)
    }
    |e=sugar {e}

scale:
    |SCALE CYCLES x=NUMBER IN e=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info, Expression.UpdateCycleNumber x, e)
    }
    |SCALE VERTICAL x=NUMBER IN e=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.UnaryOperation (info, Expression.VerticalScaling x, e)
    }
    |SCALE HORIZONTAL x=NUMBER IN e=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.UnaryOperation (info, Expression.HorizontalScaling x, e)
    }

reset:
    |RESET CYCLES IN e=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info, Expression.ResetCycleNumber, e)
    }

binary_operation:
    |e1=expression PLUS e2=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.BinaryOperation (info, Expression.Addition, e1, e2)
    }
    |e1=expression STAR e2=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.BinaryOperation (info, Expression.Concatenation, e1, e2)
    }
    |e1=expression CIRCUMFLEX e2=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.BinaryOperation (info, Expression.Multiplication, e1, e2)
    }

flag:
    |DOLLAR fl=STRING {fl}

flag_status:
    |ON {Expression.On}
    |OFF {Expression.Off}
    |RANDOM {Expression.Random}

sugar:
    |BEGIN e=expression END {e}
    |e=expression PRIME {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info, Expression.UpdateCycleNumber 2.0, e)
    }
    |e=expression COMMA {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info, Expression.UpdateCycleNumber 0.5, e)
    }
    |e=expression LT {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info,
            Expression.UpdateCycleNumber 2.0,
            Expression.UnaryOperation (info, Expression.HorizontalScaling 2.0, e))
    }
    |e=expression GT {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info,
            Expression.UpdateCycleNumber 0.5,
            Expression.UnaryOperation (info, Expression.HorizontalScaling 0.5, e))
    }
    |SCALE TIME x=NUMBER IN e=expression {
        let info = Information.construct (Tools.position_to_file_position $startpos) in
        Expression.CycleOperation (info,
            Expression.UpdateCycleNumber x,
            Expression.UnaryOperation (info, Expression.HorizontalScaling x, e))
    }

