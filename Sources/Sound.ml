(* Author: Samuele Giraudo
 * Creation: (jul. 2015), apr. 2020
 * Modifications: apr. 2020, may 2020, jul. 2020, aug. 2020, dec. 2020
 *)

(* Functional representation of a sound. *)
type sound = {
    (* This map sends each point to a signed value. This encodes the wave of the sound. *)
    map : int -> float;

    (* The size of a sound is its total number of points. The wave is considered on the
     * interval [0, size - 1]. *)
    size : int
}

(* A shape is a map from [0.0, 1.0] to [0.0, 1.0] sending each time value, normalized in the
 * interval [0.0, 1.0], to a coefficient between 0.0 and 1.0 representing its loudness. *)
type shape = float -> float

(* Returns the default sampling rate (the number of points by second). *)
let sampling_rate =
    48000

(* Returns the default number of byte depth (the number of bytes used to represent each
 * point). This is used to write sounds on PCM files. *)
let byte_depth =
    4

(* This is the default buffer path, where PCM files are stored. This file is stored in the
 * RAM instead of on the disk. *)
let buffer_path =
    "/dev/shm/Synth/Buffer.pcm"

(* Tests if s is a sound. *)
let is_valid s =
    s.size >= 0

(* Returns the sound with the specified attributes. *)
let construct map size =
    assert (size >= 0);
    {map = map; size = size}

(* Returns the map of the sound s. *)
let map s =
    assert (is_valid s);
    s.map

(* Returns the size of the sound s. *)
let size s =
    assert (is_valid s);
    s.size

(* Returns the value of the point i of the sound s. If i is not a point of s, 0.0 is
 * returned.*)
let value s i =
    assert (is_valid s);
    if 0 <= i && i < s.size then
        s.map i
    else
        0.0

(* Returns the duration of the sound s in ms. *)
let duration s =
    assert (is_valid s);
    (1000 * s.size) / sampling_rate

(* Returns the size, which the number of points, needed to encode a sound having a duration
 * of duration ms. *)
let duration_to_size duration =
    assert (0 <= duration);
    (duration * sampling_rate) / 1000

(* Returns the sound of size size obtained from the sound s by starting at index j. *)
let factor s j size =
    assert (is_valid s);
    assert (0 <= j && j < s.size);
    assert (0 <= size && j + size - 1 < s.size);
    let map i =
        s.map (j + i)
    in
    {map = map; size = size}

(* Returns the sounds obtained by keeping the first size points of the sound s. *)
let prefix s size =
    assert (is_valid s);
    assert (0 <= size && size <= s.size);
    factor s 0 size

(* Returns the sounds obtained by keeping the last size points of the sound s. *)
let suffix s size =
    assert (is_valid s);
    assert (0 <= size && size <= s.size);
    factor s (s.size - size + 1) size

(* Returns the silent sound with a duration of duration ms. *)
let silence duration =
    assert (0 <= duration);
    {map = (fun _ -> 0.0); size = duration_to_size duration}

