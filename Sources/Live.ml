(* Author: Samuele Giraudo
 * Creation: jul. 2020
 * Modifications: jul. 2020
 *)

let help_string =
    "Ctrl+Z to stop."

let info_line i =
    Printf.sprintf "> Iteration %03d" i

;;

(* Main expression. *)

let path = Sys.argv.(1) in

let rec loop last_modif i =
    print_string (info_line i);
    print_newline ();
    Thread.delay 1.0;
    let last_modif' = (Unix.stat path).Unix.st_mtime in
    if Option.is_none last_modif || Option.get last_modif < last_modif' then begin
        Printf.printf "A modification is detected.\n";
        Printf.printf "Killing previous processes...";
        ignore (Sys.command "killall aplay");
        ignore (Sys.command "killall calimba");
        Printf.printf " done.\n";
        let cmd = Printf.sprintf "./calimba -f %s" path in
        Printf.printf "Relaunching the processes...";
        ignore (Thread.create (fun _ -> ignore (Sys.command cmd)) ());
        Printf.printf " done.\n"
    end;
    loop (Some (last_modif')) (i + 1)
in

print_string help_string;
print_newline ();
loop None 1

