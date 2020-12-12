(* Author: Samuele Giraudo
 * Creation: dec. 2020
 * Modifications: dec. 2020
 *)

type data = string

type syntax =
    |Name of data
    |AtomSilence
    |AtomBeat of data
    |AtomLabeledBeat of data * data
    |Concatenation of syntax * syntax
    |Composition of syntax * syntax
    |IncreaseOctave of syntax
    |DecreaseOctave of syntax
    |IncreaseTime of syntax
    |DecreaseTime of syntax
    |Insertion of syntax * data * syntax
    |LabelInsertion of syntax * data * syntax
    |BinaryInsertion of syntax * syntax
    |Repeat of data * syntax
    |Reverse of syntax
    |Complement of syntax
    |Let of data * syntax * syntax
    |PutLayout of (data list) * syntax
    |PutRoot of data * data * data * syntax
    |PutTimeLayout of data * data * syntax
    |PutUnitDuration of data * syntax
    |PutSynthesizer of data * data * data * data * data * syntax
    |EffectScale of data * syntax
    |EffectDelay of data * data * syntax
    |EffectClip of data * syntax
    |EffectTremolo of data * data * syntax

exception DataError of string

exception ValueError of string

let data_is_integer data =
    true

let data_is_float data =
    true

let data_is_name data =
    true

let rec to_expression s =
    match s with
        |Name name -> Expression.Name name
        |AtomSilence -> Expression.Atom (TreePattern.Silence 0)
        |AtomBeat d ->
            if not (data_is_integer d) then
                raise (DataError "");
            let d' = int_of_string d in
            Expression.Atom (TreePattern.Beat ((Shift.construct d' 0), 0, None))
        |AtomLabeledBeat (d, lbl) ->
            if not (data_is_integer d) then
                raise (DataError "");
            if not (data_is_name lbl) then
                raise (DataError "");
            let d' = int_of_string d in
            Expression.Atom (TreePattern.Beat ((Shift.construct d' 0), 0, Some lbl))
        |Concatenation (s1, s2) ->
            Expression.Concatenation (to_expression s1, to_expression s2)
        |Composition (s1, s2) ->
            Expression.Composition (to_expression s1, to_expression s2)
        |IncreaseOctave s0 -> Expression.IncreaseOctave (to_expression s0)
        |DecreaseOctave s0 -> Expression.DecreaseOctave (to_expression s0)
        |IncreaseTime s0 -> Expression.IncreaseTime (to_expression s0)
        |DecreaseTime s0 ->  Expression.DecreaseTime (to_expression s0)
        |Insertion (s1, i, s2) ->
            if not (data_is_integer i) then
                raise (DataError "");
            let i' = int_of_string i in
            Expression.Insertion (to_expression s1, i', to_expression s2)
        |LabelInsertion (s1, lbl, s2) ->
            if not (data_is_name lbl) then
                raise (DataError "");
            Expression.LabelInsertion (to_expression s1, lbl, to_expression s2)
        |BinaryInsertion (s1, s2) ->
            Expression.BinaryInsertion (to_expression s1, to_expression s2)
        |Repeat (k, s0) ->
            if not (data_is_integer k) then
                raise (DataError "");
            let k' = int_of_string k in
            Expression.Repeat (k', to_expression s0)
        |Reverse s0 -> Expression.Reverse (to_expression s0)
        |Complement s0 -> Expression.Complement (to_expression s0)
        |Let (name, s1, s2) ->
            if not (data_is_name name) then
                raise (DataError "");
            Expression.Let (name, to_expression s1, to_expression s2)
        |PutLayout (lst, s0) ->
            (* TEST *)
            let lst' = lst |> List.map int_of_string in
            Expression.Put (Expression.Layout (Layout.construct lst'), to_expression s0)
        |PutRoot (step, nb, oct, s0) ->
            if not (data_is_integer step) then
                raise (DataError "");
            if not (data_is_integer nb) then
                raise (DataError "");
            if not (data_is_integer oct) then
                raise (DataError "");
            let step' = int_of_string step
            and nb' = int_of_string nb
            and oct' = int_of_string oct in
            Expression.Put
                (Expression.Root (Note.construct step' nb' oct'), to_expression s0)
        |PutTimeLayout (m, d, s0) ->
            if not (data_is_integer m) then
                raise (DataError "");
            if not (data_is_integer d) then
                raise (DataError "");
            let m' = int_of_string m and d' = int_of_string d in
            Expression.Put
                (Expression.TimeLayout (TimeLayout.construct m' d'), to_expression s0)
        |PutUnitDuration (dur, s0) ->
            if not (data_is_integer dur) then
                raise (DataError "");
            let dur' = int_of_string dur in
            Expression.Put (Expression.UnitDuration dur', to_expression s0)
        |PutSynthesizer (scale, coeff, max_dur, o_dur, c_dur, s0) ->
            if not (data_is_float scale) then
                raise (DataError "");
            if not (data_is_float coeff) then
                raise (DataError "");
            if not (data_is_integer max_dur) then
                raise (DataError "");
            if not (data_is_integer o_dur) then
                raise (DataError "");
            if not (data_is_integer c_dur) then
                raise (DataError "");
            let scale' = float_of_string scale
            and coeff' = float_of_string coeff
            and max_dur' = int_of_string max_dur
            and o_dur' = int_of_string o_dur
            and c_dur' = int_of_string c_dur in
            let t = Synthesizer.scale_timbre scale' (Synthesizer.geometric_timbre coeff') in
            Expression.Put
                (Expression.Synthesizer
                    (Synthesizer.construct t max_dur' o_dur' c_dur'), to_expression s0)
        |EffectScale (scale, s0) ->
            if not (data_is_float scale) then
                raise (DataError "");
            let scale' = float_of_string scale in
            Expression.Put
                (Expression.Effect (Sound.scale scale'), to_expression s0)
        |EffectDelay (t, c, s0) ->
            if not (data_is_integer t) then
                raise (DataError "");
            if not (data_is_float c) then
                raise (DataError "");
            let t' = int_of_string t and c' = float_of_string c in
            Expression.Put
                (Expression.Effect (fun s -> Sound.delay s t' c'), to_expression s0)
        |EffectClip (c, s0) ->
            if not (data_is_float c) then
                raise (DataError "");
            let c' = float_of_string c in
            Expression.Put
                (Expression.Effect (fun s -> Sound.clip s c'), to_expression s0)
        |EffectTremolo (t, c, s0) ->
            if not (data_is_integer t) then
                raise (DataError "");
            if not (data_is_float c) then
                raise (DataError "");
            let t' = int_of_string t and c' = float_of_string c in
            Expression.Put
                (Expression.Effect (fun s -> Sound.tremolo s t' c'), to_expression s0)

