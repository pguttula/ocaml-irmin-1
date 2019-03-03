open Lwt.Infix
open Irmin_unix
open Printf

module StoreVal = struct
  type t = string

  let t = Irmin.Type.string

  let pp = Fmt.string

  let of_string s = Ok s

  let merge ~old v1 v2 = Irmin.Merge.ok v2 

  let merge = let open Irmin.Merge in option (v t merge)
end

let _ =
  (printf "Sync Test\n"; flush_all())

module Store = Irmin_unix.Git.FS.KV(StoreVal)

module Sync = Irmin.Sync(Store)

let path = ["state"]

let uri1 = "git+ssh://opam@172.18.0.2/tmp/repos/sync_test.git"
let uri2 = "git+ssh://opam@172.18.0.3/tmp/repos/sync_test.git"

let info s = Irmin_unix.info "[repo sync_test] %s" s

let repo = Lwt_main.run
  begin 
    let config = Irmin_git.config "/tmp/repos/sync_test.git" in
    Store.Repo.v config
  end

let clean () = Sys.command "rm -rf /tmp/repos/sync_test.git" 

(*let init () = Lwt_main.run
  begin 
    store_init >>= fun repo ->
    Store.master repo >>= fun m_br ->
    Lwt.return m_br
  *)

let set_init_version () = Lwt_main.run
  begin 
    Store.master repo >>= fun m_br ->
    Store.set m_br path "Hello World\n"
        ~info:(info "initial version")
  end

let pull_remote remote_uri = Lwt_main.run
  begin 
    Store.master repo >>= fun m_br ->
    let remote = Irmin.remote_uri remote_uri in
    let cinfo = info "pulling remote" in
    Sync.pull m_br remote (`Merge cinfo) >>= fun res ->
    match res with
    | Ok _ -> Lwt.return ()
    | Error _ -> failwith "Error while pulling the remote"
  end

let clone_remote remote_uri = Lwt_main.run
  begin 
    Store.master repo >>= fun m_br ->
    let remote = Irmin.remote_uri remote_uri in
    Sync.pull m_br remote `Set >>= fun res ->
    match res with
    | Ok _ -> Lwt.return ()
    | Error _ -> failwith "Error while cloning the remote"
  end