(* Returns a sinusoidal sound with a duration of duration ms. *)
let sinusoidal freq duration =
    assert (1 <= duration);
    assert (0. < freq);
    let sampling_rate' = float_of_int sampling_rate in
    let map i =
        let i' = float_of_int i in
        sin ((2.0 *. Float.pi *. freq *. i') /. sampling_rate')
    in
    {map = map; size = duration_to_size duration}

(* Returns the sound obtained by applying the shape sh to the sound s. *)
let apply_shape s sh =
    assert (is_valid s);
    let size = float_of_int s.size in
    let map i =
        let i' = (float_of_int i) /. size in
        (s.map i) *. (sh i')
    in
    {map = map; size = s.size}

(* Returns the composition of the two shapes sh1 and sh2. *)
let compose_shapes sh1 sh2 =
    fun i -> (sh1 i) *. (sh2 i)

(* Returns the maximal absolute value among the values of the points of the sound s. *)
let magnitude s =
    assert (is_valid s);
    let rec aux i m =
        if i = s.size then
            m
        else
            let v = abs_float (s.map i) in
            aux (i + 1) (max m v)
    in
    aux 0 (s.map 0)

(* Returns the clipped version of the sound s with a threshold of c. This replaces each
 * point having absolute value greater than c into c, with the same sign. *)
let clip s c =
    assert (is_valid s);
    assert (0.0 <= c && c <= 1.0);
    let map i =
        let y = s.map i in
        copysign (min (abs_float y) c) y
    in
    {s with map = map}

(* Returns the sound obtained from the sound s by sending to 1.0 (resp. -1.0) each point
 * greater than 1.0 (resp. smaller than -1.0). *)
let cut s =
    assert (is_valid s);
    clip s 1.0

(* Returns the sound obtained by multiplying each point of the sound s by the value v. The
 * result is cut. *)
let scale v s =
    assert (is_valid s);
    assert (0.0 <= v);
    let s' = {s with map = (fun i -> (s.map i) *. v)} in
    cut s'

(* Returns the normalized sound of the sound s. The points of the sound are put
 * proportionally between -1.0 and 1.0. *)
let normalize s =
    assert (is_valid s);
    scale (1. /. (magnitude s)) s

(* Returns the sound obtained by adding the sounds of the list of sounds lst. They can have
 * different sizes. *)
let add_list lst =
    assert (lst |> List.for_all is_valid);
    let map i =
        lst |> List.fold_left (fun res s -> res +. (value s i)) 0.0
    in
    let size = lst |> List.fold_left (fun res s -> max res s.size) 0 in
    let s' = {size = size; map = map} in
    cut s'

(* Returns the sound obtained by adding the sounds s1 and s2. They can have different
 * sizes. *)
let add s1 s2 =
    assert (is_valid s1);
    assert (is_valid s2);
    add_list [s1; s2]

(* Returns the sound obtained by concatenating the sounds s1 and s2. *)
let concatenate s1 s2 =
    assert (is_valid s1);
    assert (is_valid s2);
    let map i =
        if i < s1.size then
            s1.map i
        else
            s2.map (i - s1.size)
    in
    {map = map; size = s1.size + s2.size}

(* Returns the sound obtained by concatenating the sounds of the list of sounds lst. *)
let concatenate_list lst =
    assert (lst |> List.for_all is_valid);
    lst |> List.fold_left concatenate (silence 0)

(* Returns the sound obtained by repeating k times the sound s. *)
let repeat s k =
    assert (is_valid s);
    assert (1 <= s.size);
    assert (k >= 0);
    let map i =
        s.map (i mod s.size)
    in
    {map = map; size = k * s.size}

(* Returns the sound obtained by adding to the sound s a time shifted version of s by
 * time ms. The delayed sound is scaled with c as coefficient. *)
let delay time c s =
    assert (is_valid s);
    assert (0 <= time);
    assert (0.0 <= c);
    let s' = concatenate (silence time) s in
    prefix (add s (scale c s')) s.size

(* Returns the sound obtained by applying a tremolo (periodic variation of the volume) on
 * the sound s. The periodic variation of the tremolo is of time ms, and the amplitude never
 * goes below the coefficient c. *)
let tremolo time c s =
    assert (is_valid s);
    assert (0 <= time);
    assert (0.0 <= c && c <= 1.0);
    let freq = (float_of_int (duration s)) /. (float_of_int time) in
    let sh i =
        let v = cos (2.0 *. Float.pi *. freq *. i) in
        ((c -. 1.0) *. v +. c +. 1.0) /. 2.0
    in
    apply_shape s sh

(* Returns the list of size size of integers, each between 0 and 255, encoding the integer
 * value v. The representation is in little-endian and encodes negative value by two
 * complement. *)
let value_to_bytes v size =
    assert (size >= 1);
    let rec encoding x n =
        if n = 0 then
            []
        else
            let m = x land 0xFF and q = x asr 8 in
            m :: (encoding q (n - 1))
    in
    if v >= 0 then
        encoding v size
    else
        let tmp = (1 lsl (size lsl 3)) + v in
        encoding tmp size

(* Writes in the channel channel open in binary and out mode the sound s. *)
let print_raw s channel =
    assert (is_valid s);
    let mult = (1 lsl ((8 * byte_depth) - 1)) - 1 in
    let mult' = float_of_int mult in
    let rec write_bytes i =
        if i mod 2048 = 0 then flush channel;
        if 0 <= i && i < s.size then begin
            let v = int_of_float ((s.map i) *. mult') in
            let byte_lst = value_to_bytes v byte_depth in
            byte_lst |> List.iter (fun x -> output_byte channel x);
            write_bytes (i + 1)
        end
    in
    write_bytes 0

(* Writes the sound s in the buffer file. *)
let write_buffer s =
    assert (is_valid s);
    let buffer = open_out buffer_path in
    print_raw s buffer;
    close_out buffer

(* Returns the command to play a sound calling aplay with the good parameters. The last
 * parameter (path to the RAW file) is not included by the command in order to be able to
 * pipe it from a file. *)
let command_play =
    let format_string =
        match byte_depth with
            |1 -> "U8"
            |2 -> "S16_LE"
            |3 -> "S24_3LE"
            |4 -> "S32_LE"
            |_ -> raise (Failure "Unknown format.")
    in
    Printf.sprintf "aplay -c 1 -t raw -r %d -f %s" sampling_rate format_string

(* Plays the sound which is in the buffer. *)
let play_buffer () =
    let cmd = Printf.sprintf "%s %s" command_play buffer_path in
    ignore (Sys.command cmd)

(* Remove the buffer file from the file system. *)
let delete_buffer () =
    try
        Sys.remove buffer_path;
    with
        |_ -> ()

(* Plays the sound s. *)
let play s =
    assert (is_valid s);
    let thread_writer = Thread.create (fun _ -> write_buffer s) () in
    let thread_reader = Thread.create
        (fun _ ->
            Thread.delay 1.0;
            let cmd = Printf.sprintf "cat %s | %s" buffer_path command_play in
            Sys.command cmd)
        ()
    in
    Thread.join thread_writer;
    Thread.join thread_reader


(* The test function of the module. *)
let test () =
    print_string "Sound\n";
    true
