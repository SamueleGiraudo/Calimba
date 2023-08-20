(* Author: Samuele Giraudo
* Creation: (may 2021), jul. 2023
* Modifications: jul. 2023
*)

(* Returns the sound specified by the expression e. This expression has to be simple. *)
let compute e =
    assert (Properties.is_simple e);
    let mem = ref PMap.empty in
    let rec aux freq e =
        let preimage = (freq, e) in
        if PMap.exists preimage !mem then
            PMap.find preimage !mem
        else
            let res =
                match e with
                    |Expressions.Beat _ -> Sounds.sinusoidal (Scalars.value freq) 1.0
                    |Expressions.CycleOperation (_, op, e1) -> begin
                        match op with
                            |Expressions.UpdateCycleNumber x ->
                                aux (Scalars.multiplication freq x) e1
                            |Expressions.ResetCycleNumber -> aux (Scalars.Scalar 1.0) e1
                    end
                    |Expressions.UnaryOperation (_, op, e1) -> begin
                        match op with
                            |Expressions.VerticalScaling x ->
                                Sounds.vertical_scaling (Scalars.value x) (aux freq e1)
                            |Expressions.HorizontalScaling x ->
                                Sounds.horizontal_scaling (Scalars.value x) (aux freq e1)
                    end
                    |Expressions.BinaryOperation (_, op, e1, e2) -> begin
                        let s1 = aux freq e1 and s2 = aux freq e2 in
                        match op with
                            |Expressions.Concatenation -> Sounds.concatenate s1 s2
                            |Expressions.Addition -> Sounds.add s1 s2
                            |Expressions.Multiplication -> Sounds.multiply s1 s2
                    end
                    |Expressions.FlagTest _ |Expressions.FlagModification _
                    |Expressions.Alias _ |Expressions.AliasDefinition _
                    |_ -> Expressions.ValueError (e, "sound") |> raise
            in
            mem := PMap.add preimage res !mem;
            res
    in
    aux (Scalars.Scalar 1.0) e

