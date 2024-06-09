import gleam/dynamic.{type Dynamic}
import gleam/list
import jackson/internal/json.{
  type Json, Array, Bool, Float, Integer, Null, Object, String,
}

pub fn decode(
  json: Json,
  decoder: fn(Dynamic) -> Result(a, dynamic.DecodeErrors),
) -> Result(a, dynamic.DecodeErrors) {
  let to_decode = json_to_dynamic(json)
  decoder(to_decode)
}

fn json_to_dynamic(json: Json) -> Dynamic {
  case json {
    Float(inner) -> dynamic.from(inner)
    Integer(inner) -> dynamic.from(inner)
    Bool(inner) -> dynamic.from(inner)
    Null -> dynamic.from(Nil)
    String(inner) -> dynamic.from(inner)
    Array(inner) -> dynamic.from(list.map(inner, json_to_dynamic))
    Object(entries) ->
      dynamic.from(
        list.map(entries, fn(entry) {
          dynamic.from(#(entry.0, json_to_dynamic(entry.1)))
        }),
      )
  }
}
