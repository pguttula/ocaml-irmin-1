

(* Utility functions *)
(* U is a module with two functions *)
module U = struct
  let string_of_list f l = "[ " ^ List.fold_left (fun a b -> a ^ (f b) ^ "; ") "" l ^ "]"
  let print_header h = Printf.printf "%s" ("\n" ^ h ^ "\n")
end

(* Set - AVL Tree *)
let _ =
  U.print_header "List";
let module MkConfig (Vars: sig val root: string end) : Ilist.Config = struct
  let root = Vars.root
  let shared = "/tmp/repos/shared.git"

  let init () =
    let _ = Sys.command (Printf.sprintf "rm -rf %s" root) in
    let _ = Sys.command (Printf.sprintf "mkdir -p %s" root) in
    ()
end in

let module CharAtom = struct
    type t = char
    let t = Irmin.Type.char
    (* User defined merges for atom values *)
    let resolve x y = '#'
    let merge3 ~ancestor x y = '#'

    (* Used for presentation purposes *)
    let to_string c = String.make 1 c
    let of_string s = 's'
    let compare = Char.compare
  end in

let module CInit = MkConfig(struct let root = "/tmp/repos/init.git" end) in
let module MInit = Ilist.MakeVersioned(CInit)(CharAtom) in
let module M = Mvector_list.Make(CharAtom) in
let module Vpst = MInit.Vpst in

let (>>=) = Vpst.bind  in

let thread2_f : unit Vpst.t =
  Vpst.get_latest_version () >>= fun c0 ->
  let c0' = (MInit.OM.set c0 4 'w')   in
  Vpst.sync_next_version ~v:c0' >>= fun c1 ->
  Vpst.liftLwt @@ Lwt_unix.sleep 0.5 >>= fun () ->
  let c1' = (MInit.OM.set c1 2 'o')  in
  Vpst.sync_next_version ~v:c1' >>= fun c2 ->
  let _ = Printf.printf "merged : %s\n" (U.string_of_list CharAtom.to_string c2) in
  Vpst.return ()  in


 let thread1_f : unit Vpst.t =
  Vpst.get_latest_version () >>= fun c0 ->
  Vpst.fork_version thread2_f >>= fun () ->
  Vpst.liftLwt @@ Lwt_unix.sleep 0.1 >>= fun () ->
  let c0' = (MInit.OM.set c0 1 'r') in
  Vpst.sync_next_version ~v:c0' >>= fun c1 ->
  Vpst.liftLwt @@ Lwt_unix.sleep 0.1 >>= fun () ->
  let c1' = (MInit.OM.set c1 2 'l') in
  Vpst.sync_next_version ~v:c1' >>= fun c2 ->
  let _ = Printf.printf "merged : %s\n" (U.string_of_list CharAtom.to_string c2) in
  Vpst.liftLwt @@ Lwt_unix.sleep 1.1 >>= fun () ->
  Vpst.sync_next_version ~v:c2 >>= fun c3->
  let _ = Printf.printf "merged : %s\n" (U.string_of_list CharAtom.to_string c3) in
  Vpst.return ()   in

  let main () =
   let original = ['h'; 'e'; 'l'; 'l'; 'o'] in
   Vpst.with_init_version_do original thread1_f in

main ();;
