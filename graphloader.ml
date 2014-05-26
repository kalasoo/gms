open Core.Std
open Graph

module Edge = struct
  type t = string
  let compare = compare
  let default = ""
end

type server_info = {
  id         : int;
  label      : string;
  country    : string;
  longtitude : float;
  latitude   : float;
}

let make_server_info ~id ~label ~country ~longtitude ~latitude = {
  id;
  label;
  country;
  longtitude;
  latitude;
}

module G = Imperative.Digraph.AbstractLabeled(struct
  type t = server_info
end)(Edge)

module B = Builder.I(G)

module NodeEdgeParser = struct
  
  let node l =
    let default_server_info () =
      make_server_info ~id:~-1 ~label:"<label>" ~country:"<country>" ~longtitude:0.0 ~latitude:0.0
    in
    try 
      let id =
        match List.Assoc.find_exn l "id" with
        | Gml.Int n -> n
        | _         -> -1
      in
      let label =
        match List.Assoc.find_exn l "label" with
        | Gml.String s -> s
        | _ -> "<label>"
      in
      let country =
        match List.Assoc.find_exn l "country" with
        | Gml.String s -> s
        | _ -> "<country>"
      in
      let longtitude =
        match List.Assoc.find_exn l "longtitude" with
        | Gml.Float f -> f
        | _ -> 0.0
      in
      let latitude =
        match List.Assoc.find_exn l "latitude" with
        | Gml.Float f -> f
        | _ -> 0.0
      in
      make_server_info ~id ~label ~country ~longtitude ~latitude
    with Not_found -> default_server_info ()

  let edge l =
    let default_edge_resource l =
      match List.Assoc.find_exn l "source", List.Assoc.find_exn l "target" with
      | Gml.String source, Gml.String target -> "((" ^ source ^ " " ^ target ^ "))"
      | _ -> "(())"
    in
    try
      match List.Assoc.find_exn l "label" with
      | Gml.String resource -> resource
      | _                   -> default_edge_resource l
    with Not_found -> default_edge_resource l

end

module NodeEdgePrinter = struct

  let node (v : G.V.label) = [
    "id"        , Gml.Int    v.id;
    "label"     , Gml.String v.label;
    "country"   , Gml.String v.country;
    "longtitude", Gml.Float  v.longtitude;
    "latitude"  , Gml.Float  v.latitude;
  ]

  let edge (e : G.E.label) = ["label", Gml.String e]

end

module GmlParser  = Gml.Parse (B) (NodeEdgeParser)
module GmlPrinter = Gml.Print (G) (NodeEdgePrinter)

exception Not_GML_file

let graph_of_gml f = 
  if Filename.check_suffix f ".gml" 
  then GmlParser.parse f
  else raise Not_GML_file
  
let gml_of_graph g f =
  let c = open_out f in
  let fmt = Format.formatter_of_out_channel c in
  Format.fprintf fmt "%a@." GmlPrinter.print g;
  close_out_noerr c