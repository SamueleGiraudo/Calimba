(* Author: Samuele Giraudo
 * Creation: may 2021
 * Modifications: may 2021, jun. 2021, aug. 2021, nov. 2021, dec. 2021, jan. 2022,
 * mar. 2022, may 2022, aug. 2022, jul. 2023
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

%start <Expressions.expressions> program

%%

program:
    |e=expression EOF {e}

expression:
    |L_PAR e=expression R_PAR {e}
    |PERCENT i=NUMBER {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.Beat (info, Beats.Beat (Scalars.bounded_int_of_float i))
    }
    |e=scale {e}
    |e=reset {e}
    |e=binary_operation {e}
    |IF st=flag_status fl=flag THEN e1=expression ELSE e2=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.FlagTest (info, st, Flags.Flag fl, e1, e2)
    }
    |SET st=flag_status fl=flag IN e=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.FlagModification (info, st, Flags.Flag fl, e)
    }
    |e=expression L_BRACKET e_lst=separated_list(SEMICOLON, expression) R_BRACKET {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.Composition (info, e, e_lst)
    }
    |alias=STRING {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.Alias (info, alias)
    }
    |LET alias=STRING EQUAL e1=expression IN e2=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.AliasDefinition (info, alias, e1, e2)
    }
    |PUT path=STRING {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.Put (info, path)
    }
    |e=sugar {e}

scale:
    |SCALE CYCLES x=NUMBER IN e=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar x in
        Expressions.CycleOperation (info, Expressions.UpdateCycleNumber sc, e)
    }
    |SCALE VERTICAL x=NUMBER IN e=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar x in
        Expressions.UnaryOperation (info, Expressions.VerticalScaling sc, e)
    }
    |SCALE HORIZONTAL x=NUMBER IN e=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar x in
        Expressions.UnaryOperation (info, Expressions.HorizontalScaling sc, e)
    }

reset:
    |RESET CYCLES IN e=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.CycleOperation (info, Expressions.ResetCycleNumber, e)
    }

binary_operation:
    |e1=expression PLUS e2=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.BinaryOperation (info, Expressions.Addition, e1, e2)
    }
    |e1=expression STAR e2=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.BinaryOperation (info, Expressions.Concatenation, e1, e2)
    }
    |e1=expression CIRCUMFLEX e2=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        Expressions.BinaryOperation (info, Expressions.Multiplication, e1, e2)
    }

flag:
    |DOLLAR fl=STRING {fl}

flag_status:
    |ON {Flags.On}
    |OFF {Flags.Off}
    |RANDOM {Flags.Random}

sugar:
    |BEGIN e=expression END {e}
    |e=expression PRIME {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar 2.0 in
        Expressions.CycleOperation (info, Expressions.UpdateCycleNumber sc, e)
    }
    |e=expression COMMA {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar 0.5 in
        Expressions.CycleOperation (info, Expressions.UpdateCycleNumber sc, e)
    }
    |e=expression LT {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar 2.0 in
        Expressions.CycleOperation (info,
            Expressions.UpdateCycleNumber sc,
            Expressions.UnaryOperation (info, Expressions.HorizontalScaling sc, e))
    }
    |e=expression GT {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar 0.5 in
        Expressions.CycleOperation (info,
            Expressions.UpdateCycleNumber sc,
            Expressions.UnaryOperation (info, Expressions.HorizontalScaling sc, e))
    }
    |SCALE TIME x=NUMBER IN e=expression {
        let info = Information.construct (FilePositions.from_position $startpos) in
        let sc = Scalars.Scalar x in
        Expressions.CycleOperation (info,
            Expressions.UpdateCycleNumber sc,
            Expressions.UnaryOperation (info, Expressions.HorizontalScaling sc, e))
    }

