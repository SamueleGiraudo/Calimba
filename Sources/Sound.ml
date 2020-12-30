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

(* Returns the default sampling rate (the number of points by second). *)
let sampling_rate =
    48000

(* Returns the default number of byte depth (the number of bytes used to represent each
 * point). This is used to write sounds on PCM files. *)
let byte_depth =
    4

(* This is the default buffer path, where PCM files are stored. The files stored in this
 * directory are in RAM instead on the disk. *)
let buffer_path_directory =
    "/dev/shm/Calimba/"

(* The default buffer PCM file. *)
let buffer_path_file =
    buffer_path_directory ^ "Buffer.pcm"

(* Returns the sound with the specified attributes. *)
let construct map size =
    assert (size >= 0);
    {map = map; size = size}

(* Returns the map of the sound s. *)
let map s =
    s.map

(* Returns the size of the sound s. *)
let size s =
    s.size

(* Returns the value of the point i of the sound s. If i is not a point of s, 0.0 is
 * returned.*)
let value s i =
    if 0 <= i && i < s.size then
        s.map i
    else
        0.0

(* Returns the size, which the number of points, needed to encode a sound having a duration
 * of duration ms. *)
let duration_to_size duration =
    assert (0 <= duration);
    (duration * sampling_rate) / 1000

(* Returns the duration in ms of an hypothetical sound of size size. *)
let size_to_duration size =
    assert (0 <= size);
    (1000 * size) / sampling_rate

(* Returns the duration of the sound s in ms. *)
let duration s =
    size_to_duration s.size

(* Returns the sound of size size obtained from the sound s by starting at index j. *)
let factor s j size =
    assert (0 <= j && j < s.size);
    assert (0 <= size && j + size - 1 < s.size);
    {map = (fun i -> s.map (j + i)); size = size}

(* Returns the sounds obtained by keeping the first size points of the sound s. *)
let prefix s size =
    assert (0 <= size && size <= s.size);
    factor s 0 size

(* Returns the sounds obtained by keeping the last size points of the sound s. *)
let suffix s size =
    assert (0 <= size && size <= s.size);
    factor s (s.size - size + 1) size

(* Returns the silent sound with a duration of duration ms. *)
let silence duration =
    assert (0 <= duration);
    {map = (fun _ -> 0.0); size = duration_to_size duration}

(* Returns the empty sound. *)
let empty =
    silence 0

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
    let size = float_of_int s.size in
    let map i =
        let i' = (float_of_int i) /. size in
        (s.map i) *. (Shape.to_map sh i')
    in
    {s with map = map}

(* Returns the maximal absolute value among the values of the points of the sound s. *)
let magnitude s =
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
    assert (0.0 <= c && c <= 1.0);
    let map i =
        let y = s.map i in
        copysign (min (abs_float y) c) y
    in
    {s with map = map}

(* Returns the sound obtained from the sound s by sending to 1.0 (resp. -1.0) each point
 * greater than 1.0 (resp. smaller than -1.0). *)
let cut s =
    clip s 1.0

(* Returns the sound obtained by multiplying each point of the sound s by the value v. The
 * result is cut. *)
let scale v s =
    assert (0.0 <= v);
    let s' = {s with map = (fun i -> (s.map i) *. v)} in
    cut s'

(* Returns the normalized sound of the sound s. The points of the sound are put
 * proportionally between -1.0 and 1.0. *)
let normalize s =
    scale (1. /. (magnitude s)) s

(* Returns the sound obtained by adding the sounds of the list of sounds lst. They can have
 * different sizes. *)
let add_list lst =
    let map i =
        lst |> List.fold_left (fun res s -> res +. (value s i)) 0.0
    in
    let size = lst |> List.fold_left (fun res s -> max res s.size) 0 in
    let s' = {size = size; map = map} in
    cut s'

(* Returns the sound obtained by adding the sounds s1 and s2. They can have different
 * sizes. *)
let add s1 s2 =
    add_list [s1; s2]

(* Returns the sound obtained by concatenating the sounds s1 and s2. *)
let concatenate s1 s2 =
    let map i =
        if i < s1.size then
            s1.map i
        else
            s2.map (i - s1.size)
    in
    {map = map; size = s1.size + s2.size}

(* Returns the sound obtained by concatenating the sounds of the list of sounds lst. *)
let concatenate_list lst =
    lst |> List.fold_left concatenate empty

(* Returns the sound obtained by repeating k times the sound s. *)
let repeat s k =
    assert (1 <= s.size);
    assert (k >= 0);
    let map i =
        s.map (i mod s.size)
    in
    {map = map; size = k * s.size}

(* Returns the sound obtained by adding to the sound s a time shifted version of s by
 * time ms. The delayed sound is scaled with c as coefficient. *)
let delay time c s =
    assert (0 <= time);
    assert (0.0 <= c);
    let s' = concatenate (silence time) s in
    prefix (add s (scale c s')) s.size

(* Returns the sound obtained by applying a tremolo (periodic variation of the volume) on
 * the sound s. The periodic variation of the tremolo is of time ms, and the amplitude never
 * goes below the coefficient c. *)
let tremolo time c s =
    assert (0 <= time);
    assert (0.0 <= c && c <= 1.0);
    apply_shape s (Shape.tremolo time c (duration s))

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
    let buffer = open_out buffer_path_file in
    print_raw s buffer;
    close_out buffer

(* Returns the command to play a sound calling aplay with the good parameters. The last
 * parameter (path to the PCM file) is not included by the command in order to be able to
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
    Printf.sprintf "aplay -c 1 -t raw -r %d -f %s &> /dev/null" sampling_rate format_string

(* Plays the sound which is in the buffer. *)
let play_buffer () =
    let cmd = Printf.sprintf "%s %s" command_play buffer_path_file in
    ignore (Sys.command cmd)

(* Remove the buffer file from the file system. *)
let delete_buffer () =
    try
        Sys.remove buffer_path_file;
    with
        |_ -> ()

(* Plays the sound s. *)
let play s =
    let thread_writer = Thread.create (fun _ -> write_buffer s) () in
    let thread_reader = Thread.create
        (fun _ ->
            Thread.delay 1.0;
            let cmd = Printf.sprintf "cat %s | %s" buffer_path_file command_play in
            Sys.command cmd)
        ()
    in
    Thread.join thread_writer;
    Thread.join thread_reader

(* Draw the signal of the sound s in a new window. *)
let draw s =
    let width = 920 and height = 220 and border = 16 in
    Graphics.open_graph (Printf.sprintf " %dx%d" width height);
    let color_point y =
        let y' = int_of_float (255.0 *. ((Float.abs y) ** 0.5)) in
        let y'' = 255 - y' in
        if y >= 0.0 then
            Graphics.rgb y' y' y'
        else
            Graphics.rgb y'' y'' y''
    in
    let width' = float_of_int (width - 2 * border)
    and height' = float_of_int (height - 2 * border) in
    let border' = float_of_int border in
    let size = float_of_int s.size in
    List.init s.size Fun.id |> List.iter
        (fun i ->
            let k = s.map i in
            let x = border' +. width' *. (float_of_int i)  /. size in
            let y = border' +. height' *. (k +. 1.)  /. 2. in
            Graphics.set_color (color_point k);
            Graphics.plot (int_of_float x) (int_of_float y));
    Graphics.synchronize ();
    (Graphics.wait_next_event [Graphics.Key_pressed]) |> ignore;
    Graphics.close_graph ()

