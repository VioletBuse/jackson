import gleam/bool
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/regex
import gleam/result
import gleam/string
import jackson/internal/json.{type Json}

pub type Ref {
  Root(fragment: Bool, next: Option(Ref))
  Ref(value: String, next: Option(Ref))
}

pub fn resolve(json: Json, ref: String) -> Result(Json, Nil) {
  let assert Root(_fragment, next_ref) = parse_ref(ref)

  case next_ref {
    None -> Ok(json)
    Some(ref) -> resolve_loop(json, ref)
  }
}

fn resolve_loop(json: Json, ref: Ref) -> Result(Json, Nil) {
  case json {
    json.Object(entries) -> resolve_object_ref(entries, ref)
    json.Array(entries) -> resolve_array_ref(entries, ref)
    _ -> Error(Nil)
  }
}

fn resolve_array_ref(entries: List(Json), ref: Ref) -> Result(Json, Nil) {
  let assert Ref(value, next) = ref
  let assert Ok(re) = regex.from_string("^(-|([1-9][0-9]+))$")

  let is_valid_array_path = regex.check(re, value)
  use <- bool.guard(when: !is_valid_array_path, return: Error(Nil))

  let indexed_item = case value {
    "-" -> Error(Nil)
    idx -> {
      let assert Ok(idx) = int.parse(idx)
      list.index_fold(entries, Error(Nil), fn(found, val, index) {
        case found, index {
          _, _ if index == idx -> Ok(val)
          _, _ -> found
        }
      })
    }
  }

  use json <- result.try(indexed_item)

  case next {
    None -> Ok(json)
    Some(ref) -> resolve_loop(json, ref)
  }
}

fn resolve_object_ref(
  entries: List(#(String, Json)),
  ref: Ref,
) -> Result(Json, Nil) {
  let assert Ref(value, next) = ref
  let search_codepoints = string.to_utf_codepoints(value)

  let found =
    list.find(entries, fn(entry) {
      let key_codepoints = string.to_utf_codepoints(entry.0)
      use <- bool.guard(when: search_codepoints == key_codepoints, return: True)
      False
    })

  use #(_, json) <- result.try(found)

  case next {
    None -> Ok(json)
    Some(ref) -> resolve_loop(json, ref)
  }
}

fn parse_ref(ref: String) -> Ref {
  let #(first, split) =
    string.split(ref, "/")
    |> list.split(1)

  let assert [fragment_ident] = first
  let fragment_ident_enabled = fragment_ident == "#"

  let descaped =
    list.map(split, string.replace(_, "~1", "/"))
    |> list.map(string.replace(_, "~0", "~"))

  Root(fragment_ident_enabled, ref_loop(descaped))
}

fn ref_loop(path_items: List(String)) {
  case path_items {
    [] -> None
    [first, ..rest] -> Some(Ref(first, ref_loop(rest)))
  }
}
