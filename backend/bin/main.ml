(* Ya no necesarias si usas nombres calificados *)
(* open Dream *)
(* open Sqlite3 *)
(* open Yojson.Safe *)

(* Definición del tipo ticket *)
type ticket = {
  ticket_name : string;
  estado : string;
  compra1 : float;
  compra2 : float;
  venta1 : float;
  venta2 : float;
  take_profit : float;
  stop_loss : float;
  punta_compra : float;
  punta_venta : float;
  last_update : string;
}

(* Convertimos un ticket a JSON *)
let ticket_to_yojson t =
  `Assoc [
    ("ticket_name", `String t.ticket_name);
    ("estado", `String t.estado);
    ("compra1", `Float t.compra1);
    ("compra2", `Float t.compra2);
    ("venta1", `Float t.venta1);
    ("venta2", `Float t.venta2);
    ("take_profit", `Float t.take_profit);
    ("stop_loss", `Float t.stop_loss);
    ("punta_compra", `Float t.punta_compra);
    ("punta_venta", `Float t.punta_venta);
    ("last_update", `String t.last_update)
  ]

(* Conectamos a la base de datos y leemos los tickets *)
(* Convertir columna a string de forma segura *)
let column_to_string col =
  match col with
  | Sqlite3.Data.TEXT s -> s
  | Sqlite3.Data.NULL -> ""
  | _ -> ""

(* Convertir columna a float de forma segura *)
let column_to_float col =
  match col with
  | Sqlite3.Data.FLOAT f -> f
  | Sqlite3.Data.INT i -> Int64.to_float i
  | _ -> 0.0

(* Leer tickets desde la base de datos *)
let get_tickets () : ticket list =
  let db = Sqlite3.db_open "iol.db" in
  let tickets = ref [] in

  let sql =
    "SELECT ticket_name, estado, compra1, compra2, venta1, venta2, \
     take_profit, stop_loss, punta_compra, punta_venta, last_update \
     FROM tickets"
  in

  let stmt = Sqlite3.prepare db sql in

  (* Loop recursivo para recorrer todas las filas *)
  let rec loop () =
    match Sqlite3.step stmt with
    | Sqlite3.Rc.ROW ->
        let t = {
          ticket_name = column_to_string (Sqlite3.column stmt 0);
          estado = column_to_string (Sqlite3.column stmt 1);
          compra1 = column_to_float (Sqlite3.column stmt 2);
          compra2 = column_to_float (Sqlite3.column stmt 3);
          venta1 = column_to_float (Sqlite3.column stmt 4);
          venta2 = column_to_float (Sqlite3.column stmt 5);
          take_profit = column_to_float (Sqlite3.column stmt 6);
          stop_loss = column_to_float (Sqlite3.column stmt 7);
          punta_compra = column_to_float (Sqlite3.column stmt 8);
          punta_venta = column_to_float (Sqlite3.column stmt 9);
          last_update = column_to_string (Sqlite3.column stmt 10);
        } in
        tickets := t :: !tickets;
        loop ()
    | Sqlite3.Rc.DONE -> ()
    | _ -> ()
  in

  loop ();
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db);
  List.rev !tickets

(* Actualizar un ticket en la base de datos *)
let update_ticket ticket =
  let db = Sqlite3.db_open "iol.db" in
  let sql =
    "UPDATE tickets SET estado = ?, compra1 = ?, compra2 = ?, venta1 = ?, venta2 = ?, \
     take_profit = ?, stop_loss = ?, punta_compra = ?, punta_venta = ?, last_update = ? \
     WHERE ticket_name = ?"
  in
  
  let stmt = Sqlite3.prepare db sql in
  ignore (Sqlite3.bind stmt 1 (Sqlite3.Data.TEXT ticket.estado));
  ignore (Sqlite3.bind stmt 2 (Sqlite3.Data.FLOAT ticket.compra1));
  ignore (Sqlite3.bind stmt 3 (Sqlite3.Data.FLOAT ticket.compra2));
  ignore (Sqlite3.bind stmt 4 (Sqlite3.Data.FLOAT ticket.venta1));
  ignore (Sqlite3.bind stmt 5 (Sqlite3.Data.FLOAT ticket.venta2));
  ignore (Sqlite3.bind stmt 6 (Sqlite3.Data.FLOAT ticket.take_profit));
  ignore (Sqlite3.bind stmt 7 (Sqlite3.Data.FLOAT ticket.stop_loss));
  ignore (Sqlite3.bind stmt 8 (Sqlite3.Data.FLOAT ticket.punta_compra));
  ignore (Sqlite3.bind stmt 9 (Sqlite3.Data.FLOAT ticket.punta_venta));
  ignore (Sqlite3.bind stmt 10 (Sqlite3.Data.TEXT ticket.last_update));
  ignore (Sqlite3.bind stmt 11 (Sqlite3.Data.TEXT ticket.ticket_name));
  
  let result = Sqlite3.step stmt in
  ignore (Sqlite3.finalize stmt);
  ignore (Sqlite3.db_close db);
  match result with
  | Sqlite3.Rc.DONE -> true
  | _ -> false

(* Deserializar un ticket desde JSON *)
let ticket_from_json json =
  try
    let open Yojson.Safe.Util in
    {
      ticket_name = json |> member "ticket_name" |> to_string;
      estado = json |> member "estado" |> to_string;
      compra1 = json |> member "compra1" |> to_float;
      compra2 = json |> member "compra2" |> to_float;
      venta1 = json |> member "venta1" |> to_float;
      venta2 = json |> member "venta2" |> to_float;
      take_profit = json |> member "take_profit" |> to_float;
      stop_loss = json |> member "stop_loss" |> to_float;
      punta_compra = json |> member "punta_compra" |> to_float;
      punta_venta = json |> member "punta_venta" |> to_float;
      last_update = json |> member "last_update" |> to_string;
    }
  with _ -> 
    failwith "Invalid JSON format for ticket"

(* Handler que responde con JSON *)
let tickets_handler _req =
  let tickets = get_tickets () in
  tickets
  |> List.map ticket_to_yojson
  |> fun json_list -> `List json_list
  |> Yojson.Safe.to_string
  |> Dream.json

(* Handler para actualizar un ticket *)
let update_ticket_handler req =
  let open Lwt.Syntax in
  let* body = Dream.body req in
  try
    let json = Yojson.Safe.from_string body in
    let ticket = ticket_from_json json in
    let success = update_ticket ticket in
    if success then
      Dream.json "{\"status\": \"success\", \"message\": \"Ticket actualizado correctamente\"}"
    else
      Dream.json ~status:`Internal_Server_Error "{\"status\": \"error\", \"message\": \"Error al actualizar el ticket\"}"
  with e ->
    Dream.json ~status:`Bad_Request (Printf.sprintf "{\"status\": \"error\", \"message\": \"Error en el formato: %s\"}" 
                             (Printexc.to_string e))

(* Leer un archivo *)
let read_file path =
  let ic = open_in path in
  let len = in_channel_length ic in
  let content = really_input_string ic len in
  close_in ic;
  content

(* Servidor web *)
let static_handler = Dream.static "public"
let () =
  Dream.run
  ~interface:"0.0.0.0"
  ~port:8080
  (Dream.logger
  @@ Dream.router [
    (* API *)
    Dream.get "/api/tickets" tickets_handler;
    Dream.put "/api/tickets" update_ticket_handler;

    (* Archivos estáticos del frontend *)
    Dream.get "/" (fun _ -> Dream.html (read_file "public/index.html"));

    Dream.get "/elm.js" static_handler;
    Dream.get "/index.html" static_handler;
  ])
