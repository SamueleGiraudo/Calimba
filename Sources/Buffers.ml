(* Author: Samuele Giraudo
 * Creation: aug. 2021
 * Modifications: aug. 2021, nov. 2021, may 2022, aug. 2022, jul. 2023
 *)

(* The buffer for sounds. A buffer contains a sound data encoded by its wave in the PCM
 * format. *)

(* Returns the default sampling rate expressed in number of values by second for the wave
 * contained in the buffer. *)
let sampling_rate =
    48000

(* Returns the default depth expressed in bytes (8 bits) used to represent each value of the
 * wave in the buffer. *)
let depth =
    4

(* This is the default buffer path. The files stored in this directory are in RAM instead on
 * the disk. *)
let path_directory =
    "/dev/shm/Calimba/"

(* The default buffer file. *)
let path_file =
    path_directory ^ "Buffer.pcm"

(* Returns the length of the buffer in bytes. *)
let length () =
    try
        let buffer = open_in path_file in
        let size = in_channel_length buffer in
        close_in buffer;
        size
    with
        |_ -> 0

(* Returns the number of values of the wave in the buffer in seconds. *)
let nb_values () =
    float (length ()) /. float depth

(* Returns the duration of the wave in the buffer in seconds. *)
let duration () =
    nb_values () /. float sampling_rate

(* Remove the buffer file from the file system. *)
let delete () =
    try Sys.remove path_file with |_ -> ()

(* Returns the list of size size of integers, each between 0 and 255, encoding the integer
 * value v. The representation is in little-endian and encodes negative values by their
 * two's complement. *)
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

(* Returns the integer value represented in little-endian by the list of bytes byte_lst. *)
let bytes_to_value byte_lst =
    assert (byte_lst <> []);
    assert (byte_lst |> List.for_all (fun b -> 0 <= b && b < 256));
    let byte_lst' = List.rev byte_lst in
    let tmp = byte_lst' |> List.fold_left (fun res b -> b + res * 256 ) 0 in
    if List.hd byte_lst' < 128 then
        tmp
    else
        - ((1 lsl ((List.length byte_lst) * 8)) - tmp)

(* Writes the sound s in the buffer. *)
let write s =
    let buffer = open_out path_file in
    let mult = (1 lsl ((8 * depth) - 1)) - 1 in
    let mult' = float mult in
    let nb_points = int_of_float (Sounds.duration s *. (float sampling_rate)) in
    let rec write_bytes i =
        if i mod 655536 = 0 then flush buffer;
        if i < nb_points then begin
            let x = float i /. float sampling_rate in
            let y = Sounds.value s x in
            let y' =
                mult' *. copysign (min (Float.abs y) 1.0) y
                |> Scalars.float_to_rounded_int
            in
            let byte_lst = value_to_bytes y' depth in
            byte_lst |> List.iter (fun x -> output_byte buffer x);
            write_bytes (i + 1)
        end
    in
    write_bytes 0;
    close_out buffer

(* Returns the command to play a sound calling aplay with the good parameters. The path to
 * the buffer is not included by the command in order to be able to pipe it from a file. *)
let command_play =
    let format_string =
        match depth with
            |1 -> "U8"
            |2 -> "S16_LE"
            |3 -> "S24_3LE"
            |4 -> "S32_LE"
            |_ -> raise (Failure "Unknown format.")
    in
    Printf.sprintf "aplay -c 1 -t raw -r %d -f %s &> /dev/null" sampling_rate format_string

(* Plays the sound specified by the wave which is in the buffer. *)
let play () =
    let cmd = Printf.sprintf "cat %s | %s" path_file command_play in
    Sys.command cmd |> ignore

(* Returns a string containing information about the sound s of which the wave is in the
 * buffer. *)
let to_information_string () =
    Printf.sprintf "Path: %s\n" path_file
    ^
    Printf.sprintf "Sampling rate (Hz): %d\n" sampling_rate
    ^
    Printf.sprintf "Depth (B): %d\n" depth
    ^
    Printf.sprintf "Duration (s): %.2f\n" (duration ())
    ^
    Printf.sprintf "Size (B): %d\n" (length ())

(* Writes the buffer into a PCM file at path path. *)
let write_pcm_file path =
    assert (not (Sys.file_exists path));
    assert (Paths.extension path = ".pcm");
    Sys.command (Printf.sprintf "cp %s %s" path_file path) |> ignore

(* Draws the wave of the buffer into an SVG file at path path. *)
let write_svg_file path =
    assert (not (Sys.file_exists path));
    assert (Paths.extension path = ".svg");
    let height = 256 in
    let width = 1024.0 +. 128.0 *. duration () |> Scalars.float_to_rounded_int in
    let nb_values = nb_values () in
    let max_value = 1 lsl ((depth * 8) - 1) |> float in
    let factor_x = float width -. 1.0 and factor_y = float height -. 1.0 in
    let buffer = open_in path_file in
    let f_out = open_out path in
    Printf.fprintf f_out "<svg width=\"%d\" height=\"%d\">\n" width height;
    Printf.fprintf f_out "<polyline fill=\"none\" stroke=\"black\" stroke-width=\"0.5\"\n";
    Printf.fprintf f_out "points=\"\n";
    let rec write_points i previous_line =
        if i < int_of_float nb_values then begin
            let x = float i /. nb_values in
            let byte_lst = List.init depth (fun _ -> input_byte buffer) in
            let y = float (bytes_to_value byte_lst) /. max_value in
            let x' = factor_x *. x |> Scalars.float_to_rounded_int in
            let y' = factor_y *. (-. y +. 1.0) /. 2.0 |> Scalars.float_to_rounded_int in
            let line = Printf.sprintf "%d,%d\n" x' y' in
            if line <> previous_line then output_string f_out line;
            write_points (i + 1) line
        end
    in
    write_points 0 "";
    Printf.fprintf f_out "\"/>\n";
    Printf.fprintf f_out "</svg>\n";
    close_in buffer;
    close_out f_out

