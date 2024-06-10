import gleam/bool
import gleam/float
import gleam/int
import gleam/io
import gleam/regex
import gleam/result
import gleam/string
import jackson/internal/escaping
import jackson/internal/json.{
  type Json, Array, Bool, Float, Integer, Null, Object, String,
}

pub fn parse(input: String) -> Result(Json, String) {
  let input = string.trim(input)

  case parse_loop(input) {
    Error(err) -> Error(err)
    Ok(#(val, "")) -> Ok(val)
    Ok(#(_, rest)) -> Error(unexpected_character(rest))
  }
}

fn unexpected_character(string: String) {
  let first_char = string.slice(string, 0, 1)
  "Unexpected character: \"" <> first_char <> "\""
}

fn parse_loop(input: String) -> Result(#(Json, String), String) {
  io.debug("parse_loop_call")
  io.debug(input)

  let input = string.trim_left(input)

  use _ <- result.try_recover(parse_array(input))
  use _ <- result.try_recover(parse_object(input))
  use _ <- result.try_recover(parse_bool(input))
  use _ <- result.try_recover(parse_null(input))
  use _ <- result.try_recover(parse_number(input))
  use err <- result.try_recover(parse_string(input))

  Error(err)
}

fn parse_object(input: String) -> Result(#(Json, String), String) {
  let input = string.trim_left(input)

  case input {
    "{" <> rest -> {
      use #(entries, rest) <- result.try(parse_object_entry(rest))
      Ok(#(Object(entries), rest))
    }
    _ -> Error(unexpected_character(input))
  }
}

fn parse_object_entry(
  input: String,
) -> Result(#(List(#(String, Json)), String), String) {
  let input = string.trim_left(input)
  use #(key, rest) <- result.try(parse_loop(input))
  let rest = string.trim_left(rest)

  case key {
    String(key) -> {
      use <- bool.guard(
        !string.starts_with(rest, ":"),
        Error(unexpected_character(rest)),
      )

      use #(value, rest) <- result.try(
        parse_loop(string.slice(rest, 1, string.length(rest))),
      )
      let rest = string.trim_left(rest)

      case rest {
        "," <> rest -> {
          use #(remaining, rest) <- result.try(parse_object_entry(rest))
          Ok(#([#(key, value)], rest))
        }
        "}" <> rest -> Ok(#([#(key, value)], rest))
        _ -> Error(unexpected_character(rest))
      }
    }
    _ -> Error("Only strings are valid keys in json")
  }
}

fn parse_array(input: String) -> Result(#(Json, String), String) {
  let input = string.trim_left(input)

  case input {
    "[" <> rest -> parse_array_value(rest)
    _ -> Error(unexpected_character(input))
  }
}

fn parse_array_value(input: String) -> Result(#(Json, String), String) {
  use #(element, rest) <- result.try(parse_loop(input))
  let rest = string.trim_left(rest)

  io.debug(#("decoded_array_value", element))

  case rest {
    "," <> rest ->
      case parse_array_value(rest) {
        Ok(#(Array(inner), rest)) -> Ok(#(Array([element, ..inner]), rest))
        _ -> Error(unexpected_character(rest))
      }
    "]" <> rest -> Ok(#(Array([element]), rest))
    _ -> Error(unexpected_character(rest))
  }
}

fn parse_bool(input: String) -> Result(#(Json, String), String) {
  case input {
    "true" <> rest -> Ok(#(Bool(True), rest))
    "false" <> rest -> Ok(#(Bool(False), rest))
    _ -> Error("Expected one of: \"true\", \"false\"")
  }
}

fn parse_null(input: String) -> Result(#(Json, String), String) {
  case input {
    "null" <> rest -> Ok(#(Null, rest))
    _ -> Error("Expected: \"null\"")
  }
}

fn parse_number(input: String) -> Result(#(Json, String), String) {
  let assert Ok(re) =
    regex.from_string("^-?[0-9]+(\\.[0-9]+)?((e|E)(\\+|-)?[0-9]+)?")
  let res = regex.scan(re, input)

  io.debug(res)

  case res, input {
    _, "" -> Error("Unexpected end of input")
    [], _ -> {
      Error(unexpected_character(input))
    }
    [regex.Match(content, ..), ..], _ -> {
      let rest =
        string.slice(input, string.length(content), string.length(input))

      // io.debug(#("rest", rest))

      case string.split(string.lowercase(content), "e") {
        [] -> panic as "string cannot be empty"
        [first] ->
          case int.parse(first), float.parse(first) {
            Ok(intval), _ -> Ok(#(Integer(intval), rest))
            _, Ok(floatval) -> Ok(#(Float(floatval), rest))
            _, _ -> Error(unexpected_character(content))
          }
        [first, second] ->
          case parse_exponent(first, second) {
            Ok(val) -> Ok(#(val, rest))
            Error(_) -> Error("Invalid number " <> content)
          }
        _ -> Error("Invalid number " <> content)
      }
    }
  }
}

fn parse_exponent(first: String, second: String) -> Result(Json, Nil) {
  // io.debug("parse exponent")
  let first = case int.parse(first), float.parse(first) {
    _, Ok(floatval) -> Ok(floatval)
    Ok(intval), _ -> Ok(int.to_float(intval))
    _, _ -> Error(Nil)
  }

  use first <- result.try(first)

  let second = case int.parse(second), float.parse(second) {
    _, Ok(floatval) -> Ok(floatval)
    Ok(intval), _ -> Ok(int.to_float(intval))
    _, _ -> Error(Nil)
  }

  use second <- result.try(second)

  let multiplicand = float.power(10.0, second)

  use mult <- result.try(multiplicand)

  Ok(Float(first *. mult))
}

fn parse_string(input: String) -> Result(#(Json, String), String) {
  let assert Ok(re) =
    regex.from_string(
      "^\"([^\\\\\"\\\\u0000-\\\\u001F\\\\u007F-\\\\u009F\\\\u061C\\\\u200E\\\\u200F\\\\u202A-\\\\u202E\\\\u2066-\\\\u2069]|(\\\\(\"|\\\\|\\/|b|f|n|r|t|(u[0-9a-fA-F]{4}))))*?\"",
    )
  let res = regex.scan(re, input)

  case res {
    [] -> Error(unexpected_character(input))
    [regex.Match(..) as match, ..] -> {
      let inner =
        string.slice(match.content, 1, string.length(match.content) - 2)
      let rest =
        string.slice(input, string.length(match.content), string.length(input))

      Ok(#(String(escaping.descape_string(inner)), rest))
    }
  }
}
