(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, oct. 2020, dec. 2020, jan. 2021
 *)

%{

(* Raises an exception Tools.ArgumentError with, as message string, the data provided by the
 * construction name name, the index index_arg of the argument, and the message msg. *)
let argument_error name index_arg msg =
    let str = Printf.sprintf "the arg. %d of [%s] %s" index_arg name msg in
    raise (Tools.ValueError str)

%}

%token PAR_L PAR_R
%token BEGIN END

%token POINT
%token COLON
%token PLUS
%token MINUS
%token LT
%token GT
%token STAR
%token SHARP
%token <string> AT_LABEL
%token AT_AT
%token EQUALS
%token REPEAT
%token REVERSE
%token COMPLEMENT
%token PRIME
%token COMMA
%token LET
%token PUT
%token IN

%token LAYOUT
%token ROOT
%token TIME
%token DURATION
%token SYNTHESIZER

%token SCALE
%token DELAY
%token CLIP
%token TREMOLO

%token <int> INTEGER
%token <float> POS_FLOAT
%token <string> NAME

%token EOF

%nonassoc PREC_LET
%nonassoc PREC_PUT
%nonassoc PREC_COMPLEMENT
%nonassoc PREC_REVERSE
%nonassoc PREC_REPEAT

%left AT_AT
%left AT_LABEL
%left SHARP
%left STAR

%nonassoc PRIME
%nonassoc COMMA
%nonassoc PLUS
%nonassoc MINUS
%nonassoc LT
%nonassoc GT

%start <Expression.expression> program

%%

program:
    |exp=expression EOF
        {exp}

expression:
    |name=NAME
        {Expression.Name name}
    |POINT
        {Expression.Atom (Atom.construct_silence (TimeDegree.construct 0))}
    |d=INTEGER
        {Expression.Atom (Atom.construct_beat (Degree.construct d) TimeDegree.zero)}
    |d=INTEGER COLON lbl=NAME
        {Expression.Atom
            (Atom.construct_labeled_beat (Degree.construct d) (TimeDegree.zero) lbl)}
    |exp1=expression STAR exp2=expression
        {Expression.Concatenation (exp1, exp2)}
    |exp1=expression SHARP exp2=expression
        {Expression.Addition (exp1, exp2)}
    |exp= expression PLUS
        {Expression.IncreaseDegrees exp}
    |exp= expression MINUS
        {Expression.DecreaseDegrees exp}
    |exp=expression LT
        {Expression.IncreaseTime exp}
    |exp=expression GT
        {Expression.DecreaseTime exp}
    |exp1=expression lbl=AT_LABEL exp2=expression
        {Expression.LabeledInsertion (exp1, lbl, exp2)}
    |exp1=expression AT_AT exp2=expression
        {Expression.SaturatedInsertion (exp1, exp2)}
    |REPEAT k=INTEGER exp=expression
        %prec PREC_REPEAT
        {if k <= 0 then
            argument_error "repeat" 1 "must be positive"
        else
            Expression.Repeat (k, exp)}
    |REVERSE exp=expression
        %prec PREC_REVERSE
        {Expression.Reverse exp}
    |COMPLEMENT exp=expression
        %prec PREC_COMPLEMENT
        {Expression.Complement exp}
    |exp=expression PRIME
        {Expression.IncreaseOctave exp}
    |exp=expression COMMA
        {Expression.DecreaseOctave exp}
    |LET name=NAME EQUALS exp1=expression IN exp2=expression
        %prec PREC_LET
        {Expression.Let (name, exp1, exp2)}
    |PUT cm=context_mutation IN exp=expression
        %prec PREC_PUT
        {Expression.ContextMutation (cm, exp)}
    |PUT em=effect_mutation IN exp=expression
        %prec PREC_PUT
        {Expression.EffectMutation (em, exp)}
    |PAR_L exp=expression PAR_R
        {exp}
    |BEGIN exp=expression END
        {exp}

context_mutation:
    |LAYOUT EQUALS lay=layout
        {Expression.Layout lay}
    |ROOT EQUALS root=note
        {Expression.Root root}
    |TIME EQUALS m=INTEGER d=INTEGER
        {if m <= 0 then
            argument_error "time" 1 "must be positive"
        else if d <= 0 then
            argument_error "time" 2 "must be positive"
        else if m <= d then
            argument_error "time" 1 "must be greater than the second"
        else
            Expression.TimeShape (TimeShape.construct m d)}
    |DURATION EQUALS dur=INTEGER
        {if dur <= 0 then
            argument_error "duration" 1 "must be positive"
        else
            Expression.UnitDuration dur}
    |SYNTHESIZER EQUALS s=synthesizer
        {Expression.Synthesizer s}

layout:
    |lst=nonempty_list(INTEGER)
        {if not (Layout.is_valid_list lst) then
            argument_error "layout" 1 "is not a valid layout"
        else
            Layout.construct lst}

note:
    |step=INTEGER nb=INTEGER oct=INTEGER
        {if step < 0 then
            argument_error "root" 1 "must be nonnegative"
        else if nb < 1 then
            argument_error "root" 2 "must be positive"
        else if step >= nb then
            argument_error "root" 1 "must be smaller than the nb. of steps by octave"
        else
            Note.construct step nb oct}

synthesizer:
    |t=timbre sh=synthesizer_shape
        {let (max_dur, o_dur, c_dur) = sh in Synthesizer.construct t max_dur o_dur c_dur}

timbre:
    |scale=POS_FLOAT coeff=POS_FLOAT
        {if scale > 1.0 then
            argument_error "synthesizer" 1 "must be not greater than 1.0"
        else if coeff >= 1.0 then
            argument_error "synthesizer" 2 "must be smaller than 1.0"
        else
            Timbre.scale scale (Timbre.geometric coeff)}

synthesizer_shape:
    |max_dur=INTEGER o_dur=INTEGER c_dur=INTEGER
        {(max_dur, o_dur, c_dur)}

effect_mutation:
    |SCALE EQUALS c=POS_FLOAT
        {Expression.Scale c}
    |CLIP EQUALS c=POS_FLOAT
        {if c < 0.0 || c > 1.0 then
            argument_error "clip" 1 "must be between 0.0 and 1.0"
        else
            Expression.Clip c}
    |DELAY EQUALS t=INTEGER c=POS_FLOAT
        {if t < 0 then
            argument_error "delay" 1 "must be nonnegative"
        else
            Expression.Delay (t, c)}
    |TREMOLO EQUALS t=INTEGER c=POS_FLOAT
        {if t < 0 then
            argument_error "tremolo" 1 "must be nonnegative"
        else if c < 0.0 || c > 1.0 then
            argument_error "tremolo" 2 "must be between 0.0 and 1.0"
        else
            Expression.Tremolo (t, c)}

