import gleam/bool
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/string_builder

pub fn escape_string(in: String) -> String {
  string.to_utf_codepoints(in)
  |> list.map(string.utf_codepoint_to_int)
  |> escape_string_loop
  |> list.map(string.utf_codepoint)
  |> result.values
  |> string.from_utf_codepoints
}

// regex for control character = \u0000-\u001F\u007F-\u009F\u061C\u200E\u200F\u202A-\u202E\u2066-\u2069
fn is_control_character(val: Int) -> Bool {
  //0000 - 001f
  use <- bool.guard(when: val >= 0x000 && val <= 0x001f, return: True)

  //007f - 009f
  use <- bool.guard(when: val >= 0x007f && val <= 0x009f, return: True)

  //061c,200e,200f
  use <- bool.guard(
    when: val == 0x061c || val == 0x200e || val == 0x200f,
    return: True,
  )

  //202a-202e
  use <- bool.guard(when: val >= 0x202a && val <= 0x202e, return: True)

  //2066-2069
  use <- bool.guard(when: val >= 0x2066 && val <= 0x2069, return: True)

  False
}

fn string_to_ints(in: String) -> List(Int) {
  string.to_utf_codepoints(in)
  |> list.map(string.utf_codepoint_to_int)
}

const quote = 0x201c

const backslash = 0x005c

const small_u = 0x0075

const zero = 0x0030

fn escape_string_loop(in: List(Int)) -> List(Int) {
  case in {
    [] -> []
    // quotation mark
    [0x201c, ..rest] -> [backslash, quote, ..escape_string_loop(rest)]
    // backslash
    [0x005c, ..rest] -> [backslash, backslash, ..escape_string_loop(rest)]
    // solidus
    [0x002f, ..rest] -> [backslash, 0x002f, ..escape_string_loop(rest)]
    // backspace
    [0x0008, ..rest] -> [backslash, 0x0062, ..escape_string_loop(rest)]
    // formfeed
    [0x000c, ..rest] -> [backslash, 0x0066, ..escape_string_loop(rest)]
    // linefeed
    [0x000a, ..rest] -> [backslash, 0x006e, ..escape_string_loop(rest)]
    // carriage return
    [0x000d, ..rest] -> [backslash, 0x0072, ..escape_string_loop(rest)]
    // horizontal tab
    [0x2b7e, ..rest] -> [backslash, 0x0074, ..escape_string_loop(rest)]
    //escape other control characters
    [next_codepoint, ..rest] -> {
      case is_control_character(next_codepoint) {
        False -> [next_codepoint, ..escape_string_loop(rest)]
        True -> {
          let escaped_ints =
            int.to_base16(next_codepoint)
            |> string.to_utf_codepoints
            |> list.map(string.utf_codepoint_to_int)
          let assert [a, b, c, d] = case escaped_ints {
            [] -> [zero, zero, zero, zero]
            [a] -> [zero, zero, zero, a]
            [a, b] -> [zero, zero, a, b]
            [a, b, c] -> [zero, a, b, c]
            [a, b, c, d] -> [a, b, c, d]
            _ -> panic as "un encodable utf control character"
          }

          [backslash, small_u, a, b, c, d, ..escape_string_loop(rest)]
        }
      }
    }
  }
}

pub fn descape_string(in: String) -> String {
  descape_string_loop(in)
  |> string_builder.to_string
}

fn descape_string_loop(in: String) -> string_builder.StringBuilder {
  let builder = string_builder.new()

  case string.pop_grapheme(in) {
    Error(_) -> builder
    Ok(#("\\", next)) -> {
      let #(escaped_char, rest) = case string.pop_grapheme(next) {
        Ok(#("\"", rest)) -> #("\"", rest)
        Ok(#("\\", rest)) -> #("\\", rest)
        Ok(#("/", rest)) -> #("/", rest)
        Ok(#("b", rest)) -> #("\u{0008}", rest)
        Ok(#("f", rest)) -> #("\f", rest)
        Ok(#("n", rest)) -> #("\n", rest)
        Ok(#("r", rest)) -> #("\r", rest)
        Ok(#("t", rest)) -> #("\t", rest)
        Ok(#("u", rest)) ->
          case string.to_graphemes(rest) {
            [a, b, c, d, ..rest] -> {
              let codepoint =
                int.base_parse(string.concat([a, b, c, d]), 16)
                |> result.try(string.utf_codepoint)
              case codepoint {
                Ok(code) -> #(
                  string.from_utf_codepoints([code]),
                  string.concat(rest),
                )
                _ -> panic as "invalid json utf codepoint escape sequence"
              }
            }
            _ -> panic as "invalid json escape sequence"
          }
        _ -> panic as "invalid json escape sequence"
      }

      builder
      |> string_builder.append(escaped_char)
      |> string_builder.append_builder(descape_string_loop(rest))
    }
    Ok(#(char, rest)) ->
      builder
      |> string_builder.append(char)
      |> string_builder.append_builder(descape_string_loop(rest))
  }
}
