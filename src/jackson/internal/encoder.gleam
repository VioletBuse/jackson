import gleam/dynamic.{type Dynamic}
import gleam/float
import gleam/int
import gleam/list
import gleam/result
import gleam/string_builder.{type StringBuilder}
import jackson/internal/escaping
import jackson/internal/json.{type Json}

pub fn dynamic_to_json(dyn: Dynamic) -> Result(Json, dynamic.DecodeErrors) {
  dynamic.any([
    fn(dyn: Dynamic) { dynamic.int(dyn) |> result.map(json.Integer) },
    fn(dyn: Dynamic) { dynamic.float(dyn) |> result.map(json.Float) },
    fn(dyn: Dynamic) { dynamic.string(dyn) |> result.map(json.String) },
    fn(dyn: Dynamic) { dynamic.bool(dyn) |> result.map(json.Bool) },
    fn(dyn: Dynamic) {
      dynamic.optional(fn(_) { Error([]) })(dyn)
      |> result.map(fn(_) { json.Null })
    },
    fn(dyn: Dynamic) {
      dynamic.list(dynamic.tuple2(dynamic.string, dynamic_to_json))(dyn)
      |> result.map(json.Object)
    },
    fn(dyn: Dynamic) {
      dynamic.list(dynamic_to_json)(dyn) |> result.map(json.Array)
    },
  ])(dyn)
}

pub fn to_string(json: Json) -> String {
  to_string_builder(json)
  |> string_builder.to_string
}

pub fn to_string_builder(json: Json) -> StringBuilder {
  case json {
    json.Null -> string_builder.from_string("null")
    json.Float(inner) -> float.to_string(inner) |> string_builder.from_string
    json.Integer(inner) -> int.to_string(inner) |> string_builder.from_string
    json.Bool(True) -> string_builder.from_string("true")
    json.Bool(False) -> string_builder.from_string("false")
    json.String(inner) -> {
      string_builder.from_string(escaping.escape_string(inner))
      |> string_builder.prepend("\"")
      |> string_builder.append("\"")
    }
    json.Array(entries) -> {
      list.map(entries, to_string_builder)
      |> list.index_fold(string_builder.new(), fn(acc, builder, idx) {
        let term_prepend = case idx {
          0 -> ""
          _ -> ","
        }

        acc
        |> string_builder.append(term_prepend)
        |> string_builder.append_builder(builder)
      })
      |> string_builder.prepend("[")
      |> string_builder.append("]")
    }
    json.Object(entries) -> {
      list.map(entries, fn(entry) {
        to_string_builder(json.String(entry.0))
        |> string_builder.append(":")
        |> string_builder.append_builder(to_string_builder(entry.1))
      })
      |> list.index_fold(string_builder.new(), fn(acc, builder, idx) {
        let term_prepend = case idx {
          0 -> ""
          _ -> ","
        }

        acc
        |> string_builder.append(term_prepend)
        |> string_builder.append_builder(builder)
      })
      |> string_builder.prepend("{")
      |> string_builder.append("}")
    }
  }
}
