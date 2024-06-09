import gleam/float
import gleam/int
import gleam/list
import gleam/string_builder.{type StringBuilder}
import jackson/internal/json.{type Json}

pub fn to_string_builder(json: Json) -> StringBuilder {
  case json {
    json.Null -> string_builder.from_string("null")
    json.Float(inner) -> float.to_string(inner) |> string_builder.from_string
    json.Integer(inner) -> int.to_string(inner) |> string_builder.from_string
    json.Bool(True) -> string_builder.from_string("true")
    json.Bool(False) -> string_builder.from_string("false")
    json.String(inner) -> {
      string_builder.from_string(inner)
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
