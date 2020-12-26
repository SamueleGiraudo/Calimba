(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020, aug. 2020, oct. 2020, dec. 2020
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
%token LT
%token GT
%token STAR
%token SHARP
%token <int> AT_INTEGER
%token <string> AT_LABEL
%token AT_AT
%token EQUALS
%token PRIME
%token COMMA
%token REPEAT
%token REVERSE
%token COMPLEMENT
%token LET
%token PUT
%token IN

%token LAYOUT
%token ROOT
%token TIME
%token DURATION
%token SYNTHESIZER
%token EFFECT

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
%left AT_INTEGER
%left AT_LABEL
%left SHARP
%left STAR

%nonassoc PRIME
%nonassoc COMMA
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
        {Expression.Atom (TreePattern.silence)}
    |d=INTEGER
        {Expression.Atom (TreePattern.beat d)}
    |d=INTEGER COLON lbl=NAME
        {Expression.Atom (TreePattern.labeled_beat d lbl)}
    |exp1=expression STAR exp2=expression
        {Expression.Concatenation (exp1, exp2)}
    |exp1=expression SHARP exp2=expression
        {Expression.Composition (exp1, exp2)}
    |exp=expression PRIME
        {Expression.IncreaseOctave exp}
    |exp=expression COMMA
        {Expression.DecreaseOctave exp}
    |exp=expression LT
        {Expression.IncreaseTime exp}
    |exp=expression GT
        {Expression.DecreaseTime exp}
    |exp1=expression i=AT_INTEGER exp2=expression
        {Expression.Insertion (exp1, i, exp2)}
    |exp1=expression lbl=AT_LABEL exp2=expression
        {Expression.LabelInsertion (exp1, lbl, exp2)}
    |exp1=expression AT_AT exp2=expression
        {Expression.BinaryInsertion (exp1, exp2)}
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
    |LET name=NAME EQUALS exp1=expression IN exp2=expression
        %prec PREC_LET
        {Expression.Let (name, exp1, exp2)}
    |PUT ct=put IN exp=expression
        %prec PREC_PUT
        {Expression.Put (ct, exp)}
    |PAR_L exp=expression PAR_R
        {exp}
    |BEGIN exp=expression END
        {exp}

put:
    |LAYOUT EQUALS lay=layout
        {Expression.Layout (Layout.construct lay)}
    |ROOT EQUALS root=note
        {Expression.Root root}
    |TIME EQUALS m=INTEGER d=INTEGER
        {if m <= 0 then
            argument_error "time" 1 "must be positive"
        else if d <= 0 then
            argument_error "time" 2 "must be positive"
        else
            Expression.TimeShape (TimeShape.construct m d)}
    |DURATION EQUALS dur=INTEGER
        {if dur <= 0 then
            argument_error "duration" 1 "must be positive"
        else
            Expression.UnitDuration dur}
    |SYNTHESIZER EQUALS s=synthesizer
        {Expression.Synthesizer s}
    |EFFECT EQUALS e=effect
        {Expression.Effect e}

layout:
    |lst=nonempty_list(INTEGER)
        {if not (Layout.is_valid lst) then
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
    |t=synthesizer_timbre sh=synthesizer_shape
        {let (max_dur, o_dur, c_dur) = sh in Synthesizer.construct t max_dur o_dur c_dur}

synthesizer_timbre:
    |scale=POS_FLOAT coeff=POS_FLOAT
        {if scale > 1.0 then
            argument_error "synthesizer" 1 "must be not greater than 1.0"
        else if coeff >= 1.0 then
            argument_error "synthesizer" 2 "must be smaller than 1.0"
        else
            Synthesizer.scale_timbre scale (Synthesizer.geometric_timbre coeff)}

synthesizer_shape:
    |max_dur=INTEGER o_dur=INTEGER c_dur=INTEGER
        {(max_dur, o_dur, c_dur)}

effect:
    |SCALE c=POS_FLOAT
        {Sound.scale c}
    |DELAY t=INTEGER c=POS_FLOAT
        {if t < 0 then
            argument_error "delay" 1 "must be nonnegative"
        else
            Sound.delay t c}
    |CLIP c=POS_FLOAT
        {if c < 0.0 || c > 1.0 then
            argument_error "clip" 1 "must be between 0.0 and 1.0"
        else
            fun s -> Sound.clip s c}
    |TREMOLO t=INTEGER c=POS_FLOAT
        {if t < 0 then
            argument_error "tremolo" 1 "must be nonnegative"
        else if c < 0.0 || c > 1.0 then
            argument_error "tremolo" 2 "must be between 0.0 and 1.0"
        else
            Sound.tremolo t c}

