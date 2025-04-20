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
  sto_loss : float;
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
    ("sto_loss", `Float t.sto_loss);
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
     take_profit, sto_loss, punta_compra, punta_venta, last_update \
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
          sto_loss = column_to_float (Sqlite3.column stmt 7);
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


(* Handler que responde con JSON *)
let tickets_handler _req =
  let tickets = get_tickets () in
  tickets
  |> List.map ticket_to_yojson
  |> fun json_list -> `List json_list
  |> Yojson.Safe.to_string
  |> Dream.json

(* Servidor web *)
let () =
  Dream.run
  ~interface:"0.0.0.0"
  ~port:8080
  (Dream.logger
  @@ Dream.router [
    Dream.get "/api/tickets" tickets_handler;
  ])

